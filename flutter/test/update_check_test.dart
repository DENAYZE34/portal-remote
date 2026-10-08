import 'package:flutter_hbb/mobile/update_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release notes build number is parsed', () {
    expect(parseReleaseBuild('build 42'), 42);
    expect(parseReleaseBuild('Build 7\nnotes'), 7);
    expect(parseReleaseBuild('no number'), isNull);
    expect(parseReleaseBuild(null), isNull);
  });

  test('update is offered only for a strictly newer build', () {
    expect(isNewerBuild(43, 42), isTrue);
    expect(isNewerBuild(42, 42), isFalse);
    expect(isNewerBuild(41, 42), isFalse);
    expect(isNewerBuild(null, 42), isFalse);
    expect(isNewerBuild(43, null), isFalse);
  });

  test('release notes carry the APK hash', () {
    final h = 'a' * 64;
    expect(parseReleaseSha('build 5\nsha256 $h'), h);
    expect(parseReleaseSha('SHA256 ${h.toUpperCase()}'), h);
    expect(parseReleaseSha('sha256 abc'), isNull);
    expect(parseReleaseSha(null), isNull);
  });

  test('release suffix follows the device CPU', () {
    expect(abiSuffix('3.5.4 (stable) on "android_arm64"'), '');
    expect(abiSuffix('3.5.4 (stable) on "android_arm"'), '-armv7');
    expect(abiSuffix('3.5.4 (stable) on "android_x64"'), '-x86_64');
    expect(abiSuffix('3.5.4 (stable) on "windows_x64"'), '');
  });

  test('a download is accepted only when its hash matches exactly', () {
    final bytes = [1, 2, 3, 4];
    const good =
        '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';
    expect(digestMatches(bytes, good), isTrue);
    expect(digestMatches(bytes, good.toUpperCase()), isTrue);
    expect(digestMatches([1, 2, 3, 5], good), isFalse);
    expect(digestMatches(bytes, null), isFalse);
    expect(digestMatches(bytes, 'abc'), isFalse);
  });
}
