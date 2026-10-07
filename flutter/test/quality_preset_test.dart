import 'package:flutter_hbb/mobile/quality_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presets cycle speed -> balance -> quality -> speed', () {
    expect(nextQualityPreset('low'), 'balanced');
    expect(nextQualityPreset('balanced'), 'best');
    expect(nextQualityPreset('best'), 'low');
  });

  test('custom or unknown quality jumps to the sharpest preset', () {
    expect(nextQualityPreset('custom'), 'best');
    expect(nextQualityPreset(''), 'best');
    expect(nextQualityPreset(null), 'best');
  });

  test('every preset has a label and an icon', () {
    for (final p in kQualityPresets) {
      expect(qualityPresetLabel(p), isNotEmpty);
      expect(qualityPresetIcon(p), isNotNull);
    }
  });
}
