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
