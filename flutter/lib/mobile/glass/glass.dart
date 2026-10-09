import 'dart:ui';

import 'package:flutter/material.dart';

/// PortalDesk "glass" design system: frosted panels over a living violet and
/// cyan aurora. Pure Flutter, no app dependencies, so it can be previewed on
/// its own.
class Glass {
  static const Color base = Color(0xFF070A1F);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color text = Color(0xFFF2F4FF);
  static const Color soft = Color(0xFFC9CFEE);
  static const Color muted = Color(0xFF8C95C4);
  static const Color ok = Color(0xFF34D399);
  static const Color warn = Color(0xFFFBBF24);
  static const Color bad = Color(0xFFF87171);

  static Color fill([double a = 0.08]) => Colors.white.withOpacity(a);
  static Color edge([double a = 0.16]) => Colors.white.withOpacity(a);

  static const double rCard = 28;
  static const double rPill = 99;
}

/// Full-screen aurora background. Put it under everything.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    Widget blob(Alignment a, Color c, double o, double size) => Align(
          alignment: a,
          child: IgnorePointer(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [c.withOpacity(o), c.withOpacity(0)]),
              ),
            ),
          ),
        );
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: Glass.base)),
      blob(const Alignment(-0.9, -0.85), Glass.violet, 0.62, 640),
      blob(const Alignment(1.0, -0.15), Glass.cyan, 0.38, 560),
      blob(const Alignment(-0.4, 0.95), Glass.violet, 0.4, 680),
      Positioned.fill(child: child),
    ]);
  }
}

/// A frosted panel.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final double strength;
  final VoidCallback? onTap;
  const GlassCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.margin,
      this.radius = Glass.rCard,
      this.blur = 22,
      this.strength = 1,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget body = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Glass.fill(0.14 * strength),
                Glass.fill(0.05 * strength)
              ],
            ),
            border: Border.all(color: Glass.edge(0.18 * strength), width: 1),
          ),
          child: child,
        ),
      ),
    );
    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(
            borderRadius: r, onTap: onTap, child: body),
      );
    }
    return margin == null ? body : Padding(padding: margin!, child: body);
  }
}

/// The one loud button: white, soft violet glow.
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  const GlassButton(
      {super.key,
      required this.label,
      this.icon,
      this.onPressed,
      this.filled = true});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? const Color(0xFF0B1030) : Glass.text;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Glass.rPill),
        boxShadow: filled
            ? [
                BoxShadow(
                    color: Glass.violet.withOpacity(0.55),
                    blurRadius: 28,
                    offset: const Offset(0, 8))
              ]
            : null,
      ),
      child: Material(
        color: filled ? Colors.white : Glass.fill(0.12),
        shape: StadiumBorder(
            side: filled ? BorderSide.none : BorderSide(color: Glass.edge())),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8)
                ],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glowing status dot.
class StatusDot extends StatelessWidget {
  final Color color;
  final bool glow;
  const StatusDot({super.key, this.color = Glass.ok, this.glow = true});

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow:
              glow ? [BoxShadow(color: color.withOpacity(0.8), blurRadius: 10)] : null,
        ),
      );
}

class GlassNavItem {
  final String label;
  final IconData icon;
  const GlassNavItem(this.label, this.icon);
}

/// Floating pill navigation.
class GlassNavBar extends StatelessWidget {
  final List<GlassNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  const GlassNavBar(
      {super.key,
      required this.items,
      required this.index,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: GlassCard(
            radius: Glass.rPill,
            padding: const EdgeInsets.all(6),
            strength: 1.15,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavChip(
                      item: items[i],
                      selected: i == index,
                      onTap: () => onChanged(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavChip(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
            horizontal: selected ? 18 : 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(Glass.rPill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon,
              size: 22, color: selected ? Colors.white : Glass.soft),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: selected
                ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(item.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  )
                : const SizedBox.shrink(),
          ),
        ]),
      ),
    );
  }
}

/// Two or three way switch, for "Касание / Трекпад" and similar.
class GlassSegmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const GlassSegmented(
      {super.key,
      required this.labels,
      required this.index,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: Glass.rPill,
      padding: const EdgeInsets.all(4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < labels.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: i == index
                    ? Colors.white.withOpacity(0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Glass.rPill),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      color: i == index ? Colors.white : Glass.soft,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
      ]),
    );
  }
}

class GlassDockItem {
  final IconData icon;
  final String tip;
  final VoidCallback? onTap;
  final bool primary;
  const GlassDockItem(this.icon, this.tip, {this.onTap, this.primary = false});
}

/// Floating tool dock for the remote session.
class GlassDock extends StatelessWidget {
  final List<GlassDockItem> items;
  const GlassDock({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: Glass.rPill,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      strength: 1.2,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Tooltip(
              message: it.tip,
              child: GestureDetector(
                onTap: it.onTap,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: it.primary
                        ? Colors.white
                        : Colors.white.withOpacity(0.12),
                    boxShadow: it.primary
                        ? [
                            BoxShadow(
                                color: Glass.violet.withOpacity(0.6),
                                blurRadius: 16)
                          ]
                        : null,
                  ),
                  child: Icon(it.icon,
                      size: 21,
                      color: it.primary ? const Color(0xFF0B1030) : Colors.white),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
