import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../common.dart';
import 'update_logic.dart';

export 'update_logic.dart';

const String _kBuild = String.fromEnvironment('PORTAL_BUILD');
// 64-bit ARM phones use android-latest; 32-bit ARM and x86_64 have their own releases.
final String _kAbi = abiSuffix(Platform.version);
final String _kReleaseApi =
    'https://api.github.com/repos/DENAYZE34/portal-remote/releases/tags/${isIOS ? 'ios' : 'android$_kAbi'}-latest';
final String _kApkUrl =
    'https://github.com/DENAYZE34/portal-remote/releases/download/android$_kAbi-latest/PortalDesk-android$_kAbi.apk';

/// Newest build seen on GitHub (null until the first successful check); the
/// Settings tile shows it.
final ValueNotifier<int?> portalLatestBuild = ValueNotifier<int?>(null);

int? _iosBuild;

/// This build number: a build flag on Android, the app build number on iOS.
int? get portalCurrentBuild => _iosBuild ?? int.tryParse(_kBuild);

/// Call once at start; reads the iOS build number.
Future<void> initPortalBuild() async {
  if (!isIOS) return;
  try {
    _iosBuild = int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
  } catch (_) {}
}

const String _kIosSource =
    'https://github.com/DENAYZE34/portal-remote/releases/download/ios-latest/apps.json';

DateTime? _lastCheck;

class PortalUpdate {
  final int build;
  final String sha;
  final List<String> notes;
  const PortalUpdate(this.build, this.sha, this.notes);
}

/// Reads the latest release. Returns the update only when it is newer than
/// this build; null otherwise or on any failure ([failed] tells which).
Future<PortalUpdate?> _fetch(void Function() failed) async {
  final local = portalCurrentBuild;
  if (local == null) return null;
  try {
    final resp = await http
        .get(Uri.parse(_kReleaseApi),
            headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) {
      failed();
      return null;
    }
    final body = (jsonDecode(resp.body) as Map<String, dynamic>)['body'];
    final text = body is String ? body : null;
    final remote = parseReleaseBuild(text);
    final sha = parseReleaseSha(text);
    if (remote != null) portalLatestBuild.value = remote;
    if (remote == null || (!isIOS && sha == null) || !isNewerBuild(remote, local)) {
      return null;
    }
    return PortalUpdate(remote, sha ?? '', parseReleaseNotes(text));
  } catch (_) {
    failed();
    return null;
  }
}

/// Offers an in-app update when GitHub has a newer build. Automatic checks run
/// at most every 6 hours; [manual] checks always run and always answer.
Future<void> checkForPortalUpdate(BuildContext context,
    {bool manual = false}) async {
  if (!(isAndroid || isIOS)) return;
  await initPortalBuild();
  final local = portalCurrentBuild;
  if (local == null) {
    if (manual) showToast('Версия сборки неизвестна');
    return;
  }
  if (!manual && !shouldCheckNow(_lastCheck, DateTime.now())) return;
  _lastCheck = DateTime.now();
  var failed = false;
  final update = await _fetch(() => failed = true);
  if (!context.mounted) return;
  if (update == null) {
    if (manual) {
      showToast(failed
          ? 'Не удалось проверить обновления. Проверьте интернет.'
          : 'У вас последняя версия (сборка $local)');
    }
    return;
  }
  if (isIOS) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Доступно обновление PortalDesk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Новая сборка ${update.build} (у вас $local). '
                'Откройте SideStore, вкладка «Мои приложения», PortalDesk, «Обновить». '
                'Настройки, ID и пароль сохранятся.'),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Что нового:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              for (final n in update.notes) Text('• $n'),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: _kIosSource));
                showToast('Адрес источника SideStore скопирован');
              },
              child: const Text('Скопировать источник')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Понятно')),
        ],
      ),
    );
    return;
  }
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Доступно обновление PortalDesk'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Новая сборка ${update.build} (у вас $local). '
              'Настройки, ID и пароль сохранятся.'),
          if (update.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Что нового:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            for (final n in update.notes) Text('• $n'),
          ],
        ],
      ),
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
    await _downloadAndInstall(context, update.sha);
  }
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
  await _install(path!);
}

/// Hands the verified file to the system installer. When Android has not yet
/// allowed this app to install packages, the settings page opens and the
/// install is retried automatically when the user comes back.
Future<void> _install(String path) async {
  final res = await gFFI.invokeMethod('install_apk', path);
  if (res == true) return;
  showToast('Включите «Установка неизвестных приложений» для PortalDesk и '
      'вернитесь: обновление продолжится само.');
  WidgetsBinding.instance.addObserver(_ResumeOnce(() async {
    final again = await gFFI.invokeMethod('install_apk', path);
    if (again != true) {
      showToast('Разрешение не включено. Нажмите «Проверить обновления» снова.');
    }
  }));
}

/// Runs [action] the first time the app returns to the foreground.
class _ResumeOnce with WidgetsBindingObserver {
  final Future<void> Function() action;
  _ResumeOnce(this.action);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.removeObserver(this);
      action();
    }
  }
}
