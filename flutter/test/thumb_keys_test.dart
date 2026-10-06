import 'dart:io';

import 'package:flutter_hbb/mobile/widgets/ring_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Names the key panel sends must exist in the PC-side key table.
  test('every panel and chord key is in the client KEY_MAP', () {
    final src = File('../src/client.rs').readAsStringSync();
    final names = RegExp(r'\("(VK_[A-Z0-9_]+)",')
        .allMatches(src)
        .map((m) => m.group(1))
        .toSet();
    for (final k in [...kPanelKeys, ...kChordKeys, ...kRingKeys]) {
      expect(names.contains(k), isTrue, reason: '$k missing from KEY_MAP');
    }
  });

  test('panel covers the requested keys', () {
    for (final k in [
      'VK_ESCAPE',
      'VK_TAB',
      'VK_BACK',
      'VK_DELETE',
      'VK_LEFT',
      'VK_UP',
      'VK_DOWN',
      'VK_RIGHT',
      'VK_F1',
      'VK_F12',
    ]) {
      expect(kPanelKeys, contains(k));
    }
    expect(kChordKeys, containsAll(['VK_C', 'VK_V', 'VK_X', 'VK_Z', 'VK_A']));
  });

  test('ring: empty or broken data gives the default', () {
    expect(parseRing(null), kRingDefault);
    expect(parseRing(''), kRingDefault);
    expect(parseRing('not json'), kRingDefault);
  });

  test('ring: "more" cannot be removed or replaced and is restored', () {
    expect(canRemove('more'), isFalse);
    expect(removeAction(kRingDefault, 'more'), kRingDefault);
    expect(replaceAction(kRingDefault, 'more', 'home'), kRingDefault);
    expect(parseRing(encodeRing(['copy', 'paste'])), ['copy', 'paste', 'more']);
  });

  test('ring: delete, replace and add are saved and restored', () {
    var ring = removeAction(kRingDefault, 'copy');
    expect(ring.contains('copy'), isFalse);
    ring = replaceAction(ring, 'paste', 'home');
    ring = addAction(ring, 'end');
    expect(ring, ['scrollup', 'scrolldown', 'rclick', 'home', 'enter', 'end', 'more']);
    expect(parseRing(encodeRing(ring)), ring);
  });

  test('ring: unknown, duplicate ids dropped and size capped', () {
    expect(parseRing('["copy","copy","bogus","more"]'), ['copy', 'more']);
    var ring = List.of(kRingDefault);
    for (final id in availableToAdd(ring)) {
      ring = addAction(ring, id);
    }
    expect(ring.length, kRingMax);
    expect(canAdd(ring), isFalse);
    expect(ring.contains('more'), isTrue);
  });
}
