import 'dart:math';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/health_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';

const _green = Color(0xFF34D399);
const _orange = Color(0xFFF97316);
const _red = Color(0xFFEF4444);

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => HealthScreenState();
}

class HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _initLoad();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    if (await HealthService.instance.hasPermissions) {
      await HealthService.instance.refresh();
      _ringCtrl.forward(from: 0);
    }
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final available = await HealthService.instance.isAvailable;
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('health_not_available'))),
          );
        }
        return;
      }
      final granted = await HealthService.instance.requestPermissions();
      if (granted) {
        await HealthService.instance.refresh();
        _ringCtrl.forward(from: 0);
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _refresh() async {
    _ringCtrl.reset();
    await HealthService.instance.refresh();
    _ringCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: ValueListenableBuilder<HealthSnapshot?>(
              valueListenable: HealthService.instance.snapshot,
              builder: (_, snap, __) => snap == null
                  ? _buildConnect()
                  : RefreshIndicator(
                      color: _green,
                      backgroundColor: surfaceColor,
                      onRefresh: _refresh,
                      child: _buildData(snap),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Not connected ──────────────────────────────────────────────────────────
  Widget _buildConnect() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), _green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Google Health',
              style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              t('health_connect_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _connecting ? null : _connect,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: _connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        t('health_connect'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data view ──────────────────────────────────────────────────────────────
  Widget _buildData(HealthSnapshot snap) {
    final stepsGoal = 10000;
    final stepsProgress = (snap.steps / stepsGoal).clamp(0.0, 1.0);
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.favorite_rounded, color: _green, size: 18),
            const SizedBox(width: 8),
            Text(
              'Google Health',
              style: const TextStyle(
                  color: _green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5),
            ),
            const Spacer(),
            Text(
              dateStr,
              style:
                  const TextStyle(color: textMuted, fontSize: 12),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _refresh,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: _green, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Step ring
        Center(
          child: AnimatedBuilder(
            animation: _ringAnim,
            builder: (_, __) => CustomPaint(
              painter: _RingPainter(
                progress: stepsProgress * _ringAnim.value,
                color: _green,
              ),
              child: SizedBox(
                width: 220,
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        snap.steps.toString().replaceAllMapped(
                              RegExp(r'(\d)(?=(\d{3})+$)'),
                              (m) => '${m[1]},',
                            ),
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t('health_steps'),
                        style:
                            const TextStyle(color: textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(stepsProgress * 100).round()}% of $stepsGoal',
                        style: const TextStyle(
                            color: _green, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Stat cards row
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.local_fire_department_rounded,
                value: snap.totalCalories > 0
                    ? '${snap.totalCalories.round()}'
                    : '${snap.activeCalories.round()}',
                label: t('health_kcal'),
                sub: t('health_calories'),
                color: _orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                icon: Icons.favorite_rounded,
                value: snap.heartRateAvg != null
                    ? '${snap.heartRateAvg!.round()}'
                    : '--',
                label: snap.heartRateAvg != null ? t('health_bpm') : '',
                sub: t('health_heart'),
                color: _red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Active calories card (full width)
        if (snap.totalCalories > 0 && snap.activeCalories > 0)
          _wideCard(
            icon: Icons.bolt_rounded,
            title: 'Active calories',
            value: '${snap.activeCalories.round()} kcal',
            subtitle: 'Burned through activity',
            color: const Color(0xFFFBBF24),
          ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required String sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(sub,
                  style:
                      const TextStyle(color: textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5),
          ),
          Text(
            label,
            style: const TextStyle(color: textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _wideCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style:
                      const TextStyle(color: textMuted, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeW = 14.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,       // start at top
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Glow effect
    if (progress > 0.01) {
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
