import 'package:flutter_hbb/mobile/host_resume_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('service is resumed only if it was on and is not running now', () {
    expect(shouldResumeHost('Y', false), isTrue);
    expect(shouldResumeHost('Y', true), isFalse);
    expect(shouldResumeHost('N', false), isFalse);
    expect(shouldResumeHost('', false), isFalse);
    expect(shouldResumeHost(null, false), isFalse);
  });
}
