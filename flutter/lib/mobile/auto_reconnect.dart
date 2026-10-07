/// Decides whether a dropped mobile session should reconnect by itself.
/// Gives up after [maxAttempts] drops inside [window] so a real problem
/// (wrong password, host gone) still reaches the normal error dialog.
class AutoReconnectPolicy {
  static const int maxAttempts = 6;
  static const Duration window = Duration(seconds: 90);

  // Errors where retrying cannot help or must not happen silently.
  static const List<String> _fatal = [
    'password',
    'offline',
    'key',
    'not exist',
    'refused',
    'blocked',
    'banned',
    'licen',
    'login',
    'authorized',
    'rejected',
    'denied',
    'version',
  ];

  int _attempts = 0;
  DateTime? _windowStart;

  bool isTransient(String title, String text) {
    if (title != 'Connection Error') return false;
    final t = text.toLowerCase();
    return !_fatal.any(t.contains);
  }

  /// Returns the delay before the next reconnect, or null to stop retrying.
  Duration? next(String title, String text, DateTime now) {
    if (!isTransient(title, text)) return null;
    final start = _windowStart;
    if (start == null || now.difference(start) > window) {
      _windowStart = now;
      _attempts = 0;
    }
    if (_attempts >= maxAttempts) return null;
    final secs = 1 << _attempts;
    _attempts++;
    return Duration(seconds: secs > 8 ? 8 : secs);
  }

  void reset() {
    _attempts = 0;
    _windowStart = null;
  }
}
