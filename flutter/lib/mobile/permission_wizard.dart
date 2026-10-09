import 'package:flutter/material.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../common.dart';
import 'permission_logic.dart';

/// Checklist of the phone permissions needed to be controlled; refreshes when
/// the user comes back from the system settings.
class PermissionWizardPage extends StatefulWidget {
  const PermissionWizardPage({super.key});

  @override
  State<PermissionWizardPage> createState() => _PermissionWizardPageState();
}

class _PermissionWizardPageState extends State<PermissionWizardPage>
    with WidgetsBindingObserver {
  List<PermItem> _items = permissionItems(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    Map<dynamic, dynamic>? status;
    try {
      final r = await gFFI.invokeMethod('permission_status');
      if (r is Map) status = r;
    } catch (_) {}
    if (mounted) setState(() => _items = permissionItems(status));
  }

  Future<void> _fix(String key) async {
    switch (key) {
      case 'accessibility':
        await gFFI.invokeMethod(
            AndroidChannel.kStartAction, kActionAccessibilitySettings);
        break;
      case 'overlay':
        await gFFI.invokeMethod(AndroidChannel.kStartAction,
            'android.settings.action.MANAGE_OVERLAY_PERMISSION');
        break;
      case 'battery':
        await gFFI.invokeMethod('open_battery_settings');
        break;
      default:
        await gFFI.invokeMethod(
            AndroidChannel.kStartAction, kActionApplicationDetailsSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = missingPermissions(_items);
    return Scaffold(
      appBar: AppBar(title: const Text('Разрешения телефона')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(missing == 0 ? Icons.verified : Icons.info_outline,
                color: missing == 0 ? Colors.green : Colors.orange),
            title: Text(missing == 0
                ? 'Всё включено, телефоном можно управлять'
                : 'Не хватает: $missing'),
          ),
          for (final e in _items)
            ListTile(
              leading: Icon(e.granted ? Icons.check_circle : Icons.cancel,
                  color: e.granted ? Colors.green : Colors.red),
              title: Text(e.title),
              subtitle: Text(e.hint),
              trailing: e.granted
                  ? null
                  : FilledButton(
                      onPressed: () => _fix(e.key),
                      child: const Text('Включить')),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
                'Запись экрана система спросит сама при первом подключении.',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
