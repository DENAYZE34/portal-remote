import 'dart:convert';

import 'package:flutter_hbb/mobile/voice/deepgram_transcript.dart';
import 'package:flutter_test/flutter_test.dart';

String _msg(String text,
    {bool isFinal = false, bool fromFinalize = false, String type = 'Results'}) {
  return jsonEncode({
    'type': type,
    'is_final': isFinal,
    if (fromFinalize) 'from_finalize': true,
    'channel': {
      'alternatives': [
        {'transcript': text}
      ]
    },
  });
}

void main() {
  test('interim then final builds the text', () {
    final t = DeepgramTranscript();
    expect(t.feed(_msg('привет')), isTrue);
    expect(t.composed, 'привет');
    t.feed(_msg('привет мир', isFinal: true));
    expect(t.composed, 'привет мир');
    expect(t.result, 'привет мир');
  });

  test('final segments are joined with one space, interim tail is shown', () {
    final t = DeepgramTranscript();
    t.feed(_msg('first part', isFinal: true));
    t.feed(_msg('second part', isFinal: true));
    t.feed(_msg('third'));
    expect(t.composed, 'first part second part third');
    expect(t.result, 'first part second part');
  });

  test('result falls back to interim when nothing is final', () {
    final t = DeepgramTranscript();
    t.feed(_msg('only interim'));
    expect(t.result, 'only interim');
  });

  test('empty final transcript adds nothing', () {
    final t = DeepgramTranscript();
    t.feed(_msg('hello', isFinal: true));
    t.feed(_msg('', isFinal: true));
    expect(t.result, 'hello');
  });

  test('from_finalize marks the transcript as flushed', () {
    final t = DeepgramTranscript();
    expect(t.flushed, isFalse);
    t.feed(_msg('done', isFinal: true, fromFinalize: true));
    expect(t.flushed, isTrue);
    t.reset();
    expect(t.flushed, isFalse);
    expect(t.result, '');
  });

  test('non-result, malformed and non-string messages are ignored', () {
    final t = DeepgramTranscript();
    expect(t.feed(_msg('x', type: 'Metadata')), isFalse);
    expect(t.feed('not json'), isFalse);
    expect(t.feed('[1,2]'), isFalse);
    expect(t.feed(42), isFalse);
    expect(t.feed(jsonEncode({'type': 'Results'})), isTrue);
    expect(t.result, '');
  });

  test('mixed Russian and English text is preserved', () {
    final t = DeepgramTranscript();
    t.feed(_msg('открой GitHub и Claude Code', isFinal: true));
    expect(t.result, 'открой GitHub и Claude Code');
  });
}
