import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/achievements_service.dart';
import '../services/api_service.dart';
import '../services/exp_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

class CvWorkoutScreen extends StatefulWidget {
  const CvWorkoutScreen({super.key});

  @override
  State<CvWorkoutScreen> createState() => _CvWorkoutScreenState();
}

class _CvWorkoutScreenState extends State<CvWorkoutScreen>
    with TickerProviderStateMixin {
  CameraController? _cam;
  List<CameraDescription> _cameras = [];
  bool _camReady = false;
  bool _analyzing = false;
  String? _feedback;
  double? _score;
  String _selectedExercise = 'Squat';
  bool _hasError = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _resultCtrl;
  late Animation<double> _resultSlide;

  static const _exercises = [
    'Squat', 'Deadlift', 'Bench Press', 'Pull-up',
    'Push-up', 'Overhead Press', 'Lunge', 'Plank',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _hasError = true);
        return;
      }
      // Предпочитаем фронтальную камеру для selfie-анализа
      final cam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _cam = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    _pulseCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (_analyzing || _cam == null || !_camReady) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _analyzing = true;
      _feedback = null;
      _score = null;
    });
    _pulseCtrl.repeat(reverse: true);

    try {
      final xfile = await _cam!.takePicture();
      final bytes = await xfile.readAsBytes();

      final result = await ApiService.instance.analyzeTechnique(
        bytes,
        'image/jpeg',
        _selectedExercise,
      );

      final feedback = result['feedback'] as String? ?? 'Technique looks good!';
      final score = (result['score'] as num?)?.toDouble() ?? 7.5;

      if (mounted) {
        setState(() {
          _feedback = feedback;
          _score = score;
          _analyzing = false;
        });
        _pulseCtrl.stop();
        _resultCtrl.forward(from: 0);
        await ExpService.instance.earn(ExpReward.cvAnalysis);
        await AchievementsService.instance.onCvAnalysisUsed();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedback = 'Could not analyze. Check connection and try again.';
          _analyzing = false;
        });
        _pulseCtrl.stop();
        _resultCtrl.forward(from: 0);
      }
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    final current = _cam!.description;
    final next = _cameras.firstWhere((c) => c != current, orElse: () => _cameras.first);
    await _cam?.dispose();
    _cam = CameraController(next, ResolutionPreset.medium, enableAudio: false);
    await _cam!.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(c),
                _buildExercisePicker(c),
                Expanded(child: _buildCameraArea(c)),
                _buildAnalyzeButton(c),
                if (_feedback != null) _buildFeedbackCard(c),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios_rounded, color: c.text, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Form Analyzer',
                  style: TextStyle(
                      color: c.text, fontSize: 18, fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              Text('AI technique feedback',
                  style: TextStyle(color: c.muted, fontSize: 12)),
            ],
          ),
          const Spacer(),
          if (_cameras.length > 1)
            GestureDetector(
              onTap: _switchCamera,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flip_camera_ios_rounded,
                    color: teal, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExercisePicker(AppColors c) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _exercises.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final ex = _exercises[i];
          final selected = ex == _selectedExercise;
          return GestureDetector(
            onTap: () => setState(() => _selectedExercise = ex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF00E5CC), Color(0xFF4361EE)])
                    : null,
                color: selected
                    ? null
                    : (c.isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : c.border,
                ),
              ),
              child: Text(
                ex,
                style: TextStyle(
                  color: selected ? Colors.white : c.muted,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraArea(AppColors c) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, color: c.muted, size: 48),
            const SizedBox(height: 12),
            Text('Camera unavailable',
                style: TextStyle(color: c.muted, fontSize: 15)),
          ],
        ),
      );
    }
    if (!_camReady) {
      return const Center(
          child: CircularProgressIndicator(color: teal, strokeWidth: 2));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cam!),
            // Рамка-оверлей
            _buildPoseOverlay(c),
            // Analyzing indicator
            if (_analyzing)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) => Transform.scale(
                      scale: _pulse.value,
                      child: child,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: teal.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.psychology_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text('Analyzing form…',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoseOverlay(AppColors c) {
    return CustomPaint(
      painter: _FramePainter(color: teal),
    );
  }

  Widget _buildAnalyzeButton(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SpringButton(
        onTap: _analyzing ? null : _analyze,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: teal.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _analyzing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Analyze Form',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(AppColors c) {
    final score = _score ?? 0;
    final scoreColor = score >= 8
        ? const Color(0xFF22C55E)
        : score >= 6
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _resultCtrl,
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(16),
            glowColor: scoreColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.15),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                          color: scoreColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedExercise,
                        style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _feedback ?? '',
                        style: TextStyle(
                            color: c.muted, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Corner frame overlay painter ──────────────────────────────────────────────
class _FramePainter extends CustomPainter {
  final Color color;
  const _FramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const margin = 20.0;

    final corners = [
      // top-left
      [Offset(margin, margin + len), Offset(margin, margin),
       Offset(margin + len, margin)],
      // top-right
      [Offset(size.width - margin - len, margin),
       Offset(size.width - margin, margin),
       Offset(size.width - margin, margin + len)],
      // bottom-left
      [Offset(margin, size.height - margin - len),
       Offset(margin, size.height - margin),
       Offset(margin + len, size.height - margin)],
      // bottom-right
      [Offset(size.width - margin - len, size.height - margin),
       Offset(size.width - margin, size.height - margin),
       Offset(size.width - margin, size.height - margin - len)],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
