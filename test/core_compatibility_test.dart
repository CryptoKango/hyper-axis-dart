import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Rust Core version pins stay synchronized', () {
    final shellLock = File('tool/core-version.sh').readAsStringSync();
    final nativeHook = File('hook/build.dart').readAsStringSync();
    final compatibility = File('CORE_COMPATIBILITY.md').readAsStringSync();

    const tag = 'v0.3.4';
    const commit = '30938dc352433320e2e302f3d67e9491adeea958';
    const sourceSha256 =
        '423bb4907f4d8bacf01a5fb3f9c754a8dce565541fdab45b05ea89753ce42330';

    expect(shellLock, contains(tag));
    expect(shellLock, contains(commit));
    expect(nativeHook, contains(tag));
    expect(nativeHook, contains(commit));
    expect(nativeHook, contains(sourceSha256));
    expect(compatibility, contains(tag));
    expect(compatibility, contains(commit));
    expect(compatibility, contains(sourceSha256));
  });
}
