import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../common.dart';
import 'update_logic.dart';

export 'update_logic.dart';

const String _kBuild = String.fromEnvironment('PORTAL_BUILD');
const String _kReleaseApi =
    'https://api.github.com/repos/DENAYZE34/portal-remote/releases/tags/android-latest';
const String _kApkUrl =
    'https://github.com/DENAYZE34/portal-remote/releases/download/android-latest/PortalDesk-android.apk';

/// Asks GitHub for the latest Android release and offers an in-app update when
/// it is newer than this build. Silent on every failure.
Future<void> checkForPortalUpdate(BuildContext context) async {
  final local = int.tryParse(_kBuild);
  if (local == null || !isAndroid) return;
  try {
    final resp = await http
        .get(Uri.parse(_kReleaseApi),
            headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return;
    final body = (jsonDecode(resp.body) as Map<String, dynamic>)['body'];
    final text = body is String ? body : null;
    final remote = parseReleaseBuild(text);
    final sha = parseReleaseSha(text);
    if (!isNewerBuild(remote, local) || sha == null || !context.mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Доступно обновление PortalDesk'),
        content: Text('Новая сборка $remote (у вас $local). '
            'Загрузка и проверка пройдут внутри приложения.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Позже')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Обновить')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await _downloadAndInstall(context, sha);
    }
  } catch (_) {}
}

Future<void> _downloadAndInstall(BuildContext context, String sha) async {
  final progress = ValueNotifier<double?>(0);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Загрузка обновления'),
      content: ValueListenableBuilder<double?>(
        valueListenable: progress,
        builder: (_, v, __) => LinearProgressIndicator(value: v),
      ),
    ),
  );
  String? error;
  String? path;
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/PortalDesk-update.apk');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(_kApkUrl));
      final resp = await req.close().timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) throw HttpException('status ${resp.statusCode}');
      final total = resp.contentLength;
      var got = 0;
      final sink = file.openWrite();
      await for (final chunk in resp) {
        sink.add(chunk);
        got += chunk.length;
        progress.value = total > 0 ? got / total : null;
      }
      await sink.close();
    } finally {
      client.close(force: true);
    }
    if (!digestMatches(await file.readAsBytes(), sha)) {
      await file.delete();
      error = 'Файл обновления повреждён или подменён. Установка отменена.';
    } else {
      path = file.path;
    }
  } catch (e) {
    error = 'Не удалось загрузить обновление. Проверьте интернет.';
  }
  navigator.pop();
  progress.dispose();
  if (error != null) {
    showToast(error);
    return;
  }
  final res = await gFFI.invokeMethod('install_apk', path);
  if (res != true) {
    showToast('Разрешите установку для PortalDesk и нажмите «Обновить» снова.');
  }
}
