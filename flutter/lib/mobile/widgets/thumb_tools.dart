import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/input_model.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../../common.dart';
import '../voice/deepgram_dictation.dart';
import 'ring_config.dart';

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
  String? _editId;
  bool _panelOpen = false;
  bool _fnRow = false;
  bool _recording = false;
  String _bubble = '';

  // 0 = off, 1 = next key only, 2 = locked.
  final Map<_Mod, int> _mods = {for (final m in _Mod.values) m: 0};

  static const String _kRingKey = 'portal-ring';
  static const String _kLangKey = 'portal-dg-lang';

  List<String> _ring = parseRing(bind.mainGetLocalOption(key: _kRingKey));

  late final DeepgramDictation _dictation = DeepgramDictation(
    onText: (t) {
      if (mounted) setState(() => _bubble = t);
    },
    onCommit: _type,
    onError: (msg) {
      if (mounted) setState(() => _recording = false);
      showToast(msg);
    },
  );

  InputModel get _im => widget.ffi.inputModel;

  @override
  void initState() {
    super.initState();
    final lang = bind.mainGetLocalOption(key: _kLangKey);
    if (kDictationLanguages.containsKey(lang)) {
      DeepgramDictation.language = lang;
    }
  }

  void _type(String text) {
    bind.sessionInputString(sessionId: widget.ffi.sessionId, value: text);
  }

  void _setRing(List<String> ring) {
    setState(() => _ring = ring);
    bind.mainSetLocalOption(key: _kRingKey, value: encodeRing(ring));
  }

  void _setLanguage(String lang) {
    setState(() => DeepgramDictation.language = lang);
    bind.mainSetLocalOption(key: _kLangKey, value: lang);
  }

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
      _type(text);
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
        if (i < _ring.length && _ring[i] == _editId) {
          final id = _ring[i];
          final above = p.dy > 100;
          final dy = above ? p.dy - 46 : p.dy + _item + 6;
          children.add(Positioned(
            left: p.dx - 24,
            top: dy,
            child: _editIcon(Icons.swap_horiz, Colors.blueGrey,
                () => _replace(id)),
          ));
          if (canRemove(id)) {
            children.add(Positioned(
              left: p.dx + _item - 16,
              top: dy,
              child: _editIcon(
                  Icons.delete_outline, Colors.redAccent, () => _delete(id)),
            ));
          }
        }
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
    return RawGestureDetector(
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (g) => g.onTap = () {
            HapticFeedback.selectionClick();
            setState(() {
              _ringOpen = !_ringOpen;
              _editId = null;
            });
          },
        ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
              duration: const Duration(milliseconds: 220)),
          (g) => g
            ..onLongPressStart = (_) {
              setState(() => _ringOpen = false);
              _micDown();
            }
            ..onLongPressEnd = (_) {
              _micUp();
            }
            ..onLongPressCancel = () {
              _micUp();
            },
        ),
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (g) => g.onUpdate = (d) {
            final size = MediaQuery.of(context).size;
            setState(
                () => _pos = _clamp((_pos ?? Offset.zero) + d.delta, size));
          },
        ),
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

  static const Map<String, (IconData, String)> _look = {
    'mic': (Icons.mic, 'Голос'),
    'rclick': (Icons.mouse, 'Правый клик'),
    'copy': (Icons.copy, 'Копировать'),
    'paste': (Icons.paste, 'Вставить'),
    'cut': (Icons.content_cut, 'Вырезать'),
    'undo': (Icons.undo, 'Отмена'),
    'all': (Icons.select_all, 'Выделить всё'),
    'enter': (Icons.keyboard_return, 'Enter'),
    'esc': (Icons.close, 'Esc'),
    'tab': (Icons.keyboard_tab, 'Tab'),
    'bksp': (Icons.backspace_outlined, 'Backspace'),
    'del': (Icons.delete_outline, 'Delete'),
    'home': (Icons.first_page, 'Home'),
    'end': (Icons.last_page, 'End'),
    'left': (Icons.arrow_back, 'Влево'),
    'up': (Icons.arrow_upward, 'Вверх'),
    'down': (Icons.arrow_downward, 'Вниз'),
    'right': (Icons.arrow_forward, 'Вправо'),
    'more': (Icons.more_horiz, 'Ещё'),
  };

  void _runAction(String id) {
    switch (id) {
      case 'rclick':
        _im.tap(MouseButtons.right);
      case 'copy':
        _chord('VK_C');
      case 'paste':
        _chord('VK_V');
      case 'cut':
        _chord('VK_X');
      case 'undo':
        _chord('VK_Z');
      case 'all':
        _chord('VK_A');
      case 'enter':
        _key('VK_RETURN');
      case 'esc':
        _key('VK_ESCAPE');
      case 'tab':
        _key('VK_TAB');
      case 'bksp':
        _key('VK_BACK');
      case 'del':
        _key('VK_DELETE');
      case 'home':
        _key('VK_HOME');
      case 'end':
        _key('VK_END');
      case 'left':
        _key('VK_LEFT');
      case 'up':
        _key('VK_UP');
      case 'down':
        _key('VK_DOWN');
      case 'right':
        _key('VK_RIGHT');
      case 'more':
        setState(() {
          _panelOpen = !_panelOpen;
          _ringOpen = false;
          if (!_panelOpen) _resetMods();
        });
    }
  }

  List<Widget> _ringItems() {
    return [
      for (final id in _ring)
        id == 'mic'
            ? _micButton()
            : _ringButton(_look[id]!.$1, () => _runAction(id),
                onLongPress: !canRemove(id)
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        setState(() => _editId = id);
                      }),
      if (canAdd(_ring) && availableToAdd(_ring).isNotEmpty)
        _ringButton(Icons.add, _addMenu),
    ];
  }

  Future<String?> _pickAction(String title, List<String> ids) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              for (final id in ids)
                IconButton.filledTonal(
                  iconSize: 28,
                  icon: Icon(_look[id]!.$1),
                  onPressed: () => Navigator.pop(ctx, id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addMenu() async {
    final id = await _pickAction('Добавить кнопку', availableToAdd(_ring));
    if (id != null) _setRing(addAction(_ring, id));
  }

  Future<void> _replace(String id) async {
    setState(() => _editId = null);
    final to = await _pickAction('', availableToAdd(_ring));
    if (to != null) _setRing(replaceAction(_ring, id, to));
  }

  void _delete(String id) {
    setState(() => _editId = null);
    _setRing(removeAction(_ring, id));
  }

  Widget _editIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _ringButton(IconData icon, VoidCallback onTap,
      {VoidCallback? onLongPress}) {
    return Material(
      color: MyTheme.accent80,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onLongPress: onLongPress,
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
        for (final e in kDictationLanguages.entries)
          _keyBtn('\u{1F3A4} ${e.value}', () => _setLanguage(e.key),
              active: DeepgramDictation.language == e.key, minWidth: 64),
      ]),
      Wrap(alignment: WrapAlignment.center, children: [
        _keyBtn('Esc', () => _key('VK_ESCAPE')),
        _keyBtn('Tab', () => _key('VK_TAB')),
        _keyBtn('⌫', () => _key('VK_BACK')),
        _keyBtn('Del', () => _key('VK_DELETE')),
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
