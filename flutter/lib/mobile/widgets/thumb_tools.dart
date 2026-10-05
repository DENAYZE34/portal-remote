import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../../common.dart';
import '../voice/deepgram_dictation.dart';

enum _Mod { ctrl, alt, shift, cmd }

/// One-thumb tools: a draggable hub. Hold the hub to dictate, tap it to open
/// a ring (mic, right click, copy, paste, Enter, more). "More" opens a bottom
/// key panel with Esc/Tab/modifiers/arrows/F-keys.
class ThumbTools extends StatefulWidget {
  final FFI ffi;
  const ThumbTools({Key? key, required this.ffi}) : super(key: key);

  @override
  State<ThumbTools> createState() => _ThumbToolsState();
}

class _ThumbToolsState extends State<ThumbTools> {
  static const double _hub = 56;
  static const double _item = 48;
  static const double _radius = 86;

  Offset? _pos;
  bool _ringOpen = false;
  bool _panelOpen = false;
  bool _fnRow = false;
  bool _recording = false;
  String _bubble = '';

  // 0 = off, 1 = next key only, 2 = locked.
  final Map<_Mod, int> _mods = {for (final m in _Mod.values) m: 0};

  late final DeepgramDictation _dictation =
      DeepgramDictation(onText: (t) => setState(() => _bubble = t));

  InputModel get _im => widget.ffi.inputModel;

  @override
  void dispose() {
    _resetMods();
    _dictation.dispose();
    super.dispose();
  }

  void _syncMods() {
    _im.ctrl = _mods[_Mod.ctrl]! > 0;
    _im.alt = _mods[_Mod.alt]! > 0;
    _im.shift = _mods[_Mod.shift]! > 0;
    _im.command = _mods[_Mod.cmd]! > 0;
  }

  void _resetMods() {
    for (final m in _Mod.values) {
      _mods[m] = 0;
    }
    _syncMods();
  }

  void _consumeOnce() {
    var changed = false;
    for (final m in _Mod.values) {
      if (_mods[m] == 1) {
        _mods[m] = 0;
        changed = true;
      }
    }
    if (changed) {
      _syncMods();
      if (mounted) setState(() {});
    }
  }

  void _tapMod(_Mod m) {
    HapticFeedback.selectionClick();
    setState(() {
      _mods[m] = (_mods[m]! + 1) % 3;
      _syncMods();
    });
  }

  void _key(String name) {
    HapticFeedback.selectionClick();
    _im.inputKey(name);
    _consumeOnce();
  }

  bool get _isMac => widget.ffi.ffiModel.pi.platform == kPeerPlatformMacOS;

  void _chord(String name) {
    HapticFeedback.selectionClick();
    final prevCtrl = _im.ctrl;
    final prevCmd = _im.command;
    if (_isMac) {
      _im.command = true;
    } else {
      _im.ctrl = true;
    }
    _im.inputKey(name);
    _im.ctrl = prevCtrl;
    _im.command = prevCmd;
    _consumeOnce();
  }

  Future<void> _micDown() async {
    if (_recording) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _recording = true;
      _bubble = '';
    });
    final err = await _dictation.start();
    if (err != null) {
      if (mounted) setState(() => _recording = false);
      showToast(err);
    }
  }

  Future<void> _micUp() async {
    if (!_recording) return;
    final text = await _dictation.stop();
    if (mounted) {
      setState(() {
        _recording = false;
        _bubble = '';
      });
    }
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      bind.sessionInputString(sessionId: widget.ffi.sessionId, value: text);
    }
  }

  Offset _clamp(Offset p, Size s) {
    return Offset(
      p.dx.clamp(8.0, math.max(8.0, s.width - _hub - 8)).toDouble(),
      p.dy.clamp(40.0, math.max(40.0, s.height - _hub - 8)).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _pos ??= Offset(size.width - _hub - 16, size.height * 0.62);
    final pos = _clamp(_pos!, size);
    final hubCenter = pos + const Offset(_hub / 2, _hub / 2);

    final children = <Widget>[];

    if (_panelOpen) {
      children.add(Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: _buildPanel(),
      ));
    }

    if (_ringOpen) {
      final items = _ringItems();
      final toCenter = math.atan2(
          size.height / 2 - hubCenter.dy, size.width / 2 - hubCenter.dx);
      final step = 0.55;
      for (var i = 0; i < items.length; i++) {
        final a = toCenter + (i - (items.length - 1) / 2) * step;
        final c = hubCenter + Offset(math.cos(a), math.sin(a)) * _radius;
        final p = _clamp(c - const Offset(_item / 2, _item / 2), size);
        children.add(Positioned(left: p.dx, top: p.dy, child: items[i]));
      }
    }

    children.add(Positioned(left: pos.dx, top: pos.dy, child: _buildHub()));

    if (_recording || _bubble.isNotEmpty) {
      children.add(Positioned(
        top: 48,
        left: 16,
        right: 16,
        child: IgnorePointer(child: _buildBubble()),
      ));
    }

    return Positioned.fill(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _buildBubble() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mic, color: _recording ? Colors.redAccent : Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _bubble.isEmpty ? '...' : _bubble,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHub() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _ringOpen = !_ringOpen);
      },
      onLongPressStart: (_) {
        setState(() => _ringOpen = false);
        _micDown();
      },
      onLongPressEnd: (_) => _micUp(),
      onLongPressCancel: () => _micUp(),
      onPanUpdate: (d) {
        final size = MediaQuery.of(context).size;
        setState(() => _pos = _clamp((_pos ?? Offset.zero) + d.delta, size));
      },
      child: Container(
        width: _hub,
        height: _hub,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _recording ? Colors.redAccent : MyTheme.accent,
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, spreadRadius: 1)
          ],
        ),
        child: Icon(
          _recording ? Icons.mic : Icons.touch_app,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  List<Widget> _ringItems() {
    return [
      _micButton(),
      _ringButton(Icons.mouse, () => _im.tap(MouseButtons.right)),
      _ringButton(Icons.copy, () => _chord('VK_C')),
      _ringButton(Icons.paste, () => _chord('VK_V')),
      _ringButton(Icons.keyboard_return, () => _key('VK_RETURN')),
      _ringButton(
        Icons.more_horiz,
        () => setState(() {
          _panelOpen = !_panelOpen;
          _ringOpen = false;
          if (!_panelOpen) _resetMods();
        }),
      ),
    ];
  }

  Widget _ringButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: MyTheme.accent80,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: _item,
          height: _item,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _micButton() {
    return Listener(
      onPointerDown: (_) => _micDown(),
      onPointerUp: (_) => _micUp(),
      onPointerCancel: (_) => _micUp(),
      child: Material(
        color: _recording ? Colors.redAccent : MyTheme.accent80,
        shape: const CircleBorder(),
        elevation: 4,
        child: const SizedBox(
          width: _item,
          height: _item,
          child: Icon(Icons.mic, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _keyBtn(String label, VoidCallback onTap,
      {bool? active, bool locked = false, double minWidth = 48}) {
    final bg = locked
        ? Colors.orange
        : (active == true ? MyTheme.accent : Colors.white12);
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minWidth: minWidth, minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _modBtn(String label, _Mod m) {
    final s = _mods[m]!;
    return _keyBtn(s == 2 ? '$label \u{1F512}' : label, () => _tapMod(m),
        active: s == 1, locked: s == 2, minWidth: 64);
  }

  Widget _buildPanel() {
    final rows = <Widget>[
      Wrap(alignment: WrapAlignment.center, children: [
        _keyBtn('Esc', () => _key('VK_ESCAPE')),
        _keyBtn('Tab', () => _key('VK_TAB')),
        _keyBtn('⌫', () => _key('VK_BACK')),
        _keyBtn('Del', () => _key('VK_DELETE')),
        _keyBtn('Enter', () => _key('VK_RETURN')),
        _keyBtn('Home', () => _key('VK_HOME')),
        _keyBtn('End', () => _key('VK_END')),
      ]),
      Wrap(alignment: WrapAlignment.center, children: [
        _modBtn('Ctrl', _Mod.ctrl),
        _modBtn('Alt', _Mod.alt),
        _modBtn('Shift', _Mod.shift),
        _modBtn(_isMac ? 'Cmd' : 'Win', _Mod.cmd),
      ]),
      Wrap(alignment: WrapAlignment.center, children: [
        _keyBtn('←', () => _key('VK_LEFT')),
        _keyBtn('↑', () => _key('VK_UP')),
        _keyBtn('↓', () => _key('VK_DOWN')),
        _keyBtn('→', () => _key('VK_RIGHT')),
        _keyBtn('Undo', () => _chord('VK_Z')),
        _keyBtn('All', () => _chord('VK_A')),
        _keyBtn('Cut', () => _chord('VK_X')),
        _keyBtn('F1-12', () => setState(() => _fnRow = !_fnRow),
            active: _fnRow),
      ]),
    ];
    if (_fnRow) {
      rows.add(Wrap(alignment: WrapAlignment.center, children: [
        for (var i = 1; i <= 12; i++)
          _keyBtn('F$i', () => _key('VK_F$i'), minWidth: 44),
      ]));
    }
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 200) {
          setState(() {
            _panelOpen = false;
            _resetMods();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 12),
        decoration: const BoxDecoration(
          color: Color(0xE6101418),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...rows,
          ]),
        ),
      ),
    );
  }
}
