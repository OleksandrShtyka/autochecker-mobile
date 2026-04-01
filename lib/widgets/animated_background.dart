import 'package:flutter/material.dart';

import '../theme.dart';

/// Clean static background gradient.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.isDark
              ? const [Color(0xFF08091A), Color(0xFF0E1225), Color(0xFF08091A)]
              : const [Color(0xFFF5F7FF), Color(0xFFEDF0FC), Color(0xFFF5F7FF)],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
