import 'dart:math';
import 'dart:ui';
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
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = c.isDark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value * 2 * pi;
          final size = MediaQuery.of(context).size;
          final w = size.width;
          final h = size.height;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Base background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF08080F),
                            Color(0xFF0C0C1A),
                            Color(0xFF08080F),
                          ]
                        : const [
                            Color(0xFFF7F7FF),
                            Color(0xFFF0F0FF),
                            Color(0xFFF7F7FF),
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Blob 1 — teal top-left
              _blob(
                left: w * 0.0 + sin(t * 0.55) * 40,
                top: h * 0.0 + cos(t * 0.42) * 50,
                size: 320,
                color: teal,
                opacity: isDark ? 0.28 : 0.14,
              ),
              // Blob 2 — blue bottom-right
              _blob(
                right: w * 0.0 + sin(t * 0.32 + 2.0) * 45,
                bottom: h * 0.06 + cos(t * 0.50 + 1.2) * 40,
                size: 340,
                color: blue,
                opacity: isDark ? 0.22 : 0.11,
              ),
              // Blob 3 — purple center-left
              _blob(
                left: w * 0.15 + sin(t * 0.25 + 4.1) * 60,
                top: h * 0.35 + cos(t * 0.68 + 3.0) * 45,
                size: 260,
                color: accentPurple,
                opacity: isDark ? 0.16 : 0.08,
              ),
              // Blob 4 — teal bottom-left
              _blob(
                left: w * 0.0 + sin(t * 0.48 + 1.5) * 28,
                bottom: h * 0.04 + cos(t * 0.35 + 2.7) * 35,
                size: 220,
                color: teal,
                opacity: isDark ? 0.12 : 0.09,
              ),
              // Blob 5 — rose top-right
              _blob(
                right: w * 0.04 + sin(t * 0.40 + 3.5) * 32,
                top: h * 0.08 + cos(t * 0.58 + 0.8) * 28,
                size: 200,
                color: const Color(0xFFE11D48),
                opacity: isDark ? 0.09 : 0.05,
              ),
              // Blob 6 — blue center-right
              _blob(
                right: w * 0.0 + sin(t * 0.62 + 5.2) * 35,
                top: h * 0.42 + cos(t * 0.44 + 1.9) * 55,
                size: 190,
                color: blue,
                opacity: isDark ? 0.10 : 0.06,
              ),

              // Subtle gradient vignette (dark only)
              if (isDark)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
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
              color.withValues(alpha: opacity * 0.45),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }
}
