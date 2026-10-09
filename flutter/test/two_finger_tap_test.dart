import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hbb/mobile/two_finger_tap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick two-finger tap is recognised once', () {
    final d = TwoFingerTapDetector();
    d.down(1, const Offset(10, 10), 0);
    d.down(2, const Offset(60, 10), 20);
    expect(d.up(1, 120), isFalse);
    expect(d.up(2, 130), isTrue);
  });

  test('one finger, slow, moved or three fingers are not taps', () {
    var d = TwoFingerTapDetector();
    d.down(1, Offset.zero, 0);
    expect(d.up(1, 50), isFalse);

    d = TwoFingerTapDetector();
    d.down(1, Offset.zero, 0);
    d.down(2, const Offset(50, 0), 10);
    d.up(1, 400);
    expect(d.up(2, 410), isFalse);

    d = TwoFingerTapDetector();
    d.down(1, Offset.zero, 0);
    d.down(2, const Offset(50, 0), 10);
    d.move(2, const Offset(120, 0));
    d.up(1, 50);
    expect(d.up(2, 60), isFalse);

    d = TwoFingerTapDetector();
    d.down(1, Offset.zero, 0);
    d.down(2, const Offset(50, 0), 5);
    d.down(3, const Offset(100, 0), 8);
    d.up(1, 40);
    d.up(2, 45);
    expect(d.up(3, 50), isFalse);
  });

  testWidgets('region fires on a real two-finger tap and not on one finger',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: TwoFingerTapRegion(
          onTap: () => taps++, child: const SizedBox.expand()),
    ));
    final a = await tester.startGesture(const Offset(100, 100), pointer: 1);
    await a.up();
    expect(taps, 0);

    final g1 = await tester.startGesture(const Offset(100, 100), pointer: 2);
    final g2 = await tester.startGesture(const Offset(200, 100), pointer: 3);
    await tester.pump(const Duration(milliseconds: 60));
    await g1.up();
    await g2.up();
    expect(taps, 1);
  });
}
