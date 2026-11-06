import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Rust Core version pins stay synchronized', () {
    final shellLock = File('tool/core-version.sh').readAsStringSync();
    final nativeHook = File('hook/build.dart').readAsStringSync();
    final compatibility = File('CORE_COMPATIBILITY.md').readAsStringSync();

    const tag = 'v0.3.5';
    const commit = '68a5d2a24aa3f48b55f649c0094b30956af2acc0';
    const sourceSha256 =
        '53fd5a702c030c71b663bf3bd59dee16a397589e02dd06169fb3b6606306b84d';

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
