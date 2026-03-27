import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

const _prefKey = 'workout_program_v1';

class WorkoutProgramScreen extends StatefulWidget {
  const WorkoutProgramScreen({super.key});

  @override
  State<WorkoutProgramScreen> createState() => WorkoutProgramScreenState();
}

class WorkoutProgramScreenState extends State<WorkoutProgramScreen>
    with SingleTickerProviderStateMixin {
  String _program = '';
  bool _editing = false;
  bool _saving = false;
  bool _saved = false;
  late TextEditingController _editCtrl;

  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? '';
    if (mounted) {
      setState(() => _program = saved);
      _entranceCtrl.forward();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _editCtrl.text.trim());
    if (mounted) {
      setState(() {
        _program = _editCtrl.text.trim();
        _saving = false;
        _saved = true;
        _editing = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saved = false);
    }
  }

  void _startEditing() {
    _editCtrl.text = _program;
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() => _editing = false);
  }

  // ── AI Generation sheet ──────────────────────────────────────────────────
  void showAiGenerator() => _openAiGenerator();

  void _openAiGenerator() {
    final ageCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String goal = 'muscle';
    String level = 'intermediate';
    String equipment = 'gym';
    int days = 4;
    String lang = 'uk';
    bool generating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
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
                    // Handle
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

                    // Title row
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), teal],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        t('ai_gen_title'),
                        style: const TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Age + Weight row
                    Row(children: [
                      Expanded(
                        child: _sheetField(t('ai_gen_age'), ageCtrl,
                            numeric: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sheetField(
                            t('ai_gen_weight'), weightCtrl,
                            numeric: true),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Goal
                    _sheetLabel(t('ai_gen_goal')),
                    const SizedBox(height: 6),
                    _chipRow(
                      options: [
                        ('muscle', t('ai_gen_goal_muscle')),
                        ('fat', t('ai_gen_goal_fat')),
                        ('strength', t('ai_gen_goal_strength')),
                        ('endurance', t('ai_gen_goal_endurance')),
                        ('general', t('ai_gen_goal_general')),
                      ],
                      selected: goal,
                      onSelect: (v) => setSheet(() => goal = v),
                    ),
                    const SizedBox(height: 14),

                    // Level
                    _sheetLabel(t('ai_gen_level')),
                    const SizedBox(height: 6),
                    _chipRow(
                      options: [
                        ('beginner', t('ai_gen_level_beg')),
                        ('intermediate', t('ai_gen_level_int')),
                        ('advanced', t('ai_gen_level_adv')),
                      ],
                      selected: level,
                      onSelect: (v) => setSheet(() => level = v),
                    ),
                    const SizedBox(height: 14),

                    // Equipment
                    _sheetLabel(t('ai_gen_equipment')),
                    const SizedBox(height: 6),
                    _chipRow(
                      options: [
                        ('gym', t('ai_gen_equip_gym')),
                        ('home', t('ai_gen_equip_home')),
                        ('bodyweight', t('ai_gen_equip_body')),
                        ('barbell', t('ai_gen_equip_barbell')),
                      ],
                      selected: equipment,
                      onSelect: (v) => setSheet(() => equipment = v),
                    ),
                    const SizedBox(height: 14),

                    // Days per week
                    _sheetLabel('${t('ai_gen_days')}: $days'),
                    const SizedBox(height: 4),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: teal,
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.12),
                        thumbColor: teal,
                        overlayColor: teal.withValues(alpha: 0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: days.toDouble(),
                        min: 2,
                        max: 6,
                        divisions: 4,
                        onChanged: (v) =>
                            setSheet(() => days = v.round()),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                          labelText: t('ai_gen_notes')),
                      style: const TextStyle(
                          color: textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Language
                    _sheetLabel(t('ai_gen_lang')),
                    const SizedBox(height: 6),
                    _chipRow(
                      options: [
                        ('uk', t('ai_gen_lang_uk')),
                        ('en', t('ai_gen_lang_en')),
                      ],
                      selected: lang,
                      onSelect: (v) => setSheet(() => lang = v),
                    ),
                    const SizedBox(height: 20),

                    // Generate button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: generating
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF7C3AED), teal],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                        color: generating
                            ? Colors.white.withValues(alpha: 0.08)
                            : null,
                        boxShadow: generating
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: generating
                              ? null
                              : () async {
                                  setSheet(() => generating = true);
                                  try {
                                    final prompt =
                                        _buildPrompt(
                                      age: ageCtrl.text.trim(),
                                      weight: weightCtrl.text.trim(),
                                      goal: goal,
                                      level: level,
                                      equipment: equipment,
                                      days: days,
                                      notes: notesCtrl.text.trim(),
                                      lang: lang,
                                    );
                                    final result =
                                        await ApiService.instance
                                            .sendAiMessage([
                                      {
                                        'role': 'user',
                                        'content': prompt,
                                      }
                                    ]);
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    _applyGenerated(result);
                                  } catch (e) {
                                    setSheet(
                                        () => generating = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx)
                                          .showSnackBar(SnackBar(
                                        content: Text('Error: $e'),
                                      ));
                                    }
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15),
                            child: Center(
                              child: generating
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          t('ai_gen_generating'),
                                          style: const TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Colors.white,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          t('ai_gen_btn'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
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

  void _applyGenerated(String result) {
    _editCtrl.text = result;
    setState(() {
      _program = result;
      _editing = false;
    });
    // auto-save
    SharedPreferences.getInstance()
        .then((p) => p.setString(_prefKey, result));
  }

  String _buildPrompt({
    required String age,
    required String weight,
    required String goal,
    required String level,
    required String equipment,
    required int days,
    required String notes,
    String lang = 'uk',
  }) {
    final sb = StringBuffer();

    if (lang == 'uk') {
      final goalMap = {
        'muscle': 'набір м\'язової маси',
        'fat': 'спалення жиру та схуднення',
        'strength': 'збільшення сили',
        'endurance': 'покращення витривалості',
        'general': 'загальна фізична форма',
      };
      final levelMap = {
        'beginner': 'початківець',
        'intermediate': 'середній рівень',
        'advanced': 'просунутий рівень',
      };
      final equipMap = {
        'gym': 'повноцінний зал (тренажери, блоки, штанги, гантелі)',
        'home': 'домашнє тренування з гантелями',
        'bodyweight': 'тренування без обладнання (власна вага)',
        'barbell': 'штанга та силова стійка',
      };
      sb.writeln('Склади детальну тижневу програму тренувань для такої людини:');
      if (age.isNotEmpty) sb.writeln('- Вік: $age років');
      if (weight.isNotEmpty) sb.writeln('- Вага: $weight кг');
      sb.writeln('- Ціль: ${goalMap[goal] ?? goal}');
      sb.writeln('- Рівень підготовки: ${levelMap[level] ?? level}');
      sb.writeln('- Доступне обладнання: ${equipMap[equipment] ?? equipment}');
      sb.writeln('- Кількість тренувальних днів на тиждень: $days');
      if (notes.isNotEmpty) sb.writeln('- Додаткова інформація: $notes');
      sb.writeln();
      sb.writeln(
          'Відповідь надай УКРАЇНСЬКОЮ мовою. '
          'Оформи як чіткий тижневий план. Для кожного тренувального дня вкажи: '
          'назву дня, групи м\'язів, список вправ із підходами×повторами та часом відпочинку. '
          'Додай рекомендації щодо розминки та заминки. Будь конкретним і практичним.');
    } else {
      final goalMap = {
        'muscle': 'build muscle mass',
        'fat': 'burn fat and lose weight',
        'strength': 'increase strength',
        'endurance': 'improve endurance',
        'general': 'improve general fitness',
      };
      final levelMap = {
        'beginner': 'beginner',
        'intermediate': 'intermediate',
        'advanced': 'advanced',
      };
      final equipMap = {
        'gym': 'full gym (machines, cables, barbells, dumbbells)',
        'home': 'home setup with dumbbells',
        'bodyweight': 'bodyweight only (no equipment)',
        'barbell': 'barbell and power rack',
      };
      sb.writeln('Create a detailed weekly workout program for the following person:');
      if (age.isNotEmpty) sb.writeln('- Age: $age years');
      if (weight.isNotEmpty) sb.writeln('- Weight: $weight kg');
      sb.writeln('- Goal: ${goalMap[goal] ?? goal}');
      sb.writeln('- Fitness level: ${levelMap[level] ?? level}');
      sb.writeln('- Available equipment: ${equipMap[equipment] ?? equipment}');
      sb.writeln('- Training days per week: $days');
      if (notes.isNotEmpty) sb.writeln('- Additional info: $notes');
      sb.writeln();
      sb.writeln(
          'Reply in ENGLISH. '
          'Format as a clear weekly plan. For each training day include: '
          'day name, muscle focus, list of exercises with sets×reps and '
          'rest time. Include warm-up and cool-down recommendations. '
          'Be specific and practical.');
    }

    return sb.toString();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad =
        kToolbarHeight + MediaQuery.of(context).padding.top + 16;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                border: Border(
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        t('program_title'),
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (_editing) ...[
                        GestureDetector(
                          onTap: _cancelEditing,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.12)),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: textMuted, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _saving ? null : _save,
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _saved
                                  ? const Color(0xFF16A34A)
                                  : teal,
                              borderRadius:
                                  BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  spreadRadius: -3,
                                ),
                              ],
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(
                                    _saved
                                        ? t('program_saved')
                                        : t('program_save'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _startEditing,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.10)),
                            ),
                            child: const Icon(Icons.edit_outlined,
                                color: textMuted, size: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _entranceCtrl,
        builder: (context, child) {
          final v =
              Curves.easeOutCubic.transform(_entranceCtrl.value);
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - v)),
              child: child,
            ),
          );
        },
        child: _editing ? _buildEditor(topPad) : _buildViewer(topPad),
      ),
    );
  }

  // ── Editor ───────────────────────────────────────────────────────────────
  Widget _buildEditor(double topPad) {
    return Padding(
      padding: EdgeInsets.only(
          top: topPad, left: 16, right: 16, bottom: 100),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.11)),
            ),
            child: TextField(
              controller: _editCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                  color: textPrimary, fontSize: 14, height: 1.6),
              decoration: InputDecoration(
                hintText: t('program_hint'),
                hintStyle:
                    const TextStyle(color: textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Viewer ───────────────────────────────────────────────────────────────
  Widget _buildViewer(double topPad) {
    if (_program.isEmpty) {
      return _buildEmptyState(topPad);
    }

    return ListView(
      padding: EdgeInsets.only(
          top: topPad, left: 16, right: 16, bottom: 120),
      children: [
        // AI generate button always visible at top
        _buildAiGenerateCard(),
        const SizedBox(height: 16),
        // Program content
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: SelectableText(
            _program,
            style: const TextStyle(
                color: textPrimary, fontSize: 14, height: 1.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double topPad) {
    return ListView(
      padding: EdgeInsets.only(
          top: topPad, left: 16, right: 16, bottom: 120),
      children: [
        // AI generate button — main CTA
        _buildAiGenerateCard(),
        const SizedBox(height: 20),

        // Manual option
        GestureDetector(
          onTap: _startEditing,
          child: GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: textMuted, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('program_edit'),
                        style: const TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t('program_hint'),
                        style: const TextStyle(
                            color: textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiGenerateCard() {
    return GestureDetector(
      onTap: _openAiGenerator,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF1D4ED8), teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // subtle shimmer circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: -10,
                bottom: -10,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('program_generate'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            t('program_generate_sub'),
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sheet helpers ────────────────────────────────────────────────────────
  Widget _sheetField(String label, TextEditingController ctrl,
      {bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: false)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      style: const TextStyle(color: textPrimary, fontSize: 14),
    );
  }

  Widget _sheetLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          color: textMuted, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }

  Widget _chipRow({
    required List<(String, String)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final (val, label) = o;
        final active = selected == val;
        return GestureDetector(
          onTap: () => onSelect(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: active
                  ? teal.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? teal.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? teal : textMuted,
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
