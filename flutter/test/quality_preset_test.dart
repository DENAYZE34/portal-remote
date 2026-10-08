import 'package:flutter_hbb/mobile/quality_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presets cycle speed -> balance -> quality -> max -> speed', () {
    expect(nextQualityPreset('low'), 'balanced');
    expect(nextQualityPreset('balanced'), 'best');
    expect(nextQualityPreset('best'), 'max');
    expect(nextQualityPreset('custom'), 'low'); // custom is the max profile
  });

  test('unknown or empty quality is treated as max', () {
    expect(presetFromSession(null), 'max');
    expect(presetFromSession(''), 'max');
    expect(presetFromSession('custom'), 'max');
    expect(presetFromSession('low'), 'low');
  });

  test('max profile targets top quality and 60 FPS', () {
    expect(kMaxPresetFps, 60);
    expect(kMaxPresetQuality, 100);
  });

  test('every preset has a label and an icon', () {
    for (final p in kQualityPresets) {
      expect(qualityPresetLabel(p), isNotEmpty);
      expect(qualityPresetIcon(p), isNotNull);
    }
  });
}
