import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../services/exp_service.dart';
import '../services/nutrition_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

// ── Colors ───────────────────────────────────────────────────────────────────
const _calColor     = Color(0xFFFF6B35);
const _proteinColor = Color(0xFF60A5FA);
const _carbsColor   = Color(0xFFF59E0B);
const _fatColor     = Color(0xFFF87171);

// ── Temp scan result ─────────────────────────────────────────────────────────
class _ScanResult {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double weight;
  final String description;

  const _ScanResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.weight,
    required this.description,
  });

  factory _ScanResult.fromJson(Map<String, dynamic> j) => _ScanResult(
        name: j['name'] as String? ?? '',
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0,
        carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0,
        weight: (j['weight'] as num?)?.toDouble() ?? 0,
        description: j['description'] as String? ?? '',
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class FoodCalorieScreen extends StatefulWidget {
  const FoodCalorieScreen({super.key});

  @override
  FoodCalorieScreenState createState() => FoodCalorieScreenState();
}

class FoodCalorieScreenState extends State<FoodCalorieScreen>
    with TickerProviderStateMixin {
  DateTime _date = DateTime.now();

  // Scan animation
  late AnimationController _scanCtrl;
  bool _scanning = false;
  _ScanResult? _scanResult;
  String? _scanError;
  XFile? _scannedImage;

  // Entrance animation
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    NutritionService.instance.entries.addListener(_onEntriesChange);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _entranceCtrl.dispose();
    NutritionService.instance.entries.removeListener(_onEntriesChange);
    super.dispose();
  }

  void _onEntriesChange() {
    if (mounted) setState(() {});
  }

  // ── Public entry point from HomeScreen FAB ────────────────────────────────
  void showScanner() => _showAddOptions();

  // ── Date navigation ───────────────────────────────────────────────────────
  void _prevDay() => setState(() {
        _date = _date.subtract(const Duration(days: 1));
        _entranceCtrl.forward(from: 0);
      });

  void _nextDay() {
    if (_isToday) return;
    setState(() {
      _date = _date.add(const Duration(days: 1));
      _entranceCtrl.forward(from: 0);
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }

  String get _dateLabel {
    if (_isToday) return 'Today';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (_date.year == yesterday.year &&
        _date.month == yesterday.month &&
        _date.day == yesterday.day) return 'Yesterday';
    return '${_date.day}.${_date.month.toString().padLeft(2, '0')}.${_date.year}';
  }

  // ── Scan ──────────────────────────────────────────────────────────────────
  Future<void> _pickAndScan(ImageSource source) async {
    final file = await ImagePicker()
        .pickImage(source: source, imageQuality: 72, maxWidth: 1024);
    if (file == null || !mounted) return;
    setState(() {
      _scannedImage = file;
      _scanning = true;
      _scanResult = null;
      _scanError = null;
    });
    _scanCtrl.repeat();

    try {
      final bytes = await file.readAsBytes();
      final json = await ApiService.instance.analyzeFood(bytes, 'image/jpeg');
      if (!mounted) return;
      if (json['error'] != null) {
        setState(() { _scanning = false; _scanError = t('calorie_no_food'); });
        _scanCtrl.stop();
        return;
      }
      final result = _ScanResult.fromJson(json);
      setState(() { _scanning = false; _scanResult = result; });
      _scanCtrl.stop();
      _showConfirmDialog(result);
    } catch (e) {
      if (!mounted) return;
      _scanCtrl.stop();
      setState(() {
        _scanning = false;
        _scanError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showAddOptions() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: c.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _addOptionBtn(
                    Icons.camera_alt_rounded, 'Camera', _calColor,
                    () { Navigator.pop(context); _pickAndScan(ImageSource.camera); }),
                _addOptionBtn(
                    Icons.photo_library_rounded, 'Gallery', _proteinColor,
                    () { Navigator.pop(context); _pickAndScan(ImageSource.gallery); }),
                _addOptionBtn(
                    Icons.edit_rounded, 'Manual', _carbsColor,
                    () { Navigator.pop(context); _showManualEntry(); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _addOptionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Confirm dialog after scan ─────────────────────────────────────────────
  void _showConfirmDialog(_ScanResult result) {
    final c = AppColors.of(context);
    MealType selectedMeal = _nearestMeal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 16 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: c.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Food name + calories
              Row(children: [
                const Text('🍽️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name,
                          style: TextStyle(
                              color: c.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      Text('${result.calories} kcal • ${result.weight.round()}g',
                          style: TextStyle(color: c.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // Macros row
              Row(children: [
                _macroChip('P', '${result.protein.round()}g', _proteinColor),
                const SizedBox(width: 8),
                _macroChip('C', '${result.carbs.round()}g', _carbsColor),
                const SizedBox(width: 8),
                _macroChip('F', '${result.fat.round()}g', _fatColor),
              ]),
              const SizedBox(height: 16),

              // Meal picker
              Text('Add to', style: TextStyle(color: c.muted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: MealType.values.map((m) {
                final sel = selectedMeal == m;
                return GestureDetector(
                  onTap: () => setS(() => selectedMeal = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? _calColor.withValues(alpha: 0.15)
                          : c.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel
                            ? _calColor.withValues(alpha: 0.4)
                            : c.border,
                      ),
                    ),
                    child: Text(
                      '${m.emoji} ${m.label}',
                      style: TextStyle(
                        color: sel ? _calColor : c.muted,
                        fontSize: 11,
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),

              // Log button
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _logFood(result, selectedMeal);
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_calColor, Color(0xFFFF9500)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _calColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Log Food',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroChip(String abbr, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(abbr,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: color, fontSize: 11)),
      ]),
    );
  }

  MealType _nearestMeal() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 15) return MealType.lunch;
    if (h < 20) return MealType.dinner;
    return MealType.snacks;
  }

  Future<void> _logFood(_ScanResult r, MealType meal) async {
    final entry = NutritionEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: r.name,
      calories: r.calories,
      protein: r.protein,
      carbs: r.carbs,
      fat: r.fat,
      weight: r.weight,
      meal: meal,
      loggedAt: DateTime(
          _date.year, _date.month, _date.day,
          DateTime.now().hour, DateTime.now().minute),
    );
    await NutritionService.instance.addEntry(entry);
    await ExpService.instance.earn(ExpReward.photoFood);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${r.name} logged!'),
        backgroundColor: _calColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Manual entry ──────────────────────────────────────────────────────────
  void _showManualEntry([MealType? meal]) {
    final c = AppColors.of(context);
    final nameCtrl    = TextEditingController();
    final calCtrl     = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl   = TextEditingController();
    final fatCtrl     = TextEditingController();
    MealType selectedMeal = meal ?? _nearestMeal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 16 + MediaQuery.of(ctx).padding.bottom),
            decoration: BoxDecoration(
              color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: c.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Add Food Manually',
                    style: TextStyle(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                _inputField(nameCtrl, 'Food name', c),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _inputField(calCtrl, 'Calories', c,
                      num: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField(proteinCtrl, 'Protein (g)', c,
                      num: true)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _inputField(carbsCtrl, 'Carbs (g)', c,
                      num: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputField(fatCtrl, 'Fat (g)', c,
                      num: true)),
                ]),
                const SizedBox(height: 12),

                // Meal picker
                Wrap(
                  spacing: 8,
                  children: MealType.values.map((m) {
                    final sel = selectedMeal == m;
                    return GestureDetector(
                      onTap: () => setS(() => selectedMeal = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel
                              ? _calColor.withValues(alpha: 0.15)
                              : c.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? _calColor.withValues(alpha: 0.4)
                                : c.border,
                          ),
                        ),
                        child: Text('${m.emoji} ${m.label}',
                            style: TextStyle(
                              color: sel ? _calColor : c.muted,
                              fontSize: 11,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                GestureDetector(
                  onTap: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final cal  = int.tryParse(calCtrl.text) ?? 0;
                    final prot = double.tryParse(proteinCtrl.text) ?? 0;
                    final carb = double.tryParse(carbsCtrl.text) ?? 0;
                    final fat  = double.tryParse(fatCtrl.text) ?? 0;
                    Navigator.pop(ctx);
                    final r = _ScanResult(
                      name: name, calories: cal,
                      protein: prot, carbs: carb, fat: fat,
                      weight: 0, description: '',
                    );
                    await _logFood(r, selectedMeal);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_calColor, Color(0xFFFF9500)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Add',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController ctrl, String hint, AppColors c,
      {bool num = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: num
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: TextStyle(color: c.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.muted, fontSize: 13),
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _calColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  // ── Goals dialog ──────────────────────────────────────────────────────────
  void _showGoalsDialog() {
    final c = AppColors.of(context);
    final g = NutritionService.instance.goals.value;
    final calCtrl  = TextEditingController(text: '${g.calories}');
    final protCtrl = TextEditingController(text: '${g.protein}');
    final carbCtrl = TextEditingController(text: '${g.carbs}');
    final fatCtrl  = TextEditingController(text: '${g.fat}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 16 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: c.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Daily Goals',
                  style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _inputField(calCtrl, 'Calories', c, num: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _inputField(protCtrl, 'Protein (g)', c, num: true)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _inputField(carbCtrl, 'Carbs (g)', c, num: true)),
                const SizedBox(width: 8),
                Expanded(
                    child: _inputField(fatCtrl, 'Fat (g)', c, num: true)),
              ]),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  await NutritionService.instance.setGoals(NutritionGoals(
                    calories: int.tryParse(calCtrl.text) ?? 2000,
                    protein:  int.tryParse(protCtrl.text) ?? 150,
                    carbs:    int.tryParse(carbCtrl.text) ?? 200,
                    fat:      int.tryParse(fatCtrl.text) ?? 65,
                  ));
                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_calColor, Color(0xFFFF9500)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Save Goals',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Weight log dialog ─────────────────────────────────────────────────────
  void _showWeightDialog() {
    final c = AppColors.of(context);
    final latest = NutritionService.instance.latestWeight;
    final ctrl = TextEditingController(
        text: latest != null ? latest.toStringAsFixed(1) : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 16 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(
            color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: c.muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Log Weight',
                  style: TextStyle(
                      color: c.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _inputField(ctrl, 'Weight (kg)', c, num: true),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final kg = double.tryParse(ctrl.text);
                  if (kg == null || kg <= 0) return;
                  await NutritionService.instance.logWeight(kg);
                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00E5CC), Color(0xFF4361EE)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('Save',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topPad = kToolbarHeight + MediaQuery.of(context).padding.top + 12;

    return ValueListenableBuilder<List<NutritionEntry>>(
      valueListenable: NutritionService.instance.entries,
      builder: (_, __, ___) {
        final totals = NutritionService.instance.totalsForDate(_date);
        final goals  = NutritionService.instance.goals.value;
        final dayEntries = NutritionService.instance.entriesForDate(_date);

        return ListView(
          padding: EdgeInsets.only(
              top: topPad, left: 16, right: 16, bottom: 120),
          children: [
            // ── Date nav ──────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _entranceCtrl,
              builder: (_, child) => Opacity(
                  opacity: _entranceCtrl.value, child: child),
              child: _buildDateNav(c),
            ),
            const SizedBox(height: 16),

            // ── Macro ring summary ────────────────────────────────────────
            AnimatedBuilder(
              animation: _entranceCtrl,
              builder: (_, child) => Opacity(
                  opacity: _entranceCtrl.value, child: child),
              child: _buildMacroSummary(totals, goals, c),
            ),
            const SizedBox(height: 12),

            // ── Weight + goals quick buttons ──────────────────────────────
            Row(children: [
              Expanded(
                child: _quickBtn(
                  '⚖️',
                  NutritionService.instance.latestWeight != null
                      ? '${NutritionService.instance.latestWeight!.toStringAsFixed(1)} kg'
                      : 'Log weight',
                  c,
                  onTap: _showWeightDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickBtn(
                  '🎯', 'Edit goals', c,
                  onTap: _showGoalsDialog,
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Meal sections ─────────────────────────────────────────────
            ...MealType.values.map((meal) {
              final mealEntries =
                  dayEntries.where((e) => e.meal == meal).toList();
              return _buildMealSection(meal, mealEntries, c);
            }),

            // ── Scanning overlay if active ────────────────────────────────
            if (_scanning) ...[
              const SizedBox(height: 16),
              _buildScanningCard(c),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDateNav(AppColors c) {
    return Row(
      children: [
        GestureDetector(
          onTap: _prevDay,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.chevron_left_rounded,
                color: c.text, size: 22),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              _dateLabel,
              style: TextStyle(
                  color: c.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3),
            ),
          ),
        ),
        GestureDetector(
          onTap: _nextDay,
          child: AnimatedOpacity(
            opacity: _isToday ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chevron_right_rounded,
                  color: c.text, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroSummary(
    ({int cal, double protein, double carbs, double fat}) totals,
    NutritionGoals goals,
    AppColors c,
  ) {
    final calPct  = (totals.cal     / goals.calories).clamp(0.0, 1.0);
    final protPct = (totals.protein / goals.protein ).clamp(0.0, 1.0);
    final carbPct = (totals.carbs   / goals.carbs   ).clamp(0.0, 1.0);
    final fatPct  = (totals.fat     / goals.fat     ).clamp(0.0, 1.0);

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Central ring + calories
          Row(
            children: [
              // Big calorie ring
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: _RingPainter(
                        progress: calPct,
                        color: _calColor,
                        strokeWidth: 10,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${totals.cal}',
                          style: TextStyle(
                              color: c.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1),
                        ),
                        Text('kcal',
                            style:
                                TextStyle(color: c.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _macroBar('Protein', totals.protein, goals.protein,
                        _proteinColor, protPct, c),
                    const SizedBox(height: 10),
                    _macroBar('Carbs', totals.carbs, goals.carbs,
                        _carbsColor, carbPct, c),
                    const SizedBox(height: 10),
                    _macroBar('Fat', totals.fat, goals.fat,
                        _fatColor, fatPct, c),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Remaining
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: calPct >= 1.0
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : _calColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  calPct >= 1.0
                      ? '⚠️ Goal exceeded by ${totals.cal - goals.calories} kcal'
                      : '🔥 ${goals.calories - totals.cal} kcal remaining',
                  style: TextStyle(
                    color: calPct >= 1.0
                        ? const Color(0xFFEF4444)
                        : _calColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroBar(String label, double value, int goal, Color color,
      double pct, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: c.text, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
            Text('${value.round()}/$goal g',
                style: TextStyle(color: c.muted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: c.isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _quickBtn(String emoji, String label, AppColors c,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: c.text, fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(
      MealType meal, List<NutritionEntry> entries, AppColors c) {
    final mealCal = entries.fold(0, (s, e) => s + e.calories);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(meal.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(meal.label,
                  style: TextStyle(
                      color: c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (mealCal > 0)
                Text('$mealCal kcal',
                    style: TextStyle(color: c.muted, fontSize: 12)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAddOptions(),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _calColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _calColor.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: _calColor, size: 16),
                ),
              ),
            ]),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...entries.map((e) => _buildEntryRow(e, c)),
            ] else ...[
              const SizedBox(height: 8),
              Text('No food logged yet',
                  style: TextStyle(color: c.muted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(NutritionEntry e, AppColors c) {
    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFEF4444), size: 20),
      ),
      onDismissed: (_) => NutritionService.instance.removeEntry(e.id),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name,
                    style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  _miniMacro('P ${e.protein.round()}g', _proteinColor),
                  const SizedBox(width: 5),
                  _miniMacro('C ${e.carbs.round()}g', _carbsColor),
                  const SizedBox(width: 5),
                  _miniMacro('F ${e.fat.round()}g', _fatColor),
                ]),
              ],
            ),
          ),
          Text('${e.calories}',
              style: const TextStyle(
                  color: _calColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          Text(' kcal',
              style: TextStyle(color: c.muted, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _miniMacro(String text, Color color) => Text(text,
      style: TextStyle(
          color: color, fontSize: 10, fontWeight: FontWeight.w600));

  Widget _buildScanningCard(AppColors c) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
              color: _calColor, strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text('Analyzing photo…',
            style: TextStyle(color: c.text, fontSize: 13)),
      ]),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Legacy bracket painter (needed for compatibility) ─────────────────────────
enum Corner { topLeft, topRight, bottomLeft, bottomRight }

class _BracketPaint extends StatelessWidget {
  final double w, h, thickness, radius;
  final Color color;
  final Corner corner;
  const _BracketPaint(
      this.w, this.h, this.thickness, this.radius, this.color, this.corner);
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
