import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../../common.dart';
import '../voice/deepgram_dictation.dart';

/// Bottom-bar microphone: tap to start dictation, tap again to stop.
/// Words are typed on the remote PC while you speak. Long-press switches
/// between Russian and English.
class VoiceToggleButton extends StatefulWidget {
  final FFI ffi;
  const VoiceToggleButton({Key? key, required this.ffi}) : super(key: key);

  @override
  State<VoiceToggleButton> createState() => _VoiceToggleButtonState();
}

class _VoiceToggleButtonState extends State<VoiceToggleButton> {
  static const String _kLangKey = 'portal-dg-lang';

  final ValueNotifier<String> _bubble = ValueNotifier('');
  OverlayEntry? _entry;
  bool _on = false;
  bool _busy = false;

  late final DeepgramDictation _dictation = DeepgramDictation(
    onText: (t) => _bubble.value = t,
    onCommit: _type,
    onError: (msg) {
      _hideBubble();
      if (mounted) setState(() => _on = false);
      showToast(msg);
    },
  );

  @override
  void initState() {
    super.initState();
    final lang = bind.mainGetLocalOption(key: _kLangKey);
    if (kDictationLanguages.containsKey(lang)) {
      DeepgramDictation.language = lang;
    }
  }

  @override
  void dispose() {
    _hideBubble();
    _dictation.dispose();
    _bubble.dispose();
    super.dispose();
  }

  void _type(String text) {
    bind.sessionInputString(sessionId: widget.ffi.sessionId, value: text);
  }

  void _showBubble() {
    _bubble.value = '';
    _entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 48,
        left: 16,
        right: 16,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.78),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: _bubble,
                builder: (_, text, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        text.isEmpty ? '...' : text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hideBubble() {
    _entry?.remove();
    _entry = null;
  }

  Future<void> _toggle() async {
    if (_busy) return;
    _busy = true;
    try {
      HapticFeedback.mediumImpact();
      if (!_on) {
        final err = await _dictation.start();
        if (err != null) {
          showToast(err);
          return;
        }
        if (!mounted) return;
        _showBubble();
        setState(() => _on = true);
      } else {
        final text = await _dictation.stop();
        _hideBubble();
        if (mounted) setState(() => _on = false);
        if (text.isNotEmpty) _type(text);
      }
    } finally {
      _busy = false;
    }
  }

  void _switchLanguage() {
    if (_on) return;
    final next = DeepgramDictation.language == 'ru' ? 'en' : 'ru';
    DeepgramDictation.language = next;
    bind.mainSetLocalOption(key: _kLangKey, value: next);
    HapticFeedback.selectionClick();
    showToast(kDictationLanguages[next] ?? next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _switchLanguage,
      child: IconButton(
        color: _on ? Colors.redAccent : Colors.white,
        icon: Icon(_on ? Icons.stop_circle : Icons.mic),
        tooltip: kDictationLanguages[DeepgramDictation.language],
        onPressed: _toggle,
      ),
    );
  }
}
