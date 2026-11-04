import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Rust Core version pins stay synchronized', () {
    final shellLock = File('tool/core-version.sh').readAsStringSync();
    final nativeHook = File('hook/build.dart').readAsStringSync();
    final compatibility = File('CORE_COMPATIBILITY.md').readAsStringSync();

    const tag = 'v0.3.1';
    const commit = '4bd99e0f5c896f27f3a1f9bfa06e4693aa4f0ed2';
    const sourceSha256 =
        '0bdd2ef8ef697ccf4a8f3d49f65b9515c2387f3087bdbd1725c0dbf087616287';

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
