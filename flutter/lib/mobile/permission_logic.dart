class PermItem {
  final String key;
  final String title;
  final String hint;
  final bool granted;
  const PermItem(this.key, this.title, this.hint, this.granted);
}

/// Turns the native status map into the rows of the permission checklist.
List<PermItem> permissionItems(Map<dynamic, dynamic>? status) {
  bool ok(String k) => status?[k] == true;
  return [
    PermItem('accessibility', 'Управление с другого устройства',
        'Специальные возможности → PortalDesk → включить', ok('accessibility')),
    PermItem('overlay', 'Поверх других окон',
        'Нужно, чтобы показывать подсказки и курсор', ok('overlay')),
    PermItem('battery', 'Работа в фоне без ограничений',
        'Батарея → «Без ограничений», иначе связь обрывается', ok('battery')),
    PermItem('notifications', 'Уведомления',
        'Показывает, что телефон сейчас открыт для управления',
        ok('notifications')),
  ];
}

int missingPermissions(List<PermItem> items) =>
    items.where((e) => !e.granted).length;
