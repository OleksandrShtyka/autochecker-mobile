import 'dart:ui';
import 'package:flutter/material.dart';

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
    this.radius = 20,
    this.glowColor,
    this.blur = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );

    inner = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: inner,
      ),
    );

    if (glowColor != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.18),
              blurRadius: 30,
              spreadRadius: -4,
            ),
          ],
        ),
        child: inner,
      );
    }
    return inner;
  }
}
