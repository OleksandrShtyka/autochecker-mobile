import 'dart:math';
import 'package:flutter/material.dart';

import '../theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 2 * pi;
          final size = MediaQuery.of(context).size;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Deep navy-black background
              Container(color: bgColor),
              // Blob 1 — teal
              _blob(
                left: size.width * 0.05 + sin(t * 0.7) * 30,
                top: size.height * 0.02 + cos(t * 0.5) * 40,
                size: 250,
                color: teal,
                opacity: 0.20,
              ),
              // Blob 2 — blue
              _blob(
                right: size.width * 0.02 + sin(t * 0.4 + 2.1) * 35,
                bottom: size.height * 0.12 + cos(t * 0.6 + 1.3) * 30,
                size: 280,
                color: blue,
                opacity: 0.16,
              ),
              // Blob 3 — purple
              _blob(
                left: size.width * 0.25 + sin(t * 0.3 + 4.2) * 50,
                top: size.height * 0.40 + cos(t * 0.8 + 3.1) * 35,
                size: 220,
                color: const Color(0xFF7C3AED),
                opacity: 0.12,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blob({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
