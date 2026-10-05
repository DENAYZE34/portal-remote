import 'dart:convert';

import 'package:flutter_hbb/mobile/voice/cert_pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const abcHash =
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
  final abc = utf8.encode('abc');

  test('fingerprint is lowercase sha256 hex', () {
    expect(certFingerprint(abc), abcHash);
  });

  test('matches ignores case and colon separators', () {
    final colon = RegExp('.{2}')
        .allMatches(abcHash.toUpperCase())
        .map((m) => m.group(0))
        .join(':');
    expect(certMatches(abc, abcHash), isTrue);
    expect(certMatches(abc, abcHash.toUpperCase()), isTrue);
    expect(certMatches(abc, colon), isTrue);
  });

  test('wrong or empty expected fingerprint does not match', () {
    expect(certMatches(abc, '00' * 32), isFalse);
    expect(certMatches(abc, ''), isFalse);
    expect(certMatches(utf8.encode('abd'), abcHash), isFalse);
  });
}
