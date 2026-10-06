import 'dart:convert';

/// Ids of the actions a ring button can have.
const List<String> kRingCatalog = [
  'scrollup',
  'scrolldown',
  'rclick',
  'copy',
  'paste',
  'enter',
  'home',
  'end',
  'more',
];

const List<String> kRingDefault = [
  'scrollup',
  'scrolldown',
  'rclick',
  'copy',
  'paste',
  'enter',
  'more',
];

/// "More" opens the key panel; without it the panel is unreachable.
const String kRingLocked = 'more';
const int kRingMax = 9;

/// Keys of the bottom panel, as sent to the PC (`sessionInputKey` names).
final List<String> kPanelKeys = [
  'VK_ESCAPE',
  'VK_TAB',
  'VK_BACK',
  'VK_DELETE',
  'VK_LEFT',
  'VK_UP',
  'VK_DOWN',
  'VK_RIGHT',
  for (var i = 1; i <= 12; i++) 'VK_F$i',
];

/// Keys reachable only from ring buttons (Enter, Home, End).
const List<String> kRingKeys = ['VK_RETURN', 'VK_HOME', 'VK_END'];

/// Letters used with Ctrl (Cmd on Mac) by the panel and the ring.
const List<String> kChordKeys = ['VK_C', 'VK_V', 'VK_X', 'VK_Z', 'VK_A'];

/// Decodes a saved ring; falls back to the default for empty or broken data.
/// Unknown and duplicate ids are dropped and "more" is always present.
List<String> parseRing(String? saved) {
  List<String> ids = kRingDefault;
  if (saved != null && saved.isNotEmpty) {
    try {
      final decoded = jsonDecode(saved);
      if (decoded is List) {
        ids = decoded.whereType<String>().toList();
      }
    } catch (_) {}
  }
  final out = <String>[];
  for (final id in ids) {
    if (kRingCatalog.contains(id) && !out.contains(id)) out.add(id);
  }
  if (out.length > kRingMax) out.removeRange(kRingMax, out.length);
  if (!out.contains(kRingLocked)) {
    if (out.length >= kRingMax) out.removeLast();
    out.add(kRingLocked);
  }
  return out;
}

String encodeRing(List<String> ids) => jsonEncode(ids);

bool canRemove(String id) => id != kRingLocked;

bool canAdd(List<String> ids) => ids.length < kRingMax;

/// Catalog entries not yet in the ring.
List<String> availableToAdd(List<String> ids) =>
    [for (final id in kRingCatalog) if (!ids.contains(id)) id];

List<String> removeAction(List<String> ids, String id) =>
    canRemove(id) ? [for (final x in ids) if (x != id) x] : List.of(ids);

/// Replaces [oldId] with [newId] in place; ignores ids already in the ring.
List<String> replaceAction(List<String> ids, String oldId, String newId) {
  if (oldId == kRingLocked || ids.contains(newId)) return List.of(ids);
  return [for (final x in ids) x == oldId ? newId : x];
}

/// Inserts [id] before the locked "more" button.
List<String> addAction(List<String> ids, String id) {
  if (!canAdd(ids) || ids.contains(id) || !kRingCatalog.contains(id)) {
    return List.of(ids);
  }
  final out = List.of(ids);
  final at = out.indexOf(kRingLocked);
  out.insert(at < 0 ? out.length : at, id);
  return out;
}
