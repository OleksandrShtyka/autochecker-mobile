import 'dart:async';
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

  // Bar: scales in horizontally
  late Animation<double> _barScale;
  // Plates: slide in from both sides
  late Animation<double> _plateSlide;
  // Collars snap in
  late Animation<double> _collarScale;
  // Lift upward
  late Animation<double> _liftY;
  // Title + tagline fade
  late Animation<double> _titleFade;
  // Exit fade out
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _barScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOutBack),
    );
    _plateSlide = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    _collarScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.50, 0.62, curve: Curves.elasticOut),
    );
    _liftY = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.60, 0.82, curve: Curves.easeInOut),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.70, 0.88, curve: Curves.easeOut),
    );
    _exitFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.93, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward();
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _navigate();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final hasSession = await ApiService.instance.checkSession();
    final hasPin = hasSession && await LockService.instance.hasPin();
    if (hasSession) {
      // Load subscription status in background — don't block navigation
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
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // Lift: goes up 72px then returns to 0
          final lv = _liftY.value;
          final liftOffset = lv < 0.5
              ? -(lv * 2) * 72  // going up
              : -(1 - (lv - 0.5) * 2) * 72; // coming back down

          final exitOpacity = (1 - _exitFade.value).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF060F1A), Color(0xFF0D1B2A), Color(0xFF060F1A)],
                  ),
                ),
              ),
              // Subtle glow blobs
              Positioned(
                top: -100,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
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
                  width: 250,
                  height: 250,
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
                      // Barbell
                      Transform.translate(
                        offset: Offset(0, liftOffset),
                        child: _buildBarbell(),
                      ),
                      const SizedBox(height: 52),
                      // Title
                      FadeTransition(
                        opacity: _titleFade,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xFF0A7B72), teal, blue],
                              ).createShader(b),
                              child: const Text(
                                'GYM TRACKER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
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

  Widget _buildBarbell() {
    return SizedBox(
      width: 280,
      height: 80,
      child: CustomPaint(
        painter: _BarbellPainter(
          barScale: _barScale.value,
          plateSlide: _plateSlide.value,
          collarScale: _collarScale.value,
        ),
      ),
    );
  }
}

// ── Barbell CustomPainter ─────────────────────────────────────────────────────

class _BarbellPainter extends CustomPainter {
  final double barScale;
  final double plateSlide;
  final double collarScale;

  _BarbellPainter({
    required this.barScale,
    required this.plateSlide,
    required this.collarScale,
  });

  static const _barColor = Color(0xFFCBD5E1);   // silver bar
  static const _plate1Color = Color(0xFF0D9488); // teal large plate
  static const _plate2Color = Color(0xFF1B5BA0); // blue medium plate
  static const _plate3Color = Color(0xFF475569); // gray small plate
  static const _collarColor = Color(0xFF94A3B8);  // silver collar

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // ── Dimensions ──────────────────────────────────────────────────────────
    const barH = 12.0;
    final barHalfW = 130.0 * barScale;

    // Plate distances from center of bar (left side, negative = left)
    const p1W = 18.0; // large plate width
    const p1H = 62.0;
    const p2W = 13.0;
    const p2H = 50.0;
    const p3W = 9.0;
    const p3H = 38.0;
    const colW = 10.0;
    const colH = 28.0;
    const gap = 2.0;

    // Plate x-positions (distance from bar center, positive = outward)
    // They start at the bar center and slide to their final positions
    final p3Start = barHalfW - 20; // near bar end
    final p3End = barHalfW - p3W / 2 - gap;
    final p2End = p3End - p3W / 2 - gap - p2W / 2;
    final p1End = p2End - p2W / 2 - gap - p1W / 2;
    final colEnd = p1End - p1W / 2 - gap - colW / 2;

    double lerp(double a, double b, double t) => a + (b - a) * t;
    final p1X = lerp(p3Start, p1End, plateSlide);
    final p2X = lerp(p3Start, p2End, plateSlide);
    final p3X = lerp(p3Start, p3End, plateSlide);
    final colX = lerp(p3Start, colEnd, plateSlide) * collarScale;

    // ── Paint helpers ────────────────────────────────────────────────────────
    final barPaint = Paint()
      ..color = _barColor
      ..style = PaintingStyle.fill;

    void drawPlate(double xOff, double w, double h, Color color) {
      final paint = Paint()..color = color;
      final rect = Rect.fromCenter(
          center: Offset(cx + xOff, cy), width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      // Highlight
      final hl = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 2, rect.top + 2, w - 4, 4),
          const Radius.circular(2),
        ),
        hl,
      );
    }

    // Draw left plates (mirrored)
    drawPlate(-p1X, p1W, p1H, _plate1Color);
    drawPlate(-p2X, p2W, p2H, _plate2Color);
    drawPlate(-p3X, p3W, p3H, _plate3Color);
    // Draw right plates
    drawPlate(p3X, p3W, p3H, _plate3Color);
    drawPlate(p2X, p2W, p2H, _plate2Color);
    drawPlate(p1X, p1W, p1H, _plate1Color);

    // ── Bar ──────────────────────────────────────────────────────────────────
    final barRect = Rect.fromCenter(
        center: Offset(cx, cy), width: barHalfW * 2, height: barH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
      barPaint,
    );
    // Bar highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barRect.left + 8, barRect.top + 2, barRect.width - 16, 3),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // ── Collars ───────────────────────────────────────────────────────────────
    if (collarScale > 0) {
      final colPaint = Paint()..color = _collarColor;
      for (final side in [-1.0, 1.0]) {
        final cx2 = cx + side * colX;
        final rect = Rect.fromCenter(
            center: Offset(cx2, cy), width: colW, height: colH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          colPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarbellPainter old) =>
      old.barScale != barScale ||
      old.plateSlide != plateSlide ||
      old.collarScale != collarScale;
}
