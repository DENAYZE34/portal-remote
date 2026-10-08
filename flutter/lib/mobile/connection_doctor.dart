/// Turns technical connection errors into one plain Russian sentence with the fix.
/// Returns null when the message is not one we can explain (the original is shown).
String? diagnoseConnection(String title, String text) {
  final t = text.toLowerCase();
  bool has(String s) => t.contains(s);

  if (has('device not paired')) {
    return 'Это устройство не сопряжено с ПК. На ПК откройте PortalDesk → '
        'Настройки → Безопасность → «Открыть сопряжение на 5 минут» и '
        'подключитесь снова.';
  }
  if (has('too many') || has('blocked') || has('banned')) {
    return 'Слишком много неудачных попыток. Подождите несколько минут и '
        'введите пароль правильно.';
  }
  if (has('wrong password') || has('password is wrong')) {
    return 'Неверный пароль. Проверьте постоянный пароль на ПК: '
        'PortalDesk → Настройки → Безопасность.';
  }
  if (has('no password access')) {
    return 'На ПК запрещён вход по паролю. Подтвердите подключение на самом ПК '
        'или включите вход по паролю в Настройки → Безопасность.';
  }
  if (has('offline')) {
    return 'ПК выключен, спит или не в сети. Включите его и проверьте, что '
        'PortalDesk запущен и есть интернет.';
  }
  if (has('id does not exist') || has('not exist')) {
    return 'Такого ID нет. Проверьте цифры: ID виден в окне PortalDesk на ПК.';
  }
  if (has('key mismatch')) {
    return 'Ключ сервера не совпадает. Установите свежую версию PortalDesk '
        'на обоих устройствах.';
  }
  if (has('rendezvous') || has('failed to connect to') && has('server')) {
    return 'Нет связи с сервером PortalDesk. Проверьте интернет на телефоне '
        'и повторите через минуту.';
  }
  if (has('timed out') || has('timeout') || has('deadline has elapsed')) {
    return 'ПК или сервер не ответили вовремя. Проверьте интернет с обеих '
        'сторон и повторите.';
  }
  if (has('connection refused') || has('refused')) {
    return 'ПК отклонил подключение. Проверьте, что PortalDesk на ПК запущен '
        'и не заблокирован брандмауэром.';
  }
  if (has('reset by peer') || has('connection closed') ||
      has('forcibly closed') || has('broken pipe')) {
    return 'Связь оборвалась. Приложение переподключится само; если не '
        'получается, проверьте интернет.';
  }
  return null;
}
