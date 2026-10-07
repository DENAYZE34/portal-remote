import 'package:flutter_hbb/mobile/update_check.dart';
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
}
