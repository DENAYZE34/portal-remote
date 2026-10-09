import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// PortalDesk look on phones: the night-navy and violet-to-cyan glow of the
/// app icon. Desktop keeps the stock theme.
bool get kNeon =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class Neon {
  static const Color bg = Color(0xFF070A1F);
  static const Color bar = Color(0xFF0B1030);
  static const Color surface = Color(0xFF101635);
  static const Color surfaceHigh = Color(0xFF171E45);
  static const Color line = Color(0xFF262F66);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color text = Color(0xFFE8ECFF);
  static const Color muted = Color(0xFF8C95C4);

  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan],
  );

  static List<BoxShadow> glow([double strength = 0.35]) => [
        BoxShadow(
            color: cyan.withOpacity(strength * 0.5),
            blurRadius: 18,
            spreadRadius: -2),
        BoxShadow(
            color: violet.withOpacity(strength * 0.5),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(-4, 4)),
      ];
}

/// A rounded panel with a thin gradient edge, used for the main cards.
class NeonPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glow;
  const NeonPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.radius = 20,
      this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: Neon.gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow ? Neon.glow() : null,
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          color: Neon.surface,
          borderRadius: BorderRadius.circular(radius - 1),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
