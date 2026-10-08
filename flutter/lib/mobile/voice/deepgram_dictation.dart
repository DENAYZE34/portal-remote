import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'cert_pin.dart';
import 'deepgram_transcript.dart';

// Token proxy (server/dg-proxy): the Deepgram key lives only on the server.
const String _kProxyUrl = String.fromEnvironment('PORTAL_DG_URL');
const String _kProxySecret = String.fromEnvironment('PORTAL_DG_SECRET');
const String _kProxyFingerprint = String.fromEnvironment('PORTAL_DG_FP');
const String _kDeepgramModel =
    String.fromEnvironment('DEEPGRAM_MODEL', defaultValue: 'nova-3');

/// Languages offered in the panel: Deepgram code and label.
const Map<String, String> kDictationLanguages = {
  'ru': 'RU',
  'en': 'EN',
};

/// Hold-to-talk dictation. The microphone starts at once and audio is buffered
/// while the Deepgram socket connects; every finished phrase is delivered
/// through [onCommit] immediately, not after the button is released.
class DeepgramDictation {
  /// Live text (final + interim) for the bubble.
  final void Function(String text)? onText;

  /// Finished text to type on the PC right now.
  final void Function(String text)? onCommit;

  /// Connection or microphone failure after [start] already returned.
  final void Function(String message)? onError;

  DeepgramDictation({this.onText, this.onCommit, this.onError});

  static String language = 'ru';

  // One microphone: the hold-to-talk hub and the bar button must not overlap.
  static bool _micBusy = false;

  final AudioRecorder _recorder = AudioRecorder();
  final DeepgramTranscript _transcript = DeepgramTranscript();
  final List<Uint8List> _buffer = [];
  WebSocket? _socket;
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription? _socketSub;
  Timer? _keepAlive;
  Completer<void>? _flushed;
  Future<void>? _connecting;
  bool _active = false;
  bool _stopping = false;

  static bool get configured =>
      _kProxyUrl.isNotEmpty &&
      _kProxySecret.isNotEmpty &&
      _kProxyFingerprint.isNotEmpty;

  bool get active => _active;

  Future<String> _fetchToken() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) =>
          certMatches(cert.der, _kProxyFingerprint);
    try {
      final req = await client.getUrl(Uri.parse(_kProxyUrl));
      req.headers.set('X-Portal-Secret', _kProxySecret);
      final resp = await req.close().timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) {
        throw HttpException('token proxy status ${resp.statusCode}');
      }
      final body = await resp.transform(utf8.decoder).join();
      return (jsonDecode(body) as Map<String, dynamic>)['access_token']
          as String;
    } finally {
      client.close(force: true);
    }
  }

  /// Starts the microphone immediately. Returns an error message, or null
  /// when recording started; the connection continues in the background.
  Future<String?> start() async {
    if (_active) return null;
    if (_micBusy) return 'Microphone is busy';
    if (!configured) return 'Voice proxy is not configured in this build';
    if (!await _recorder.hasPermission()) return 'Microphone permission denied';
    _transcript.reset();
    _buffer.clear();
    _stopping = false;
    final Stream<Uint8List> stream;
    try {
      stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
    } catch (e) {
      return 'Microphone start failed';
    }
    _active = true;
    _micBusy = true;
    _audioSub = stream.listen((data) {
      final s = _socket;
      if (s != null) {
        s.add(data);
      } else {
        _buffer.add(data);
      }
    });
    _connecting = _connect();
    return null;
  }

  Future<void> _connect() async {
    try {
      final String token;
      try {
        token = await _fetchToken();
      } catch (e) {
        return _fail('Voice server unreachable');
      }
      final uri = Uri.parse('wss://api.deepgram.com/v1/listen').replace(
        queryParameters: {
          'model': _kDeepgramModel,
          'language': language,
          'encoding': 'linear16',
          'sample_rate': '16000',
          'channels': '1',
          'smart_format': 'true',
          'punctuate': 'true',
          'interim_results': 'true',
          'endpointing': '300',
        },
      );
      final WebSocket socket;
      try {
        socket = await WebSocket.connect(uri.toString(), headers: {
          'Authorization': 'Bearer $token',
        }).timeout(const Duration(seconds: 6));
      } catch (e) {
        return _fail('Deepgram connection failed');
      }
      _socketSub = socket.listen(_onMessage, onError: (_) {}, onDone: _release);
      for (final chunk in _buffer) {
        socket.add(chunk);
      }
      _buffer.clear();
      _socket = socket;
      _keepAlive = Timer.periodic(const Duration(seconds: 5), (_) {
        _socket?.add(jsonEncode({'type': 'KeepAlive'}));
      });
    } catch (e) {
      return _fail('Deepgram connection failed');
    }
  }

  Future<void> _fail(String message) async {
    if (!_active) return;
    _active = false;
    _micBusy = false;
    _keepAlive?.cancel();
    await _audioSub?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    _buffer.clear();
    onError?.call(message);
  }

  void _release() {
    final f = _flushed;
    if (f != null && !f.isCompleted) f.complete();
  }

  void _onMessage(dynamic raw) {
    if (!_transcript.feed(raw)) return;
    onText?.call(_transcript.composed);
    final text = _transcript.takeCommitted();
    if (text.isNotEmpty) onCommit?.call(text);
    if (_transcript.flushed) _release();
  }

  /// Stops recording, waits for Deepgram to flush and returns any text that
  /// was not already delivered through [onCommit].
  Future<String> stop() async {
    if (!_active || _stopping) return '';
    _stopping = true;
    await _connecting;
    if (!_active) return '';
    _active = false;
    _micBusy = false;
    _keepAlive?.cancel();
    await _audioSub?.cancel();
    await _recorder.stop();
    final socket = _socket;
    if (socket != null) {
      _flushed = Completer<void>();
      socket.add(jsonEncode({'type': 'Finalize'}));
      await _flushed!.future
          .timeout(const Duration(milliseconds: 1800), onTimeout: () {});
      socket.add(jsonEncode({'type': 'CloseStream'}));
      await _socketSub?.cancel();
      await socket.close();
    }
    _socket = null;
    final out = _transcript.takeCommitted() + _transcript.takeTail();
    _transcript.reset();
    return out;
  }

  Future<void> dispose() async {
    if (_active) await stop();
    await _recorder.dispose();
  }
}
