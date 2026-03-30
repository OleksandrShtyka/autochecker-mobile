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
      duration: const Duration(seconds: 14),
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
                        ? const [Color(0xFF060B14), Color(0xFF0A1628), Color(0xFF060B14)]
                        : const [Color(0xFFF5F7FF), Color(0xFFEFF4FF), Color(0xFFF2F5FF)],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Blob 1 — teal top-left
              _blob(
                left: w * 0.0 + sin(t * 0.6) * 35,
                top: h * 0.0 + cos(t * 0.45) * 45,
                size: 300,
                color: teal,
                opacity: isDark ? 0.22 : 0.15,
              ),
              // Blob 2 — blue bottom-right
              _blob(
                right: w * 0.0 + sin(t * 0.35 + 2.0) * 40,
                bottom: h * 0.08 + cos(t * 0.55 + 1.2) * 35,
                size: 320,
                color: blue,
                opacity: isDark ? 0.18 : 0.12,
              ),
              // Blob 3 — purple center
              _blob(
                left: w * 0.2 + sin(t * 0.28 + 4.1) * 55,
                top: h * 0.38 + cos(t * 0.72 + 3.0) * 40,
                size: 240,
                color: const Color(0xFF7C3AED),
                opacity: isDark ? 0.13 : 0.07,
              ),
              // Blob 4 — teal bottom-left
              _blob(
                left: w * 0.0 + sin(t * 0.52 + 1.5) * 25,
                bottom: h * 0.05 + cos(t * 0.38 + 2.7) * 30,
                size: 200,
                color: teal,
                opacity: isDark ? 0.10 : 0.08,
              ),
              // Blob 5 — rose top-right
              _blob(
                right: w * 0.05 + sin(t * 0.44 + 3.5) * 30,
                top: h * 0.10 + cos(t * 0.62 + 0.8) * 25,
                size: 180,
                color: const Color(0xFFE11D48),
                opacity: isDark ? 0.07 : 0.05,
              ),

              // Subtle grain overlay (dark only)
              if (isDark)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
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
              color.withValues(alpha: opacity * 0.5),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
