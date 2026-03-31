import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// ── GlassCard — Calz-style clean white card ───────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? glowColor;
  // blur param kept for API compat but not used
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.glowColor,
    this.blur = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.cardFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (glowColor != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: glowColor!.withValues(alpha: c.isDark ? 0.20 : 0.12),
              blurRadius: 32,
              spreadRadius: -8,
            ),
          ],
        ),
        child: inner,
      );
    }
    return inner;
  }
}

// ── SpringButton — scale on press with spring return ─────────────────────────
class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.animateBack(0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _ctrl.animateBack(0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}
