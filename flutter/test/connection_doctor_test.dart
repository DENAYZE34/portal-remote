import 'package:flutter_hbb/mobile/connection_doctor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each known failure gets a plain Russian explanation with the fix', () {
    final cases = {
      'Device not paired': 'сопряжено',
      'Wrong Password': 'пароль',
      'No Password Access': 'вход по паролю',
      'Remote desktop is offline': 'выключен',
      'ID does not exist': 'ID',
      'Key mismatch': 'Ключ',
      'Failed to connect to rendezvous server': 'сервером',
      'Connection timed out': 'вовремя',
      'deadline has elapsed': 'вовремя',
      'Connection refused (os error 10061)': 'брандмауэр',
      'Connection reset by peer': 'оборвалась',
      'Too many wrong password attempts': 'Подождите',
    };
    cases.forEach((raw, word) {
      final d = diagnoseConnection('Connection Error', raw);
      expect(d, isNotNull, reason: raw);
      expect(d, contains(word), reason: raw);
    });
  });

  test('unknown errors are left alone', () {
    expect(diagnoseConnection('Connection Error', 'Something weird'), isNull);
    expect(diagnoseConnection('', ''), isNull);
  });

  test('the not-paired message wins over the wrong-password wording', () {
    final d = diagnoseConnection('Login Error', 'Device not paired');
    expect(d, contains('сопряжение'));
  });
}
