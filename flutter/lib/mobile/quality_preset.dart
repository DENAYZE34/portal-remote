import 'package:flutter/material.dart';

/// One-tap quality presets, from fastest to sharpest. 'max' is the custom
/// profile (top bitrate, 60 FPS); the others are the built-in qualities.
const List<String> kQualityPresets = ['low', 'balanced', 'best', 'max'];

/// Custom profile used by 'max'.
const int kMaxPresetQuality = 100;
const int kMaxPresetFps = 60;

/// Maps what the session reports ('custom' means our max profile) to a preset.
String presetFromSession(String? quality) {
  if (quality == 'custom') return 'max';
  return kQualityPresets.contains(quality) ? quality! : 'max';
}

String nextQualityPreset(String? current) {
  final i = kQualityPresets.indexOf(presetFromSession(current));
  return kQualityPresets[(i + 1) % kQualityPresets.length];
}

String qualityPresetLabel(String preset) {
  switch (preset) {
    case 'low':
      return 'Скорость';
    case 'balanced':
      return 'Баланс';
    case 'best':
      return 'Качество';
    default:
      return 'Максимум';
  }
}

IconData qualityPresetIcon(String preset) {
  switch (preset) {
    case 'low':
      return Icons.bolt;
    case 'balanced':
      return Icons.tune;
    case 'best':
      return Icons.hd;
    default:
      return Icons.rocket_launch;
  }
}
