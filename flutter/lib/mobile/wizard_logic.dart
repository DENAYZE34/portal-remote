class WizardStep {
  final String title;
  final String body;
  const WizardStep(this.title, this.body);
}

/// First-run guide: three screens from nothing to the first remote picture.
const List<WizardStep> kWizardSteps = [
  WizardStep('1. Поставьте PortalDesk на ПК',
      'Скачайте установщик для Windows со страницы релизов и установите. '
          'Ссылка скопируется кнопкой ниже.'),
  WizardStep('2. Задайте пароль на ПК',
      'На ПК откройте PortalDesk → Настройки → Безопасность и задайте '
          'постоянный пароль. ID вашего ПК виден в главном окне.'),
  WizardStep('3. Подключитесь с телефона',
      'Введите ID ПК в верхнем поле на вкладке «Подключение» и пароль. '
          'Первая картинка появится через пару секунд.'),
];

const String kWizardReleasesUrl =
    'https://github.com/DENAYZE34/portal-remote/releases/latest';

const String kWizardDoneOption = 'portal-wizard';

bool wizardNeeded(String? savedOption) => savedOption != 'Y';
