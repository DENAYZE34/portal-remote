import 'dart:math' as math;

/// Zoom levels of the one-tap button, as multiples of the fit-to-screen size.
const List<double> kZoomLevels = [1.0, 2.0, 3.0];

/// Next level of the tap-to-cycle button; wraps back to fit.
double nextZoomLevel(double current) {
  for (final l in kZoomLevels) {
    if (l > current + 0.15) return l;
  }
  return kZoomLevels.first;
}

/// Zoom factor for a vertical drag of [dy] pixels (up is negative = zoom in).
double dragZoomFactor(double dy) => math.exp(-dy / 220);

/// "1×", "2×", "2.5×" for the badge.
String zoomLabel(double level) {
  if (level < 1.08) return '1×';
  final rounded = (level * 2).round() / 2;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(1);
  return '$text×';
}

/// Where the zoom controls live; chosen in Settings for the A/B test.
enum ZoomMode { edgeRight, edgeLeft, button, both }

ZoomMode parseZoomMode(String? saved) {
  switch (saved) {
    case 'edge-right':
      return ZoomMode.edgeRight;
    case 'edge-left':
      return ZoomMode.edgeLeft;
    case 'button':
      return ZoomMode.button;
    default:
      return ZoomMode.both;
  }
}

String zoomModeKey(ZoomMode m) {
  switch (m) {
    case ZoomMode.edgeRight:
      return 'edge-right';
    case ZoomMode.edgeLeft:
      return 'edge-left';
    case ZoomMode.button:
      return 'button';
    case ZoomMode.both:
      return 'both';
  }
}

bool zoomModeHasButton(ZoomMode m) => m == ZoomMode.button || m == ZoomMode.both;

bool zoomModeHasEdge(ZoomMode m) => m != ZoomMode.button;

/// The strip sits on the left only in the left-edge mode.
bool zoomEdgeOnLeft(ZoomMode m) => m == ZoomMode.edgeLeft;
