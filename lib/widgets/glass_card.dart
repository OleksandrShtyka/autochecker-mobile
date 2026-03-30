import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme.dart';

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
    this.radius = 24,
    this.glowColor,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.cardFill,
        gradient: c.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.03),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.cardBorder, width: 1),
        boxShadow: c.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
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
              color: glowColor!.withValues(alpha: c.isDark ? 0.20 : 0.12),
              blurRadius: 36,
              spreadRadius: -6,
            ),
          ],
        ),
        child: inner,
      );
    }
    return inner;
  }
}

// ── Spring Button — scales on press ──────────────────────────────────────────

class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.94,
    this.duration = const Duration(milliseconds: 130),
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
      duration: widget.duration,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _ctrl.reverse();

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
