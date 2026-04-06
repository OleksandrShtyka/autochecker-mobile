import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class WeightEntry {
  final String date;
  final double weightKg;
  final int sets;
  final int reps;

  const WeightEntry({
    required this.date,
    required this.weightKg,
    required this.sets,
    required this.reps,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'weightKg': weightKg,
        'sets': sets,
        'reps': reps,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        date: j['date'] as String,
        weightKg: (j['weightKg'] as num).toDouble(),
        sets: (j['sets'] as num?)?.toInt() ?? 1,
        reps: (j['reps'] as num?)?.toInt() ?? 1,
      );
}

class ExerciseProgression {
  final String name;
  final List<WeightEntry> entries; // sorted by date ascending

  const ExerciseProgression({required this.name, required this.entries});

  double get latestWeight =>
      entries.isEmpty ? 0 : entries.last.weightKg;

  double get firstWeight =>
      entries.isEmpty ? 0 : entries.first.weightKg;

  double get changePct => firstWeight == 0
      ? 0
      : ((latestWeight - firstWeight) / firstWeight) * 100;

  bool get isImproving => latestWeight > firstWeight;
  bool get isStagnant => latestWeight == firstWeight;
}

// ── Screen ────────────────────────────────────────────────────────────────────

const _prefKey = 'weight_progression_v1';

class WeightProgressionScreen extends StatefulWidget {
  final String currentProgram;

  const WeightProgressionScreen({super.key, required this.currentProgram});

  @override
  State<WeightProgressionScreen> createState() =>
      _WeightProgressionScreenState();
}

class _WeightProgressionScreenState extends State<WeightProgressionScreen>
    with SingleTickerProviderStateMixin {
  List<ExerciseProgression> _progressions = [];
  bool _loading = true;
  bool _analyzing = false;
  String? _aiResult;
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Load: merge session data + manual entries ──────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = true);

    // 1. Session-based entries
    final Map<String, List<WeightEntry>> map = {};
    try {
      final raw = await ApiService.instance.getSessions();
      final sessions = raw
          .map((e) => GymSession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      for (final s in sessions) {
        for (final ex in s.exercises) {
          final e = ex as Map<String, dynamic>;
          final name = (e['name'] as String? ?? '').trim().toLowerCase();
          if (name.isEmpty) continue;
          final kg = (e['weightKg'] as num?)?.toDouble() ?? 0;
          if (kg <= 0) continue;
          map.putIfAbsent(name, () => []).add(WeightEntry(
            date: s.date,
            weightKg: kg,
            sets: (e['sets'] as num?)?.toInt() ?? 1,
            reps: (e['reps'] as num?)?.toInt() ?? 1,
          ));
        }
      }
    } catch (_) {}

    // 2. Manual entries from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        for (final kv in decoded.entries) {
          final name = kv.key.toLowerCase();
          final entries = (kv.value as List<dynamic>)
              .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          map.putIfAbsent(name, () => []).addAll(entries);
        }
      }
    } catch (_) {}

    // 3. Build sorted progressions
    final list = map.entries.map((kv) {
      final sorted = kv.value.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return ExerciseProgression(name: kv.key, entries: sorted);
    }).toList()
      ..sort((a, b) => b.entries.length.compareTo(a.entries.length));

    if (mounted) {
      setState(() {
        _progressions = list;
        _loading = false;
      });
      _entranceCtrl.forward(from: 0);
    }
  }

  // ── Save manual entry ──────────────────────────────────────────────────────

  Future<void> _saveManualEntry(
      String name, double kg, int sets, int reps) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    final Map<String, dynamic> stored =
        raw != null ? json.decode(raw) as Map<String, dynamic> : {};

    final key = name.trim().toLowerCase();
    final existingList = (stored[key] as List<dynamic>?)
            ?.map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    existingList.add(WeightEntry(
      date: DateTime.now().toIso8601String().substring(0, 10),
      weightKg: kg,
      sets: sets,
      reps: reps,
    ));
    stored[key] = existingList.map((e) => e.toJson()).toList();
    await prefs.setString(_prefKey, json.encode(stored));
    await _load();
  }

  // ── AI analysis ───────────────────────────────────────────────────────────

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _aiResult = null;
    });

    final sb = StringBuffer();
    sb.writeln('Ось дані про прогресію ваг атлета по вправах:');
    sb.writeln();
    for (final p in _progressions) {
      sb.writeln('Вправа: ${p.name.toUpperCase()}');
      for (final e in p.entries) {
        sb.writeln(
            '  ${e.date}: ${e.weightKg} кг × ${e.sets}×${e.reps}');
      }
      final pct = p.changePct;
      sb.writeln(
          '  Зміна: ${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%');
      sb.writeln();
    }
    if (widget.currentProgram.isNotEmpty) {
      sb.writeln('Поточна програма тренувань:');
      sb.writeln(widget.currentProgram);
      sb.writeln();
    }
    sb.writeln(
        'Проаналізуй прогресію ваг. Вкажи: які вправи прогресують добре, '
        'які стагнують або регресують, та запропонуй конкретні корективи '
        'у програму (зміна ваг, об\'єму, інтенсивності, нові вправи). '
        'Будь конкретним і практичним. Відповідай УКРАЇНСЬКОЮ.');

    try {
      final result = await ApiService.instance.sendAiMessage([
        {'role': 'user', 'content': sb.toString()}
      ]);
      if (mounted) setState(() => _aiResult = result);
    } catch (e) {
      if (mounted) setState(() => _aiResult = 'Помилка аналізу. Спробуй ще раз.');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  // ── Add entry dialog ──────────────────────────────────────────────────────

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final kgCtrl = TextEditingController();
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.trending_up_rounded,
                      color: teal, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  t('wp_add_entry'),
                  style: const TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 18),
              _field(t('exercise_name'), nameCtrl),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _field('${t('weight_kg')} *', kgCtrl,
                        numeric: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(t('sets'), setsCtrl, numeric: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(t('reps'), repsCtrl, numeric: true)),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final kg = double.tryParse(kgCtrl.text) ?? 0;
                  if (name.isEmpty || kg <= 0) return;
                  Navigator.pop(ctx);
                  await _saveManualEntry(
                    name,
                    kg,
                    int.tryParse(setsCtrl.text) ?? 3,
                    int.tryParse(repsCtrl.text) ?? 10,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text(t('wp_add_entry'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      style: const TextStyle(color: textPrimary, fontSize: 13),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textPrimary,
        elevation: 0,
        title: Text(t('wp_title'),
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.07)),
        ),
        actions: [
          GestureDetector(
            onTap: _showAddDialog,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: teal, size: 15),
                  const SizedBox(width: 4),
                  Text(t('add'),
                      style: const TextStyle(
                          color: teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: teal, strokeWidth: 2))
          : _buildBody(),
      floatingActionButton: _progressions.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _analyzing ? null : _analyze,
              backgroundColor: _analyzing ? surfaceColor : teal,
              elevation: 0,
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: teal),
                    )
                  : const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _analyzing ? t('wp_analyzing') : t('wp_analyze_btn'),
                style: TextStyle(
                    color: _analyzing ? teal : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (_, child) {
        final v = Curves.easeOutCubic.transform(_entranceCtrl.value);
        return Opacity(opacity: v, child: child);
      },
      child: RefreshIndicator(
        color: teal,
        backgroundColor: surfaceColor,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // AI result card
            if (_aiResult != null) ...[
              _buildAiResultCard(),
              const SizedBox(height: 16),
            ],

            // Empty state
            if (_progressions.isEmpty) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(Icons.trending_up_rounded,
                          color: textMuted, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(t('wp_empty'),
                        style: const TextStyle(
                            color: textMuted, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(t('wp_empty_sub'),
                        style: const TextStyle(
                            color: textMuted,
                            fontSize: 12,
                            height: 1.5),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ] else ...[
              // Summary row
              _buildSummaryRow(),
              const SizedBox(height: 16),

              // Exercise cards
              ...List.generate(_progressions.length, (i) {
                final p = _progressions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildExerciseCard(p),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final improving =
        _progressions.where((p) => p.changePct > 0).length;
    final stagnant =
        _progressions.where((p) => p.changePct == 0).length;
    final declining =
        _progressions.where((p) => p.changePct < 0).length;

    return Row(children: [
      _summaryChip(improving.toString(), t('wp_improving'),
          const Color(0xFF22C55E)),
      const SizedBox(width: 8),
      _summaryChip(stagnant.toString(), t('wp_stagnant'),
          textMuted),
      const SizedBox(width: 8),
      _summaryChip(declining.toString(), t('wp_declining'),
          const Color(0xFFEF4444)),
    ]);
  }

  Widget _summaryChip(String count, String label, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseProgression p) {
    final isPositive = p.changePct > 0;
    final isNegative = p.changePct < 0;
    final trendColor = isPositive
        ? const Color(0xFF22C55E)
        : isNegative
            ? const Color(0xFFEF4444)
            : textMuted;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(children: [
            Expanded(
              child: Text(
                _capitalize(p.name),
                style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ),
            // Trend badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: trendColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : isNegative
                            ? Icons.trending_down_rounded
                            : Icons.trending_flat_rounded,
                    color: trendColor,
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${isPositive ? '+' : ''}${p.changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: trendColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Mini progress chart (weight bars)
          if (p.entries.length >= 2) ...[
            _buildMiniChart(p),
            const SizedBox(height: 10),
          ],

          // Latest entry + count
          Row(children: [
            const Icon(Icons.fitness_center_rounded,
                color: teal, size: 13),
            const SizedBox(width: 5),
            Text(
              '${p.latestWeight} кг',
              style: const TextStyle(
                  color: teal,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Text(
              '${p.entries.length} ${t('wp_records')}',
              style: const TextStyle(color: textMuted, fontSize: 11),
            ),
            const Spacer(),
            Text(
              p.entries.last.date,
              style: const TextStyle(color: textMuted, fontSize: 11),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMiniChart(ExerciseProgression p) {
    final maxW = p.entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
    final minW = p.entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
    final range = (maxW - minW).clamp(1.0, double.infinity);

    // Show last 8 entries at most
    final entries = p.entries.length > 8
        ? p.entries.sublist(p.entries.length - 8)
        : p.entries;

    return SizedBox(
      height: 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.asMap().entries.map((kv) {
          final entry = kv.value;
          final pct = ((entry.weightKg - minW) / range).clamp(0.0, 1.0);
          final h = 8 + pct * 24;
          final isLast = kv.key == entries.length - 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                height: h,
                decoration: BoxDecoration(
                  color: isLast
                      ? teal
                      : teal.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAiResultCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            teal.withValues(alpha: 0.15),
            blue.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: teal.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome_rounded, color: teal, size: 16),
            const SizedBox(width: 8),
            Text(t('wp_ai_result'),
                style: const TextStyle(
                    color: teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _aiResult = null),
              child: const Icon(Icons.close_rounded,
                  color: textMuted, size: 16),
            ),
          ]),
          const SizedBox(height: 12),
          SelectableText(
            _aiResult!,
            style: const TextStyle(
                color: textPrimary, fontSize: 13, height: 1.65),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
