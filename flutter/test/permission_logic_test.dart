import 'package:flutter_hbb/mobile/permission_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no status means everything is missing', () {
    expect(missingPermissions(permissionItems(null)), 4);
  });

  test('granted items are not counted', () {
    final items = permissionItems({
      'accessibility': true,
      'overlay': true,
      'battery': false,
      'notifications': true,
    });
    expect(missingPermissions(items), 1);
    expect(items.firstWhere((e) => !e.granted).key, 'battery');
  });

  test('all granted', () {
    final items = permissionItems({
      'accessibility': true, 'overlay': true, 'battery': true, 'notifications': true,
    });
    expect(missingPermissions(items), 0);
  });
}
