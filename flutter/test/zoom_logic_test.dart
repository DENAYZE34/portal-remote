import 'package:flutter_hbb/mobile/zoom_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tap cycles fit -> 2x -> 3x -> fit', () {
    expect(nextZoomLevel(1.0), 2.0);
    expect(nextZoomLevel(2.0), 3.0);
    expect(nextZoomLevel(3.0), 1.0);
    expect(nextZoomLevel(1.05), 2.0);
    expect(nextZoomLevel(2.5), 3.0);
    expect(nextZoomLevel(3.4), 1.0);
  });

  test('dragging up zooms in, down zooms out, no drag changes nothing', () {
    expect(dragZoomFactor(-50), greaterThan(1));
    expect(dragZoomFactor(50), lessThan(1));
    expect(dragZoomFactor(0), 1.0);
    // up then down by the same amount returns to the same size
    expect(dragZoomFactor(-80) * dragZoomFactor(80), closeTo(1.0, 1e-9));
  });

  test('badge text', () {
    expect(zoomLabel(1.0), '1×');
    expect(zoomLabel(1.04), '1×');
    expect(zoomLabel(2.0), '2×');
    expect(zoomLabel(2.5), '2.5×');
    expect(zoomLabel(2.74), '2.5×');
  });

  test('zoom mode is saved and restored; unknown means both', () {
    for (final m in ZoomMode.values) {
      expect(parseZoomMode(zoomModeKey(m)), m);
    }
    expect(parseZoomMode(null), ZoomMode.both);
    expect(parseZoomMode('weird'), ZoomMode.both);
  });

  test('which controls each mode shows', () {
    expect(zoomModeHasButton(ZoomMode.button), isTrue);
    expect(zoomModeHasEdge(ZoomMode.button), isFalse);
    expect(zoomModeHasButton(ZoomMode.edgeRight), isFalse);
    expect(zoomModeHasEdge(ZoomMode.edgeLeft), isTrue);
    expect(zoomEdgeOnLeft(ZoomMode.edgeLeft), isTrue);
    expect(zoomEdgeOnLeft(ZoomMode.edgeRight), isFalse);
    expect(zoomModeHasButton(ZoomMode.both), isTrue);
    expect(zoomModeHasEdge(ZoomMode.both), isTrue);
  });
}
