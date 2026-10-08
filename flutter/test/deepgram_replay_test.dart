import 'dart:convert';
import 'dart:io';

import 'package:flutter_hbb/mobile/voice/deepgram_transcript.dart';
import 'package:flutter_test/flutter_test.dart';

// Replays real Deepgram sessions (recorded with the app's exact stream
// parameters from synthesized speech) and checks the text typed on the PC.
String _typedFor(String name) {
  final lines = File('test/fixtures/deepgram_$name.jsonl')
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty);
  final t = DeepgramTranscript();
  final out = StringBuffer();
  for (final line in lines) {
    t.feed((jsonDecode(line) as Map<String, dynamic>)['raw']);
    out.write(t.takeCommitted());
  }
  out.write(t.takeCommitted());
  out.write(t.takeTail());
  return out.toString();
}

void main() {
  for (final name in ['ru_commands', 'ru_mixed', 'en_plain']) {
    test('recorded session $name types the expected text exactly once', () {
      final expected =
          File('test/fixtures/deepgram_$name.expected.txt').readAsStringSync();
      expect(_typedFor(name), expected);
    });
  }

  test('English phrase is typed word for word', () {
    expect(
      _typedFor('en_plain'),
      'Open the browser and search for the weather tomorrow. '
      'Then send a message that the meeting moves to Friday.',
    );
  });

  test('no word is typed twice in a Russian session', () {
    final typed = _typedFor('ru_commands').toLowerCase();
    expect(RegExp(r'открой браузер').allMatches(typed).length, 1);
    expect(RegExp(r'потом напиши').allMatches(typed).length, 1);
  });
}
