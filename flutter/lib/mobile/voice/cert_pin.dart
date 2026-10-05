import 'package:crypto/crypto.dart';

/// Lowercase hex SHA-256 of a DER certificate.
String certFingerprint(List<int> der) => sha256.convert(der).toString();

/// True when [der] matches [expected] (hex, any case, optional ':' separators).
bool certMatches(List<int> der, String expected) {
  final want = expected.replaceAll(':', '').trim().toLowerCase();
  if (want.isEmpty) return false;
  return certFingerprint(der) == want;
}
