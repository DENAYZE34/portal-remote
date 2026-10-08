/// Keeps the crash log small: appends [entry] and drops the oldest text when the
/// file would exceed [maxChars].
String appendCrashEntry(String existing, String entry, {int maxChars = 120000}) {
  final all = existing.isEmpty ? entry : '$existing\n$entry';
  if (all.length <= maxChars) return all;
  final cut = all.substring(all.length - maxChars);
  final nl = cut.indexOf('\n');
  return nl >= 0 ? cut.substring(nl + 1) : cut;
}

/// One log record: time, short title and the stack (trimmed).
String formatCrashEntry(DateTime when, String title, String? stack) {
  final s = (stack ?? '').trim();
  final lines = s.isEmpty ? <String>[] : s.split('\n').take(12).toList();
  return '[${when.toIso8601String()}] $title${lines.isEmpty ? '' : '\n${lines.join('\n')}'}';
}
