import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
import 'package:path/path.dart' as path;

const _coreTag = 'v0.1.0';
const _coreCommit = 'da335740afba6f4d3ed9848efddc622072e04ab6';
const _sourceArchiveSha256 =
    '4efa2335e46f2e5cba59596244961b8fc8f7a922f599cacaa75b4c3847b51334';
const _sourceArchiveUrl =
    'https://github.com/CryptoKango/hyper-axis/archive/refs/tags/'
    '$_coreTag.tar.gz';
const _cacheMarker = '$_coreCommit:$_sourceArchiveSha256:compat-v1';
const _maximumArchiveBytes = 16 * 1024 * 1024;

void main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final targetOS = input.config.code.targetOS;
    if (targetOS != OS.android && targetOS != OS.iOS) {
      if (!input.config.linkingEnabled) {
        // Pure Dart tests request code assets for the host, but do not link or
        // load them. Keep tests portable without weakening application builds.
        return;
      }
      throw UnsupportedError('hyper_axis 仅支持 Android 与 iOS，当前目标为 $targetOS。');
    }

    final coreDirectory = await _CoreSourceCache(
      sharedOutputDirectory: input.outputDirectoryShared,
    ).prepare();
    final crateDirectory = Directory(
      path.join(coreDirectory.path, 'crates', 'hyper-axis-ffi'),
    );
    final packageRoot = Directory.fromUri(input.packageRoot).path;

    await FlutterRustBridgeNativeAssetsBuilder(
      assetName: 'src/generated/frb_generated.io.dart',
      cratePath: path.relative(crateDirectory.path, from: packageRoot),
      extraCargoBuildArgs: ['--locked'],
    ).run(input: input, output: output);
  });
}

final class _CoreSourceCache {
  const _CoreSourceCache({required this.sharedOutputDirectory});

  final Uri sharedOutputDirectory;

  Future<Directory> prepare() async {
    final cacheRoot = Directory.fromUri(sharedOutputDirectory);
    final coreDirectory = Directory(
      path.join(cacheRoot.path, 'hyper-axis-core-$_coreCommit'),
    );
    final marker = File(path.join(coreDirectory.path, '.hyper-axis-commit'));
    final lockFile = File('${coreDirectory.path}.lock');

    await cacheRoot.create(recursive: true);
    await lockFile.create(recursive: true);
    final lock = await lockFile.open(mode: FileMode.write);
    try {
      await lock.lock(FileLock.exclusive);
      if (await _isComplete(marker)) {
        return coreDirectory;
      }

      if (await coreDirectory.exists()) {
        await coreDirectory.delete(recursive: true);
      }
      await coreDirectory.create(recursive: true);

      final archiveBytes = await _downloadSourceArchive();
      _verifyArchive(archiveBytes);
      await _extractArchive(archiveBytes, coreDirectory);
      await _applyLockedCompatibilityFix(coreDirectory);
      await _writeNativeAssetsToolchain(coreDirectory);
      await marker.writeAsString('$_cacheMarker\n', flush: true);
      return coreDirectory;
    } finally {
      await lock.unlock();
      await lock.close();
    }
  }

  Future<bool> _isComplete(File marker) async {
    if (!await marker.exists()) {
      return false;
    }
    return (await marker.readAsString()).trim() == _cacheMarker;
  }

  Future<Uint8List> _downloadSourceArchive() async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20);
      try {
        final request = await client.getUrl(Uri.parse(_sourceArchiveUrl));
        request.followRedirects = true;
        request.maxRedirects = 5;
        final response = await request.close().timeout(
          const Duration(minutes: 2),
        );
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            '下载 HyperAxis Rust Core 失败：HTTP ${response.statusCode}',
            uri: Uri.parse(_sourceArchiveUrl),
          );
        }
        if (response.contentLength > _maximumArchiveBytes) {
          throw StateError('HyperAxis Rust Core 源码归档超过大小限制。');
        }

        final bytes = BytesBuilder(copy: false);
        var receivedBytes = 0;
        await for (final chunk in response.timeout(
          const Duration(minutes: 2),
        )) {
          receivedBytes += chunk.length;
          if (receivedBytes > _maximumArchiveBytes) {
            throw StateError('HyperAxis Rust Core 源码归档超过大小限制。');
          }
          bytes.add(chunk);
        }
        return bytes.takeBytes();
      } on Object catch (error) {
        lastError = error;
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      } finally {
        client.close(force: true);
      }
    }
    throw StateError('下载 HyperAxis Rust Core 失败，已重试 3 次：$lastError');
  }

  void _verifyArchive(Uint8List bytes) {
    final actual = sha256.convert(bytes).toString();
    if (actual != _sourceArchiveSha256) {
      throw StateError('HyperAxis Rust Core 源码归档 SHA256 不匹配：$actual。');
    }
  }

  Future<void> _extractArchive(Uint8List bytes, Directory destination) async {
    final tarBytes = GZipDecoder().decodeBytes(bytes);
    final archive = TarDecoder().decodeBytes(tarBytes);
    const archiveRoot = 'hyper-axis-0.1.0/';

    for (final entry in archive) {
      if (!entry.name.startsWith(archiveRoot)) {
        throw StateError('源码归档包含未知根目录：${entry.name}');
      }
      final relativeName = entry.name.substring(archiveRoot.length);
      if (relativeName.isEmpty) {
        continue;
      }

      final normalizedName = path.posix.normalize(relativeName);
      if (path.posix.isAbsolute(normalizedName) ||
          normalizedName == '..' ||
          normalizedName.startsWith('../')) {
        throw StateError('源码归档包含非法路径：${entry.name}');
      }

      final outputPath = path.joinAll([
        destination.path,
        ...path.posix.split(normalizedName),
      ]);
      if (entry.isFile) {
        final content = entry.readBytes();
        if (content == null) {
          throw StateError('无法读取源码归档文件：${entry.name}');
        }
        final output = File(outputPath);
        await output.parent.create(recursive: true);
        await output.writeAsBytes(content, flush: true);
      } else if (entry.isDirectory) {
        await Directory(outputPath).create(recursive: true);
      }
    }

    final manifest = File(path.join(destination.path, 'Cargo.toml'));
    if (!await manifest.exists()) {
      throw StateError('HyperAxis Rust Core 源码归档缺少 Cargo.toml。');
    }
  }

  Future<void> _applyLockedCompatibilityFix(Directory coreDirectory) async {
    final lockFile = File(path.join(coreDirectory.path, 'Cargo.lock'));
    final original = await lockFile.readAsString();
    const incompatible = '''name = "libc"
version = "0.2.190"
source = "registry+https://github.com/rust-lang/crates.io-index"
checksum = "ce5d3ddc6d3fa000eb1536d85e147bfe31aacaba692ed6a876f95cb7c855be78"''';
    const compatible = '''name = "libc"
version = "0.2.189"
source = "registry+https://github.com/rust-lang/crates.io-index"
checksum = "3eaf3ede3fee6db1a4c2ee091bf8a8b4dccdc6d17f656fb07896ee72867612f2"''';
    if (!original.contains(incompatible)) {
      throw StateError('Rust Core Cargo.lock 不符合 $_coreCommit 的预期内容。');
    }
    await lockFile.writeAsString(
      original.replaceFirst(incompatible, compatible),
      flush: true,
    );
  }

  Future<void> _writeNativeAssetsToolchain(Directory coreDirectory) async {
    final toolchain = File(
      path.join(
        coreDirectory.path,
        'crates',
        'hyper-axis-ffi',
        'rust-toolchain.toml',
      ),
    );
    await toolchain.writeAsString('''[toolchain]
channel = "1.99.1"
profile = "minimal"
targets = [
  "aarch64-apple-ios",
  "aarch64-apple-ios-sim",
  "x86_64-apple-ios",
  "aarch64-linux-android",
  "armv7-linux-androideabi",
  "x86_64-linux-android",
]
''', flush: true);
  }
}
