import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../theme.dart';

// ── Data model ───────────────────────────────────────────────────────────────
class _FoodResult {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double weight;
  final String description;

  const _FoodResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.weight,
    required this.description,
  });

  factory _FoodResult.fromJson(Map<String, dynamic> j) => _FoodResult(
        name: j['name'] as String? ?? '',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0,
        carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        description: j['description'] as String? ?? '',
      );
}

// ── Widget ───────────────────────────────────────────────────────────────────
class FoodCalorieScreen extends StatefulWidget {
  const FoodCalorieScreen({super.key});

  @override
  FoodCalorieScreenState createState() => FoodCalorieScreenState();
}

class FoodCalorieScreenState extends State<FoodCalorieScreen>
    with TickerProviderStateMixin {
  XFile? _image;
  bool _analyzing = false;
  _FoodResult? _result;
  String? _error;

  // Scan beam — repeating 0→1
  late AnimationController _scanCtrl;

  // Result entrance — fade + slide
  late AnimationController _resultCtrl;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  // Animated counter (calories + macros fill)
  late AnimationController _countCtrl;

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _resultFade =
        CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _countCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _resultCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  // ── Public entry point called from HomeScreen FAB ─────────────────────────
  void showScanner() => _showPickerSheet();

  // ── Image picking ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1024,
    );
    if (file == null || !mounted) return;
    setState(() {
      _image = file;
      _result = null;
      _error = null;
    });
    _analyze(file);
  }

  Future<void> _analyze(XFile file) async {
    setState(() => _analyzing = true);
    _scanCtrl.repeat();
    try {
      final bytes = await file.readAsBytes();
      final json = await ApiService.instance.analyzeFood(bytes, 'image/jpeg');
      if (!mounted) return;
      // AI says no food in image
      if (json['error'] != null) {
        setState(() {
          _analyzing = false;
          _error = t('calorie_no_food');
        });
        _scanCtrl.stop();
        return;
      }
      final result = _FoodResult.fromJson(json);
      setState(() {
        _result = result;
        _analyzing = false;
        _error = null;
      });
      _scanCtrl.stop();
      _resultCtrl.forward(from: 0);
      _countCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      _scanCtrl.stop();
      setState(() {
        _analyzing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── Picker sheet ──────────────────────────────────────────────────────────
  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF9500)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFF6B35).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(t('calorie_title'),
                      style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: _pickerBtn(
                      Icons.camera_alt_rounded,
                      t('calorie_camera'),
                      () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _pickerBtn(
                      Icons.photo_library_rounded,
                      t('calorie_gallery'),
                      () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pickerBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          Icon(icon, color: teal, size: 28),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: textPrimary, fontSize: 13)),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad =
        kToolbarHeight + MediaQuery.of(context).padding.top + 16;
    final bottomPad =
        120 + MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
          top: topPad, left: 16, right: 16, bottom: bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            t('calorie_title'),
            style: const TextStyle(
              color: textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          // Image area or empty state
          if (_image == null)
            _buildEmptyState()
          else
            _buildImageArea(),

          // Results
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResultCard(),
          ],

          // Error
          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(),
          ],

          // Retry button
          if (_image != null && !_analyzing) ...[
            const SizedBox(height: 20),
            _buildRetryButton(),
          ],
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _showPickerSheet,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.07),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(
            color: teal.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera icon with glow ring
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  teal.withValues(alpha: 0.18),
                  teal.withValues(alpha: 0.04),
                ]),
                border: Border.all(color: teal.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.2),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: teal, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              t('calorie_empty'),
              style: TextStyle(
                color: textPrimary.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _miniBtn(Icons.camera_alt_rounded, t('calorie_camera'),
                    ImageSource.camera),
                const SizedBox(width: 10),
                _miniBtn(Icons.photo_library_rounded, t('calorie_gallery'),
                    ImageSource.gallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, String label, ImageSource src) {
    return GestureDetector(
      onTap: () => _pickImage(src),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: teal.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: teal, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Image area with scan overlay ──────────────────────────────────────────
  Widget _buildImageArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(_image!.path), fit: BoxFit.cover),
            if (_analyzing) _buildScanOverlay(),
            if (!_analyzing && _result != null)
              _buildSuccessGradient(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return AnimatedBuilder(
      animation: _scanCtrl,
      builder: (_, __) => LayoutBuilder(
        builder: (_, constraints) {
          final h = constraints.maxHeight;
          final beamY = h * _scanCtrl.value - 22;
          return Stack(
            children: [
              // Dark tint
              Container(color: Colors.black.withValues(alpha: 0.32)),

              // Scan beam
              Positioned(
                top: beamY,
                left: 0,
                right: 0,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        teal.withValues(alpha: 0.55),
                        teal.withValues(alpha: 0.85),
                        teal.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),

              // Corner brackets
              ..._corners(),

              // Spinner + text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: teal,
                        strokeWidth: 2.5,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('calorie_analyzing'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 8)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _corners() {
    const d = 26.0;
    const t2 = 2.5;
    const r = 7.0;
    const p = 14.0;
    return [
      Positioned(
          top: p,
          left: p,
          child:
              _BracketPaint(d, d, t2, r, teal, Corner.topLeft)),
      Positioned(
          top: p,
          right: p,
          child:
              _BracketPaint(d, d, t2, r, teal, Corner.topRight)),
      Positioned(
          bottom: p,
          left: p,
          child: _BracketPaint(
              d, d, t2, r, teal, Corner.bottomLeft)),
      Positioned(
          bottom: p,
          right: p,
          child: _BracketPaint(
              d, d, t2, r, teal, Corner.bottomRight)),
    ];
  }

  // ── Result card ───────────────────────────────────────────────────────────
  Widget _buildResultCard() {
    final r = _result!;
    final macroTotal = r.protein + r.carbs + r.fat;
    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name row
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6B35),
                            Color(0xFFFF9500)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35)
                                .withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.name,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),

                  if (r.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      r.description,
                      style: TextStyle(
                        color: textPrimary.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Big calorie counter ─────────────────────────────────
                  Center(
                    child: Column(children: [
                      AnimatedBuilder(
                        animation: _countCtrl,
                        builder: (_, __) {
                          final v = (r.calories *
                                  CurvedAnimation(
                                    parent: _countCtrl,
                                    curve: Curves.easeOut,
                                  ).value)
                              .round();
                          return ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                Color(0xFFFF9500),
                                Color(0xFFFF6B35),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              '$v',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -3,
                                height: 1,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('calorie_result_kcal').toUpperCase(),
                        style: const TextStyle(
                          color: teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                      if (r.weight > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '~${r.weight.round()} ${t('calorie_result_g')}  •  ${t('calorie_result_weight')}',
                          style: TextStyle(
                            color: textPrimary.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ]),
                  ),

                  const SizedBox(height: 22),
                  Divider(color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 18),

                  // ── Macro bars ──────────────────────────────────────────
                  _macroRow(
                    t('calorie_result_protein'),
                    r.protein,
                    const Color(0xFF60A5FA),
                    macroTotal,
                  ),
                  const SizedBox(height: 14),
                  _macroRow(
                    t('calorie_result_carbs'),
                    r.carbs,
                    const Color(0xFFF59E0B),
                    macroTotal,
                  ),
                  const SizedBox(height: 14),
                  _macroRow(
                    t('calorie_result_fat'),
                    r.fat,
                    const Color(0xFFF87171),
                    macroTotal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroRow(
      String label, double value, Color color, double total) {
    final fraction =
        total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6)
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: textPrimary.withValues(alpha: 0.75),
                      fontSize: 13)),
            ]),
            Text(
              '${value.round()} ${t('calorie_result_g')}',
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 7),
        AnimatedBuilder(
          animation: CurvedAnimation(
              parent: _countCtrl, curve: Curves.easeOut),
          builder: (_, __) {
            final anim = CurvedAnimation(
                parent: _countCtrl, curve: Curves.easeOut);
            return ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(children: [
                Container(
                    height: 7,
                    color: Colors.white.withValues(alpha: 0.07)),
                FractionallySizedBox(
                  widthFactor:
                      (fraction * anim.value).clamp(0.0, 1.0),
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.7),
                          color
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ],
    );
  }

  // ── Error card ────────────────────────────────────────────────────────────
  Widget _buildErrorCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color(0xFFEF4444), fontSize: 13)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Retry button ──────────────────────────────────────────────────────────
  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: _showPickerSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Colors.white.withValues(alpha: 0.06),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.camera_alt_rounded, color: teal, size: 16),
            const SizedBox(width: 8),
            Text(t('calorie_retry'),
                style: const TextStyle(
                    color: teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ]),
        ),
      ),
    );
  }
}

// ── Corner bracket painter ────────────────────────────────────────────────────
enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _BracketPaint extends StatelessWidget {
  final double w, h, thickness, radius;
  final Color color;
  final Corner corner;

  const _BracketPaint(
      this.w, this.h, this.thickness, this.radius, this.color, this.corner);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(w, h),
      painter: _BracketPainter(
          thickness: thickness,
          radius: radius,
          color: color,
          corner: corner),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final double thickness, radius;
  final Color color;
  final Corner corner;

  const _BracketPainter(
      {required this.thickness,
      required this.radius,
      required this.color,
      required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = radius;
    final path = Path();

    switch (corner) {
      case Corner.topLeft:
        path
          ..moveTo(0, h)
          ..lineTo(0, r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..lineTo(w, 0);
      case Corner.topRight:
        path
          ..moveTo(0, 0)
          ..lineTo(w - r, 0)
          ..quadraticBezierTo(w, 0, w, r)
          ..lineTo(w, h);
      case Corner.bottomLeft:
        path
          ..moveTo(0, 0)
          ..lineTo(0, h - r)
          ..quadraticBezierTo(0, h, r, h)
          ..lineTo(w, h);
      case Corner.bottomRight:
        path
          ..moveTo(0, h)
          ..lineTo(w - r, h)
          ..quadraticBezierTo(w, h, w, h - r)
          ..lineTo(w, 0);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}
