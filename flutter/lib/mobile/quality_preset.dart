import 'package:flutter/material.dart';


/// One-tap quality presets, from fastest to sharpest.
const List<String> kQualityPresets = ['low', 'balanced', 'best'];

String nextQualityPreset(String? current) {
  final i = kQualityPresets.indexOf(current ?? '');
  // Unknown values (custom, empty) jump to the sharpest preset.
  return i < 0 ? 'best' : kQualityPresets[(i + 1) % kQualityPresets.length];
}

String qualityPresetLabel(String preset) {
  switch (preset) {
    case 'low':
      return 'Скорость';
    case 'balanced':
      return 'Баланс';
    default:
      return 'Качество';
  }
}

IconData qualityPresetIcon(String preset) {
  switch (preset) {
    case 'low':
      return Icons.bolt;
    case 'balanced':
      return Icons.tune;
    default:
      return Icons.hd;
  }
}
