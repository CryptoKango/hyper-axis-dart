import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Rust Core version pins stay synchronized', () {
    final shellLock = File('tool/core-version.sh').readAsStringSync();
    final nativeHook = File('hook/build.dart').readAsStringSync();
    final compatibility = File('CORE_COMPATIBILITY.md').readAsStringSync();

    const tag = 'v0.1.0';
    const commit = 'da335740afba6f4d3ed9848efddc622072e04ab6';
    const sourceSha256 =
        '4efa2335e46f2e5cba59596244961b8fc8f7a922f599cacaa75b4c3847b51334';

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
