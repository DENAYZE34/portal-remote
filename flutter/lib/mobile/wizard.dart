import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/models/platform_model.dart';

import '../common.dart';
import 'wizard_logic.dart';

/// Shows the 3-step guide once, on the first launch.
Future<void> showFirstRunWizardOnce(BuildContext context) async {
  if (!wizardNeeded(bind.mainGetLocalOption(key: kWizardDoneOption))) return;
  if (!context.mounted) return;
  await showFirstRunWizard(context);
  await bind.mainSetLocalOption(key: kWizardDoneOption, value: 'Y');
}

Future<void> showFirstRunWizard(BuildContext context) async {
  var i = 0;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final step = kWizardSteps[i];
        final last = i == kWizardSteps.length - 1;
        return AlertDialog(
          title: Text(step.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.body),
              if (i == 0)
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Скопировать ссылку'),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: kWizardReleasesUrl));
                    showToast('Ссылка скопирована');
                  },
                ),
              const SizedBox(height: 8),
              Text('Шаг ${i + 1} из ${kWizardSteps.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Пропустить')),
            FilledButton(
              onPressed: () {
                if (last) {
                  Navigator.pop(ctx);
                } else {
                  setState(() => i++);
                }
              },
              child: Text(last ? 'Готово' : 'Далее'),
            ),
          ],
        );
      },
    ),
  );
}
