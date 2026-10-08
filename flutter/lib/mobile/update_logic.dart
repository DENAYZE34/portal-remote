import 'package:crypto/crypto.dart';

/// Build number stamped into the release notes as "build N"; null if absent.
int? parseReleaseBuild(String? body) {
  final m = RegExp(r'build\s+(\d+)', caseSensitive: false).firstMatch(body ?? '');
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// SHA-256 of the APK stamped into the release notes as "sha256 <64 hex>".
String? parseReleaseSha(String? body) {
  final m = RegExp(r'sha256\s+([0-9a-fA-F]{64})', caseSensitive: false)
      .firstMatch(body ?? '');
  return m?.group(1)?.toLowerCase();
}

bool isNewerBuild(int? remote, int? local) =>
    remote != null && local != null && remote > local;

/// True only when [bytes] hash to exactly [expectedHex].
bool digestMatches(List<int> bytes, String? expectedHex) {
  if (expectedHex == null || expectedHex.length != 64) return false;
  return sha256.convert(bytes).toString() == expectedHex.toLowerCase();
}

/// Release suffix for the device CPU, from Dart's `Platform.version`
/// ("... on \"android_arm64\""). 64-bit ARM has no suffix.
String abiSuffix(String dartVersion) {
  if (dartVersion.contains('android_arm64')) return '';
  if (dartVersion.contains('android_arm')) return '-armv7';
  if (dartVersion.contains('android_x64')) return '-x86_64';
  return '';
}

/// "What is new" lines from the release notes: lines starting with "- ", at most [max].
List<String> parseReleaseNotes(String? body, {int max = 6}) {
  final out = <String>[];
  for (final line in (body ?? '').split('\n')) {
    final t = line.trim();
    if (t.startsWith('- ') && t.length > 2) {
      out.add(t.substring(2).trim());
      if (out.length >= max) break;
    }
  }
  return out;
}

/// Automatic checks run at most once per [every]; manual checks always run.
bool shouldCheckNow(DateTime? last, DateTime now,
    {Duration every = const Duration(hours: 6)}) {
  return last == null || now.difference(last) >= every;
}
