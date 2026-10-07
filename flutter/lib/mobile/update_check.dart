import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String _kBuild = String.fromEnvironment('PORTAL_BUILD');
const String _kReleaseApi =
    'https://api.github.com/repos/DENAYZE34/portal-remote/releases/tags/android-latest';
const String _kApkUrl =
    'https://github.com/DENAYZE34/portal-remote/releases/download/android-latest/PortalDesk-android.apk';

/// Build number stamped into the release notes as "build N"; null if absent.
int? parseReleaseBuild(String? body) {
  final m = RegExp(r'build\s+(\d+)', caseSensitive: false).firstMatch(body ?? '');
  return m == null ? null : int.tryParse(m.group(1)!);
}

bool isNewerBuild(int? remote, int? local) =>
    remote != null && local != null && remote > local;

/// Asks GitHub for the latest Android release and offers the download when it
/// is newer than this build. Silent on every failure.
Future<void> checkForPortalUpdate(BuildContext context) async {
  final local = int.tryParse(_kBuild);
  if (local == null) return;
  try {
    final resp = await http
        .get(Uri.parse(_kReleaseApi),
            headers: {'Accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return;
    final body = (jsonDecode(resp.body) as Map<String, dynamic>)['body'];
    final remote = parseReleaseBuild(body is String ? body : null);
    if (!isNewerBuild(remote, local) || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Доступно обновление PortalDesk'),
        content: Text('Новая сборка $remote (у вас $local).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Позже')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse(_kApkUrl),
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('Скачать'),
          ),
        ],
      ),
    );
  } catch (_) {}
}
