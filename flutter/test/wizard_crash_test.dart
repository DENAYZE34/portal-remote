import 'package:flutter_hbb/mobile/crash_log_logic.dart';
import 'package:flutter_hbb/mobile/wizard_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first-run guide has three complete steps', () {
    expect(kWizardSteps.length, 3);
    for (final s in kWizardSteps) {
      expect(s.title, isNotEmpty);
      expect(s.body, isNotEmpty);
    }
  });

  test('guide is shown until it was finished once', () {
    expect(wizardNeeded(null), isTrue);
    expect(wizardNeeded(''), isTrue);
    expect(wizardNeeded('N'), isTrue);
    expect(wizardNeeded('Y'), isFalse);
  });

  test('crash entries are appended in order', () {
    final a = formatCrashEntry(DateTime(2026, 1, 1), 'first', 'at a\nat b');
    final b = formatCrashEntry(DateTime(2026, 1, 2), 'second', null);
    final log = appendCrashEntry(appendCrashEntry('', a), b);
    expect(log.indexOf('first') < log.indexOf('second'), isTrue);
    expect(a, contains('at a'));
    expect(b.contains('\n'), isFalse);
  });

  test('crash log never grows past the limit and keeps the newest', () {
    var log = '';
    for (var i = 0; i < 500; i++) {
      log = appendCrashEntry(log, 'entry number $i with some text', maxChars: 2000);
    }
    expect(log.length, lessThanOrEqualTo(2000));
    expect(log, contains('entry number 499'));
    expect(log.startsWith('entry') || log.startsWith('['), isTrue);
  });

  test('stack in an entry is trimmed to 12 lines', () {
    final stack = List.generate(40, (i) => 'frame $i').join('\n');
    final e = formatCrashEntry(DateTime(2026), 't', stack);
    expect(e, contains('frame 11'));
    expect(e, isNot(contains('frame 12')));
  });
}
