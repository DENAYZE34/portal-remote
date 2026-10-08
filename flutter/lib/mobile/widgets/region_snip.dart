import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';

import '../../common.dart';

/// Region screenshot of the remote PC, done from the phone:
/// 1. the user draws a rectangle on the phone screen,
/// 2. the app opens Windows "Snip" (Win+Shift+S) on the PC,
/// 3. the app drags the mouse over the same area on the PC,
/// 4. Windows puts the picture in the PC clipboard; the user pastes it (Ctrl+V)
///    into any field on the PC.
Future<void> startRegionSnip(BuildContext context, FFI ffi) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  void close() {
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (_) => _SnipSelector(
      onCancel: close,
      onSelected: (rect) {
        close();
        unawaited(_performSnip(ffi, rect));
      },
    ),
  );
  overlay.insert(entry);
}

/// Points of a straight drag from [a] to [b] in [steps] equal steps (both ends included).
List<Offset> dragPath(Offset a, Offset b, int steps) {
  final n = math.max(1, steps);
  return [
    for (var i = 0; i <= n; i++)
      Offset(a.dx + (b.dx - a.dx) * i / n, a.dy + (b.dy - a.dy) * i / n)
  ];
}

Future<void> _performSnip(FFI ffi, Rect rect) async {
  final im = ffi.inputModel;
  if (rect.width < 8 || rect.height < 8) {
    showToast('Область слишком мала');
    return;
  }
  final a = im.handlePointerDevicePos(
      'mouse', rect.left, rect.top, false, 'move');
  final b = im.handlePointerDevicePos(
      'mouse', rect.right, rect.bottom, false, 'move');
  if (a == null || b == null) {
    showToast('Не удалось определить область на экране ПК');
    return;
  }
  // 1. open Windows Snip on the PC
  final prevCmd = im.command;
  final prevShift = im.shift;
  im.command = true;
  im.shift = true;
  im.inputKey('VK_S');
  im.command = prevCmd;
  im.shift = prevShift;
  await Future.delayed(const Duration(milliseconds: 900));
  // 2. drag the selection on the PC
  final path = dragPath(Offset(a.x.toDouble(), a.y.toDouble()),
      Offset(b.x.toDouble(), b.y.toDouble()), 10);
  await im.moveMouse(path.first.dx, path.first.dy);
  await Future.delayed(const Duration(milliseconds: 120));
  await im.sendMouse('down', MouseButtons.left);
  for (final p in path.skip(1)) {
    await im.moveMouse(p.dx, p.dy);
    await Future.delayed(const Duration(milliseconds: 25));
  }
  await Future.delayed(const Duration(milliseconds: 100));
  await im.sendMouse('up', MouseButtons.left);
  HapticFeedback.mediumImpact();
  showToast('Скриншот в буфере ПК. Нажмите «Вставить» в нужном поле.');
}

class _SnipSelector extends StatefulWidget {
  final VoidCallback onCancel;
  final void Function(Rect) onSelected;
  const _SnipSelector({required this.onCancel, required this.onSelected});

  @override
  State<_SnipSelector> createState() => _SnipSelectorState();
}

class _SnipSelectorState extends State<_SnipSelector> {
  Offset? _start;
  Offset? _end;

  Rect? get _rect =>
      (_start == null || _end == null) ? null : Rect.fromPoints(_start!, _end!);

  @override
  Widget build(BuildContext context) {
    final rect = _rect;
    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => setState(() {
              _start = d.globalPosition;
              _end = d.globalPosition;
            }),
            onPanUpdate: (d) => setState(() => _end = d.globalPosition),
            onPanEnd: (_) {
              final r = _rect;
              if (r != null) widget.onSelected(r);
            },
            child: CustomPaint(painter: _SnipPainter(rect)),
          ),
        ),
        Positioned(
          top: 56,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Проведите пальцем и выделите область',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ),
        ),
        Positioned(
          top: 48,
          right: 12,
          child: IconButton(
            color: Colors.white,
            icon: const Icon(Icons.close),
            onPressed: widget.onCancel,
          ),
        ),
      ]),
    );
  }
}

class _SnipPainter extends CustomPainter {
  final Rect? rect;
  _SnipPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withOpacity(0.45);
    final full = Offset.zero & size;
    final r = rect;
    if (r == null) {
      canvas.drawRect(full, dim);
      return;
    }
    final path = Path()
      ..addRect(full)
      ..addRect(r)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dim);
    canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.cyanAccent);
  }

  @override
  bool shouldRepaint(covariant _SnipPainter old) => old.rect != rect;
}
