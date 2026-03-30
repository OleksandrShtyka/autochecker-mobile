import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/lock_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'lock_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final AudioPlayer _audio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _navigate();
    });
    _playLaunchSound();
  }

  Future<void> _playLaunchSound() async {
    try {
      await _audio.play(AssetSource('sounds/launch.wav'), volume: 0.6);
    } catch (_) {}
  }

  @override
  void dispose() {
    _audio.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final hasSession = await ApiService.instance.checkSession();
    final hasPin = hasSession && await LockService.instance.hasPin();
    if (hasSession) {
      SubscriptionService.instance.refresh();
    }
    if (!mounted) return;
    Widget dest;
    if (!hasSession) {
      dest = const LoginScreen();
    } else if (hasPin) {
      dest = const LockScreen(destination: HomeScreen());
    } else {
      dest = const HomeScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => dest,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final v = _ctrl.value;

          // Stage timing:
          // 0–30%: dots appear (staggered)
          // 30–60%: dots collapse, logo appears
          // 60–85%: text fades in
          // 85–100%: fade out

          final exitOpacity = v >= 0.85
              ? (1.0 - ((v - 0.85) / 0.15)).clamp(0.0, 1.0)
              : 1.0;

          // Logo scale — spring in during 30–60%
          final logoT = ((v - 0.30) / 0.30).clamp(0.0, 1.0);
          const logoSpring = ElasticOutCurve(0.6);
          final logoScale = logoT > 0 ? logoSpring.transform(logoT) : 0.0;
          final logoOpacity = (logoT * 3).clamp(0.0, 1.0);

          // Text fade — 60–85%
          final textT = ((v - 0.60) / 0.25).clamp(0.0, 1.0);
          final textOpacity = Curves.easeOut.transform(textT);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF08080F),
                      Color(0xFF0C0C1E),
                      Color(0xFF08080F),
                    ],
                  ),
                ),
              ),

              // Subtle glow blobs
              Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: teal.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blue.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Main content
              Opacity(
                opacity: exitOpacity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dots ring (0–30%) + collapsing (30–60%)
                      _DotsRing(animValue: v),

                      const SizedBox(height: 0),

                      // Logo — appears at 30–60%
                      if (logoT > 0)
                        Opacity(
                          opacity: logoOpacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: logoScale.clamp(0.0, 1.3),
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00E5CC),
                                    Color(0xFF4361EE),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: teal.withValues(alpha: 0.50),
                                    blurRadius: 40,
                                    spreadRadius: -4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 88),

                      const SizedBox(height: 40),

                      // Text — fades in at 60–85%
                      Opacity(
                        opacity: textOpacity,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                              ).createShader(b),
                              child: Text(
                                'GYM TRACKER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4.0 + (1.0 - textOpacity) * 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your personal fitness companion',
                              style: TextStyle(
                                color: textMuted.withValues(alpha: 0.8),
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Dots Ring — 8 staggered dots that appear then collapse ────────────────────
class _DotsRing extends StatelessWidget {
  final double animValue;

  const _DotsRing({required this.animValue});

  @override
  Widget build(BuildContext context) {
    const dotCount = 8;
    const ringRadius = 36.0;
    const dotSize = 6.0;

    // Dots phase: 0–30% appear, 30–60% collapse to center
    final dotsAppearT = (animValue / 0.30).clamp(0.0, 1.0);
    final dotsCollapseT = ((animValue - 0.30) / 0.30).clamp(0.0, 1.0);
    final currentRadius = ringRadius * (1.0 - dotsCollapseT);
    final dotsOpacity = (1.0 - dotsCollapseT).clamp(0.0, 1.0);

    return SizedBox(
      width: (ringRadius + dotSize) * 2 + 4,
      height: (ringRadius + dotSize) * 2 + 4,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(dotCount, (i) {
          final angle = (2 * pi / dotCount) * i - pi / 2;
          // Stagger: each dot appears with a delay proportional to its index
          final staggerDelay = i / dotCount * 0.6;
          final dotT = ((dotsAppearT - staggerDelay) / (1.0 - staggerDelay))
              .clamp(0.0, 1.0);
          final dotOpacity = (dotT * dotsOpacity).clamp(0.0, 1.0);

          final x = cos(angle) * currentRadius;
          final y = sin(angle) * currentRadius;

          // Color gradient around the ring
          final hue = (i / dotCount) * 60 + 168; // teal to blue range
          final color = HSLColor.fromAHSL(1.0, hue, 0.9, 0.55).toColor();

          return Transform.translate(
            offset: Offset(x, y),
            child: Opacity(
              opacity: dotOpacity,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
