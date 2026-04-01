import 'dart:ui';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/achievements_service.dart';
import '../services/api_service.dart';
import '../services/exp_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

const _workoutTypes = [
  'push', 'pull', 'legs', 'upper', 'lower', 'full_body', 'cardio', 'other'
];

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  SessionsScreenState createState() => SessionsScreenState();
}

class SessionsScreenState extends State<SessionsScreen>
    with SingleTickerProviderStateMixin {
  List<GymSession> _sessions = [];
  bool _loading = true;

  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.instance.getSessions();
      final list = raw
          .map((e) => GymSession.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _sessions = list);
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
      _listCtrl.forward(from: 0);
    }
  }

  void showAdd() {
    String selectedType = 'full_body';
    final dateCtrl = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));
    final durCtrl = TextEditingController(text: '60');
    final costCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final List<Map<String, TextEditingController>> exercises = [];

    void addExercise(StateSetter setModalState) {
      exercises.add({
        'name': TextEditingController(),
        'sets': TextEditingController(text: '3'),
        'reps': TextEditingController(text: '10'),
        'kg': TextEditingController(text: '0'),
      });
      setModalState(() {});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.13),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28)),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                            Icons.fitness_center_rounded,
                            color: teal,
                            size: 14),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t('add_session'),
                        style: const TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _field('Date', dateCtrl)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _field(t('duration_min'), durCtrl,
                              numeric: true)),
                    ]),
                    const SizedBox(height: 10),
                    _field(t('session_cost'), costCtrl,
                        numeric: true),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        dropdownColor: surfaceColor,
                        style: const TextStyle(color: textPrimary),
                        decoration: InputDecoration(
                          labelText: t('workout_type'),
                          filled: true,
                          fillColor:
                              Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white
                                    .withValues(alpha: 0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white
                                    .withValues(alpha: 0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: teal, width: 1.5),
                          ),
                        ),
                        items: _workoutTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.replaceAll('_', ' '),
                                    style: const TextStyle(
                                        color: textPrimary),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedType = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(t('notes_optional'), notesCtrl),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('exercises'),
                          style: const TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: () => addExercise(setModalState),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: teal.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      teal.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add,
                                    size: 14, color: teal),
                                const SizedBox(width: 4),
                                Text(t('add_exercise'),
                                    style: const TextStyle(
                                        color: teal,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...exercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ex = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(children: [
                          Expanded(
                              flex: 3,
                              child:
                                  _field(t('exercise_name'), ex['name']!)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _field(t('sets'), ex['sets']!,
                                  numeric: true)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _field(t('reps'), ex['reps']!,
                                  numeric: true)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: _field(t('weight_kg'), ex['kg']!,
                                  numeric: true)),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFFEF4444),
                                size: 18),
                            onPressed: () => setModalState(
                                () => exercises.removeAt(i)),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final exList = exercises
                              .map((ex) => {
                                    'name':
                                        ex['name']!.text.trim(),
                                    'sets': int.tryParse(
                                            ex['sets']!.text) ??
                                        1,
                                    'reps': int.tryParse(
                                            ex['reps']!.text) ??
                                        1,
                                    'weightKg':
                                        double.tryParse(
                                                ex['kg']!.text) ??
                                            0,
                                  })
                              .toList();
                          final volumeKg = exList.fold<double>(
                            0,
                            (sum, ex) =>
                                sum +
                                (ex['sets'] as int) *
                                    (ex['reps'] as int) *
                                    (ex['weightKg'] as double),
                          );
                          Navigator.pop(ctx);
                          await ApiService.instance.createSession({
                            'date': dateCtrl.text.trim(),
                            'durationMin':
                                int.tryParse(durCtrl.text) ?? 60,
                            'workoutType': selectedType,
                            'volumeKg': volumeKg,
                            'exercises': exList,
                            if (notesCtrl.text.trim().isNotEmpty)
                              'notes': notesCtrl.text.trim(),
                          });
                          // Add session cost to monthly gym cost
                          final sessionCost =
                              double.tryParse(costCtrl.text.trim()) ?? 0;
                          if (sessionCost > 0) {
                            final profile =
                                await ApiService.instance.getProfile();
                            final current =
                                (profile?['monthlyGymCost'] as num?)
                                    ?.toDouble() ??
                                0;
                            await ApiService.instance.saveProfile(
                              monthlyGymCost: current + sessionCost,
                              fitnessGoal: profile?['fitnessGoal'] as String? ??
                                  'general',
                              fitnessBadge:
                                  profile?['fitnessBadge'] as String? ?? '',
                            );
                          }
                          // EXP + achievements
                          await ExpService.instance.earn(ExpReward.session);
                          await AchievementsService.instance.onSessionLogged();
                          final streak = ExpService.instance.streak.value;
                          await AchievementsService.instance.onStreakUpdate(streak);
                          await AchievementsService.instance.onLevelUp(ExpService.instance.level);
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          t('add_session'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    final topPad =
        kToolbarHeight + MediaQuery.of(context).padding.top + 16;

    if (_loading) {
      return const Center(
          child:
              CircularProgressIndicator(color: teal, strokeWidth: 2));
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Icon(Icons.fitness_center_outlined,
                  color: textMuted, size: 32),
            ),
            const SizedBox(height: 16),
            Text(t('no_sessions'),
                style: const TextStyle(color: textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: teal,
      backgroundColor: surfaceColor,
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.only(
            top: topPad, left: 16, right: 16, bottom: 120),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = _sessions[i];
          return AnimatedBuilder(
            animation: _listCtrl,
            builder: (context, child) {
              final delay = (i * 0.07).clamp(0.0, 0.7);
              final progress =
                  ((_listCtrl.value - delay) / (1.0 - delay))
                      .clamp(0.0, 1.0);
              final curved =
                  Curves.easeOutCubic.transform(progress);
              return Opacity(
                opacity: curved,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - curved)),
                  child: child,
                ),
              );
            },
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: teal.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      s.workoutType
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: const TextStyle(
                        color: teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.date,
                            style: const TextStyle(
                                color: textMuted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip('${s.durationMin} min',
                                Icons.timer_outlined),
                            if (s.volumeKg > 0)
                              _chip(
                                  '${s.volumeKg.toStringAsFixed(0)} kg',
                                  Icons.fitness_center_outlined),
                            if (s.exercises.isNotEmpty)
                              _chip('${s.exercises.length} ex.',
                                  Icons.list_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFEF4444), size: 20),
                    onPressed: () async {
                      await ApiService.instance.deleteSession(s.id);
                      _load();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
