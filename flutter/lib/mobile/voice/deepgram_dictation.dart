import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'deepgram_transcript.dart';

const String _kDeepgramKey = String.fromEnvironment('DEEPGRAM_API_KEY');
const String _kDeepgramLanguage =
    String.fromEnvironment('DEEPGRAM_LANGUAGE', defaultValue: 'multi');
const String _kDeepgramModel =
    String.fromEnvironment('DEEPGRAM_MODEL', defaultValue: 'nova-3');

/// Hold-to-talk dictation: audio goes to Deepgram over a WebSocket,
/// the finished text is returned once, when [stop] completes.
class DeepgramDictation {
  final void Function(String text)? onText;

  DeepgramDictation({this.onText});

  final AudioRecorder _recorder = AudioRecorder();
  final DeepgramTranscript _transcript = DeepgramTranscript();
  WebSocket? _socket;
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription? _socketSub;
  Timer? _keepAlive;
  Completer<void>? _flushed;
  bool _active = false;

  static bool get hasKey => _kDeepgramKey.isNotEmpty;

  bool get active => _active;

  /// Returns an error message, or null when recording started.
  Future<String?> start() async {
    if (_active) return null;
    if (!hasKey) return 'Deepgram key is not built into this app';
    if (!await _recorder.hasPermission()) return 'Microphone permission denied';
    _transcript.reset();
    try {
      final uri = Uri.parse('wss://api.deepgram.com/v1/listen').replace(
        queryParameters: {
          'model': _kDeepgramModel,
          'language': _kDeepgramLanguage,
          'encoding': 'linear16',
          'sample_rate': '16000',
          'channels': '1',
          'smart_format': 'true',
          'punctuate': 'true',
          'interim_results': 'true',
          'endpointing': '1000',
        },
      );
      _socket = await WebSocket.connect(uri.toString(), headers: {
        'Authorization': 'Token $_kDeepgramKey',
      }).timeout(const Duration(seconds: 6));
    } catch (e) {
      _socket = null;
      return 'Deepgram connection failed';
    }
    _socketSub = _socket!.listen(_onMessage, onError: (_) {}, onDone: _release);
    _keepAlive = Timer.periodic(const Duration(seconds: 5), (_) {
      _socket?.add(jsonEncode({'type': 'KeepAlive'}));
    });
    try {
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      _audioSub = stream.listen((data) => _socket?.add(data));
    } catch (e) {
      _keepAlive?.cancel();
      await _socketSub?.cancel();
      await _socket?.close();
      _socket = null;
      return 'Microphone start failed';
    }
    _active = true;
    return null;
  }

  void _release() {
    final f = _flushed;
    if (f != null && !f.isCompleted) f.complete();
  }

  void _onMessage(dynamic raw) {
    if (!_transcript.feed(raw)) return;
    onText?.call(_transcript.composed);
    if (_transcript.flushed) _release();
  }

  /// Stops recording, waits for Deepgram to flush and returns the text.
  Future<String> stop() async {
    if (!_active) return '';
    _active = false;
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
    final out = _transcript.result;
    _transcript.reset();
    return out;
  }

  Future<void> dispose() async {
    if (_active) await stop();
    await _recorder.dispose();
  }
}
