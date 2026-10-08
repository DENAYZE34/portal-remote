import 'dart:convert';

/// Accumulates Deepgram live-streaming `Results` messages into one text and
/// hands out words to type as soon as they are stable, so text appears while
/// the user is still speaking.
///
/// A word is stable when two consecutive interim results agree on it at the
/// same position. Words are never taken back: when the final result of a phrase
/// arrives, only the words after the ones already typed are added.
class DeepgramTranscript {
  final StringBuffer _final = StringBuffer();
  String _interim = '';
  bool _flushed = false;
  final List<String> _pending = [];
  bool _typedAny = false;
  List<String> _prevInterim = const [];
  int _phraseCommitted = 0;

  static List<String> _words(String t) {
    final s = t.trim();
    return s.isEmpty ? const [] : s.split(RegExp(r'\s+'));
  }

  /// True once a `from_finalize` result arrived (reply to a Finalize request).
  bool get flushed => _flushed;

  /// Final segments plus the current interim tail.
  String get composed {
    if (_interim.isEmpty) return _final.toString();
    return _final.isEmpty ? _interim : '$_final $_interim';
  }

  /// Text to type: final segments, or the interim tail if nothing was final.
  String get result => (_final.isNotEmpty ? _final.toString() : _interim).trim();

  void reset() {
    _final.clear();
    _interim = '';
    _flushed = false;
    _pending.clear();
    _typedAny = false;
    _prevInterim = const [];
    _phraseCommitted = 0;
  }

  /// Words ready to type and not handed out yet, with a leading space when
  /// something was already typed in this utterance. Empty if none.
  String takeCommitted() {
    if (_pending.isEmpty) return '';
    final text = _pending.join(' ');
    _pending.clear();
    final out = _typedAny ? ' $text' : text;
    _typedAny = true;
    return out;
  }

  /// Interim words never confirmed; last resort on stop.
  String takeTail() {
    final words = _words(_interim);
    _interim = '';
    _prevInterim = const [];
    if (words.length <= _phraseCommitted) {
      _phraseCommitted = 0;
      return '';
    }
    final tail = words.sublist(_phraseCommitted).join(' ');
    _phraseCommitted = 0;
    final out = _typedAny ? ' $tail' : tail;
    _typedAny = true;
    return out;
  }

  /// Feeds one raw websocket message. Returns true if [composed] may have changed.
  bool feed(dynamic raw) {
    if (raw is! String) return false;
    final Map<String, dynamic> msg;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      msg = decoded;
    } catch (_) {
      return false;
    }
    if (msg['type'] != 'Results') return false;
    final alts = (msg['channel']?['alternatives'] as List?) ?? const [];
    final text = alts.isEmpty ? '' : (alts.first['transcript'] ?? '').toString();
    final words = _words(text);
    if (msg['is_final'] == true) {
      if (text.isNotEmpty) {
        if (_final.isNotEmpty) _final.write(' ');
        _final.write(text);
      }
      if (words.length > _phraseCommitted) {
        _pending.add(words.sublist(_phraseCommitted).join(' '));
      }
      _phraseCommitted = 0;
      _prevInterim = const [];
      _interim = '';
      if (msg['from_finalize'] == true) _flushed = true;
    } else {
      var stable = 0;
      final limit =
          words.length < _prevInterim.length ? words.length : _prevInterim.length;
      while (stable < limit && words[stable] == _prevInterim[stable]) {
        stable++;
      }
      if (stable > _phraseCommitted) {
        _pending.add(words.sublist(_phraseCommitted, stable).join(' '));
        _phraseCommitted = stable;
      }
      _prevInterim = words;
      _interim = text;
    }
    return true;
  }
}
