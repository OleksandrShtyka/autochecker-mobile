import 'package:flutter/material.dart';

import '../theme.dart';

/// Calz-style clean static background — warm gradient, no blobs.
class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: c.isDark
              ? const [Color(0xFF1C1917), Color(0xFF232018), Color(0xFF1C1917)]
              : const [Color(0xFFFBF9F7), Color(0xFFF5F0EA), Color(0xFFFBF9F7)],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
