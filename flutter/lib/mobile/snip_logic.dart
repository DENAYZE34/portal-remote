import 'dart:math' as math;
import 'dart:ui';

/// Points of a straight drag from [a] to [b] in [steps] equal steps (both ends included).
List<Offset> dragPath(Offset a, Offset b, int steps) {
  final n = math.max(1, steps);
  return [
    for (var i = 0; i <= n; i++)
      Offset(a.dx + (b.dx - a.dx) * i / n, a.dy + (b.dy - a.dy) * i / n)
  ];
}
