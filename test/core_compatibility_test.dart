import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Rust Core version pins stay synchronized', () {
    final shellLock = File('tool/core-version.sh').readAsStringSync();
    final nativeHook = File('hook/build.dart').readAsStringSync();
    final compatibility = File('CORE_COMPATIBILITY.md').readAsStringSync();

    const tag = 'v0.3.3';
    const commit = '456fd699e181752c08e2800a99db379b72d8dd96';
    const sourceSha256 =
        '1f1245e04e847d3fd89be8c8fca75e158582518d2911a8dcc3515b726ce53ca1';

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
