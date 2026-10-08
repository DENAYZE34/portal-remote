import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../zoom_logic.dart';

const String kZoomModeOption = 'portal-zoom-mode';

ZoomMode currentZoomMode() =>
    parseZoomMode(bind.mainGetLocalOption(key: kZoomModeOption));

/// Zoom of the remote picture around the remote cursor, as multiples of the
/// fit-to-screen size. Shared by the bar button and the edge strip.
class ZoomController {
  final FFI ffi;
  ZoomController(this.ffi);

  double get _fit => ffi.imageModel.minScale * 1.5;

  /// 1.0 = whole remote screen visible.
  double get level {
    final fit = _fit;
    if (fit <= 0) return 1.0;
    return ffi.canvasModel.scale / fit;
  }

  Offset get _focal {
    final c = ffi.canvasModel;
    final cx = ffi.cursorModel.x;
    final cy = ffi.cursorModel.y;
    if (cx < 0 || cy < 0) {
      final s = c.size;
      return Offset(s.width / 2, s.height / 2);
    }
    return Offset(c.x + cx * c.scale, c.y + cy * c.scale);
  }

  void zoomBy(double factor) {
    if (ffi.imageModel.image == null) return;
    ffi.canvasModel.updateScale(factor, _focal);
  }

  void zoomTo(double target) {
    final cur = level;
    if (cur <= 0) return;
    zoomBy(target / cur);
  }

  void cycle() => zoomTo(nextZoomLevel(level));

  void reset() => zoomTo(1.0);
}

/// Bar button: tap cycles fit -> 2x -> 3x, long-press resets.
class ZoomButton extends StatelessWidget {
  final FFI ffi;
  const ZoomButton({Key? key, required this.ffi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final zc = ZoomController(ffi);
    return AnimatedBuilder(
      animation: ffi.canvasModel,
      builder: (_, __) {
        final zoomed = zc.level > 1.08;
        return GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            zc.reset();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                color: zoomed ? Colors.amberAccent : Colors.white,
                icon: Icon(zoomed ? Icons.zoom_out : Icons.zoom_in),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  zc.cycle();
                },
              ),
              if (zoomed)
                Positioned(
                  bottom: 2,
                  child: IgnorePointer(
                    child: Text(zoomLabel(zc.level),
                        style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Invisible strip along a screen edge: slide up to zoom in, down to zoom out.
/// A small badge appears only while zoomed; tap it to go back to fit.
class ZoomEdgeStrip extends StatefulWidget {
  final FFI ffi;
  final bool onLeft;
  const ZoomEdgeStrip({Key? key, required this.ffi, required this.onLeft})
      : super(key: key);

  @override
  State<ZoomEdgeStrip> createState() => _ZoomEdgeStripState();
}

class _ZoomEdgeStripState extends State<ZoomEdgeStrip> {
  late final ZoomController _zc = ZoomController(widget.ffi);
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: widget.ffi.canvasModel,
      builder: (_, __) {
        final zoomed = _zc.level > 1.08;
        final handleOpacity = _dragging ? 0.55 : 0.18;
        return Stack(children: [
          Positioned(
            top: h * 0.25,
            bottom: h * 0.12,
            left: widget.onLeft ? 0 : null,
            right: widget.onLeft ? null : 0,
            width: 26,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (_) => setState(() => _dragging = true),
              onVerticalDragUpdate: (d) => _zc.zoomBy(dragZoomFactor(d.delta.dy)),
              onVerticalDragEnd: (_) => setState(() => _dragging = false),
              onVerticalDragCancel: () => setState(() => _dragging = false),
              child: Align(
                alignment:
                    widget.onLeft ? Alignment.centerLeft : Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: handleOpacity,
                  child: Container(
                    width: 4,
                    height: 64,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (zoomed)
            Positioned(
              top: h * 0.25 - 30,
              left: widget.onLeft ? 8 : null,
              right: widget.onLeft ? null : 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _zc.reset();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(zoomLabel(_zc.level),
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
