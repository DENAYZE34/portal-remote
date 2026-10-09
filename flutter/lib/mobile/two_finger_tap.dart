import 'package:flutter/widgets.dart';

const int kTwoFingerTapMaxMs = 300;
const double kTwoFingerTapSlop = 8;

/// Recognises a quick two-finger tap (both fingers down together, barely
/// moving, both up fast). Pure logic, fed with pointer events.
class TwoFingerTapDetector {
  final Map<int, Offset> _start = {};
  final Map<int, Offset> _now = {};
  double _startGap = 0;
  int _firstDownMs = 0;
  bool _broken = false;
  bool _hadTwo = false;

  void down(int pointer, Offset pos, int timeMs) {
    if (_start.isEmpty) {
      _firstDownMs = timeMs;
      _broken = false;
      _hadTwo = false;
    }
    _start[pointer] = pos;
    _now[pointer] = pos;
    if (_start.length == 2) {
      _hadTwo = true;
      _startGap = (_now.values.first - _now.values.last).distance;
    }
    if (_start.length > 2) _broken = true;
  }

  void move(int pointer, Offset pos) {
    final s = _start[pointer];
    if (s == null) return;
    _now[pointer] = pos;
    if ((pos - s).distance > kTwoFingerTapSlop) _broken = true;
    if (_hadTwo && _now.length == 2) {
      final gap = (_now.values.first - _now.values.last).distance;
      if ((gap - _startGap).abs() > kTwoFingerTapSlop) _broken = true;
    }
  }

  /// Returns true when this release completes a two-finger tap.
  bool up(int pointer, int timeMs) {
    _start.remove(pointer);
    _now.remove(pointer);
    if (_start.isNotEmpty) return false;
    final ok =
        _hadTwo && !_broken && timeMs - _firstDownMs <= kTwoFingerTapMaxMs;
    _hadTwo = false;
    _broken = false;
    return ok;
  }

  void cancel() {
    _start.clear();
    _now.clear();
    _broken = false;
    _hadTwo = false;
  }
}

/// Reports two-finger taps without taking part in the gesture arena, so the
/// existing one-finger, scale and drag gestures keep working unchanged.
class TwoFingerTapRegion extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const TwoFingerTapRegion(
      {super.key, required this.child, required this.onTap});

  @override
  State<TwoFingerTapRegion> createState() => _TwoFingerTapRegionState();
}

class _TwoFingerTapRegionState extends State<TwoFingerTapRegion> {
  final _d = TwoFingerTapDetector();

  int _ms(Duration t) => t.inMilliseconds;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _d.down(e.pointer, e.position, _ms(e.timeStamp)),
      onPointerMove: (e) => _d.move(e.pointer, e.position),
      onPointerUp: (e) {
        if (_d.up(e.pointer, _ms(e.timeStamp))) widget.onTap();
      },
      onPointerCancel: (_) => _d.cancel(),
      child: widget.child,
    );
  }
}
