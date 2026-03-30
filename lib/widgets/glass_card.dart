import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// ── GlassCard — theme-aware glass/card widget ─────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? glowColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 28,
    this.glowColor,
    this.blur = 24,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        gradient: c.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.11),
                  Colors.white.withValues(alpha: 0.04),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.10)
              : c.border,
          width: 1,
        ),
        boxShadow: c.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );

    if (c.isDark) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: inner,
        ),
      );
    }

    if (glowColor != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: glowColor!.withValues(alpha: c.isDark ? 0.22 : 0.10),
              blurRadius: 42,
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
    this.pressedScale = 0.93,
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
      duration: const Duration(milliseconds: 120),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack);
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _ctrl.animateBack(0,
        duration: const Duration(milliseconds: 300),
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
