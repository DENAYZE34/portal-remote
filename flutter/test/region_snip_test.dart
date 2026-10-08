import 'dart:ui';

import 'package:flutter_hbb/mobile/widgets/region_snip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drag path covers both ends in equal steps', () {
    final p = dragPath(const Offset(0, 0), const Offset(100, 50), 10);
    expect(p.length, 11);
    expect(p.first, const Offset(0, 0));
    expect(p.last, const Offset(100, 50));
    expect(p[5], const Offset(50, 25));
  });

  test('drag path works backwards and with one step', () {
    final p = dragPath(const Offset(10, 10), const Offset(0, 0), 1);
    expect(p, [const Offset(10, 10), const Offset(0, 0)]);
  });
}
