import 'package:flutter_hbb/mobile/auto_reconnect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 7, 12);

  test('network drop retries with growing delay, capped at 8 seconds', () {
    final p = AutoReconnectPolicy();
    final delays = [
      for (var i = 0; i < 6; i++)
        p.next('Connection Error', 'Connection reset by peer', t0)!.inSeconds
    ];
    expect(delays, [1, 2, 4, 8, 8, 8]);
  });

  test('gives up after the attempt limit so the error dialog shows', () {
    final p = AutoReconnectPolicy();
    for (var i = 0; i < AutoReconnectPolicy.maxAttempts; i++) {
      expect(p.next('Connection Error', 'timed out', t0), isNotNull);
    }
    expect(p.next('Connection Error', 'timed out', t0), isNull);
  });

  test('attempts reset once the window has passed', () {
    final p = AutoReconnectPolicy();
    for (var i = 0; i < AutoReconnectPolicy.maxAttempts; i++) {
      p.next('Connection Error', 'timed out', t0);
    }
    final later = t0.add(AutoReconnectPolicy.window + const Duration(seconds: 1));
    expect(p.next('Connection Error', 'timed out', later)?.inSeconds, 1);
  });

  test('wrong password, offline and other fatal errors never auto-retry', () {
    final p = AutoReconnectPolicy();
    for (final text in [
      'Wrong Password',
      'Remote desktop is offline',
      'Key mismatch',
      'ID does not exist',
      'Connection refused',
    ]) {
      expect(p.next('Connection Error', text, t0), isNull, reason: text);
    }
  });

  test('other dialog titles are left alone', () {
    expect(AutoReconnectPolicy().next('Privacy mode', 'x', t0), isNull);
  });
}
