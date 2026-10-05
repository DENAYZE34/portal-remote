import 'dart:convert';

/// Accumulates Deepgram live-streaming `Results` messages into one text.
class DeepgramTranscript {
  final StringBuffer _final = StringBuffer();
  String _interim = '';
  bool _flushed = false;

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
    if (msg['is_final'] == true) {
      if (text.isNotEmpty) {
        if (_final.isNotEmpty) _final.write(' ');
        _final.write(text);
      }
      _interim = '';
      if (msg['from_finalize'] == true) _flushed = true;
    } else {
      _interim = text;
    }
    return true;
  }
}
