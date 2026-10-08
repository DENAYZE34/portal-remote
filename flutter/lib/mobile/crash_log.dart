import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'crash_log_logic.dart';

Future<File> _file() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}/portal_crash.log');
}

Future<void> _record(String title, Object error, StackTrace? stack) async {
  try {
    final f = await _file();
    final old = await f.exists() ? await f.readAsString() : '';
    await f.writeAsString(appendCrashEntry(
        old, formatCrashEntry(DateTime.now(), '$title: $error', stack?.toString())));
  } catch (_) {}
}

/// Writes unhandled Flutter and async errors to a small local file so the
/// owner can copy it from Settings and send it. Nothing leaves the phone.
Future<void> installCrashLog() async {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    _record('Flutter error', details.exception, details.stack);
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _record('Unhandled', error, stack);
    return false;
  };
}

Future<String> readCrashLog() async {
  try {
    final f = await _file();
    return await f.exists() ? await f.readAsString() : '';
  } catch (_) {
    return '';
  }
}

Future<void> clearCrashLog() async {
  try {
    final f = await _file();
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
