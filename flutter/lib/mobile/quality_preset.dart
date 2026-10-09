import 'package:flutter/material.dart';

/// One-tap quality presets, from fastest to sharpest. 'max' is the custom
/// profile (top bitrate, 60 FPS); the others are the built-in qualities.
const List<String> kQualityPresets = ['low', 'balanced', 'best', 'max'];

/// Custom profile used by 'max'.
// Host bitrate = base(1080p 2.07 Mbps) * quality*2/100, so 300 is about 12 Mbps at
// 1080p. The host lowers it by itself when the network delay grows.
const int kMaxPresetQuality = 300;
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

/// Parses the delay text of the quality monitor ("37"), null when unknown.
int? parseDelayMs(String? text) => int.tryParse((text ?? '').trim());

/// Picks the starting preset from what the link looks like. Direct links and
/// a relay with a short delay get the top profile; slow links start lower so
/// the picture stays smooth, and the owner's own choice always wins.
String smartStartPreset({required bool direct, int? delayMs}) {
  if (delayMs == null || delayMs <= 0) return 'max';
  if (direct) return delayMs > 200 ? 'best' : 'max';
  if (delayMs <= 90) return 'max';
  if (delayMs <= 160) return 'best';
  return 'balanced';
}
