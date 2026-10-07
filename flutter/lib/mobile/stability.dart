import 'package:flutter/material.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../common.dart';

const String _kSetupDoneKey = 'portal-stability-setup';

/// Keeps the connection alive while the app is in the background (Android).
Future<void> setSessionKeepAlive(bool on) async {
  if (!isAndroid) return;
  try {
    await gFFI.invokeMethod(on ? 'keep_alive_start' : 'keep_alive_stop');
  } catch (_) {}
}

/// One-time guide for the phone settings no app can change by itself.
Future<void> showStabilitySetupOnce(BuildContext context) async {
  if (!isAndroid) return;
  if (bind.mainGetLocalOption(key: _kSetupDoneKey) == 'Y') return;
  if (!context.mounted) return;
  await showStabilitySetup(context);
  await bind.mainSetLocalOption(key: _kSetupDoneKey, value: 'Y');
}

Future<void> showStabilitySetup(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Стабильное соединение'),
      content: const Text(
          'Чтобы телефон не обрывал связь в фоне, разрешите PortalDesk '
          'работать без ограничений батареи и включите автозапуск.'),
      actions: [
        TextButton(
          onPressed: () => gFFI.invokeMethod('open_battery_settings'),
          child: const Text('Батарея'),
        ),
        TextButton(
          onPressed: () => gFFI.invokeMethod('open_autostart'),
          child: const Text('Автозапуск'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Готово'),
        ),
      ],
    ),
  );
}
