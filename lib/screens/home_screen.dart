import 'dart:ui';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/locale_service.dart';
import '../services/update_service.dart';
import '../theme.dart';
import '../widgets/ai_panel.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import 'sessions_screen.dart';
import 'settings_screen.dart';
import 'supplements_screen.dart';
import 'workout_program_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _tab = 0;
  GymRoi? _roi;
  bool _loading = true;

  // GlobalKeys for child screens (to call their methods)
  final _suppKey = GlobalKey<SupplementsScreenState>();
  final _sessKey = GlobalKey<SessionsScreenState>();
  final _progKey = GlobalKey<WorkoutProgramScreenState>();

  // avatar
  String? _avatarUrl;
  String _userName = '';

  // profile edit
  late TextEditingController _costCtrl;
  String _goal = 'general';
  late TextEditingController _badgeCtrl;
  bool _saving = false;
  bool _saved = false;

  // AI overlay
  bool _aiOpen = false;
  late AnimationController _aiAnimCtrl;
  late Animation<Offset> _aiSlide;
  late Animation<double> _aiDim;

  // Entrance animation
  bool _entered = false;
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _costCtrl = TextEditingController();
    _badgeCtrl = TextEditingController();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _aiAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _aiSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _aiAnimCtrl, curve: Curves.easeInOut));
    _aiDim = Tween<double>(begin: 0, end: 0.4)
        .animate(CurvedAnimation(parent: _aiAnimCtrl, curve: Curves.easeInOut));

    _loadDashboard();
    _checkUpdate();
    _loadAvatar();

    LocaleService.instance.langCode.addListener(_onLocaleChange);
  }

  void _onLocaleChange() {
    if (mounted) setState(() {});
  }

  void _openAi() {
    setState(() => _aiOpen = true);
    _aiAnimCtrl.forward();
  }

  void _closeAi() {
    _aiAnimCtrl.reverse().whenComplete(() {
      if (mounted) setState(() => _aiOpen = false);
    });
  }

  void _toggleAi() => _aiOpen ? _closeAi() : _openAi();

  @override
  void dispose() {
    _costCtrl.dispose();
    _badgeCtrl.dispose();
    _aiAnimCtrl.dispose();
    _entranceCtrl.dispose();
    LocaleService.instance.langCode.removeListener(_onLocaleChange);
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    try {
      final acc = await ApiService.instance.getAccountProfile();
      final accountData = acc['accountData'] as Map<String, dynamic>?;
      final profile = acc['profile'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _avatarUrl = accountData?['avatarUrl'] as String?;
          _userName = (profile?['name'] as String?) ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkUpdate() async {
    double prog = 0;
    final updated = await UpdateService.instance.checkAndUpdate(
      onProgress: (p) {
        prog = p;
        if (mounted && prog < 1.0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Downloading update… ${(prog * 100).toStringAsFixed(0)}%'),
            duration: const Duration(milliseconds: 800),
          ));
        }
      },
    );
    if (updated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Update downloaded — tap Install to apply.')),
      );
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final profJson = await ApiService.instance.getProfile();
      final roiJson = await ApiService.instance.getRoi();
      if (mounted) {
        final p = profJson != null ? FitnessProfile.fromJson(profJson) : null;
        setState(() {
          _roi = roiJson != null ? GymRoi.fromJson(roiJson) : null;
          if (p != null) {
            _costCtrl.text = '${p.monthlyGymCost}';
            _goal = p.fitnessGoal;
            _badgeCtrl.text = p.fitnessBadge;
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
    await Future.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      setState(() => _entered = true);
      _entranceCtrl.forward();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await ApiService.instance.saveProfile(
      monthlyGymCost: double.tryParse(_costCtrl.text) ?? 0,
      fitnessGoal: _goal,
      fitnessBadge: _badgeCtrl.text.trim(),
    );
    final roiJson = await ApiService.instance.getRoi();
    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
        if (roiJson != null) _roi = GymRoi.fromJson(roiJson);
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saved = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelH = size.height * 0.65;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildGlassAppBar(),
      bottomNavigationBar: _buildGlassBottomBar(bottomPad),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background blobs
          const AnimatedBackground(),

          // Tab content
          IndexedStack(
            index: _tab,
            children: [
              _buildDashboard(),
              SupplementsScreen(key: _suppKey),
              SessionsScreen(key: _sessKey),
              WorkoutProgramScreen(key: _progKey),
              const SettingsScreen(),
            ],
          ),

          // FAB for tabs that need it (above bottom nav)
          _buildFab(bottomPad),

          // Dim overlay
          AnimatedBuilder(
            animation: _aiDim,
            builder: (_, __) => IgnorePointer(
              ignoring: !_aiOpen,
              child: GestureDetector(
                onTap: _closeAi,
                child: Container(
                    color: Colors.black.withValues(alpha: _aiDim.value)),
              ),
            ),
          ),

          // AI Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: panelH,
            child: SlideTransition(
              position: _aiSlide,
              child: IgnorePointer(
                ignoring: !_aiOpen,
                child: AiPanel(onClose: _closeAi),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB (shown for Supplements, Sessions, Program tabs) ───────────────────
  Widget _buildFab(double bottomPad) {
    // Nav bar height: AI strip ~44px + nav items 56px + bottom safe area
    final navH = 44.0 + 58.0 + (bottomPad > 0 ? bottomPad : 8) + 4;

    if (_tab == 1) {
      return Positioned(
        right: 16,
        bottom: navH + 12,
        child: _glowFab(
          icon: Icons.add,
          label: 'Add',
          onTap: () => _suppKey.currentState?.showAdd(),
        ),
      );
    }
    if (_tab == 2) {
      return Positioned(
        right: 16,
        bottom: navH + 12,
        child: _glowFab(
          icon: Icons.fitness_center_rounded,
          label: 'Log',
          onTap: () => _sessKey.currentState?.showAdd(),
        ),
      );
    }
    if (_tab == 3) {
      return Positioned(
        right: 16,
        bottom: navH + 12,
        child: _glowFab(
          icon: Icons.auto_awesome_rounded,
          label: t('program_generate'),
          color: const Color(0xFF7C3AED),
          onTap: () => _progKey.currentState?.showAiGenerator(),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _glowFab({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = teal,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Glass AppBar ───────────────────────────────────────────────────────────
  PreferredSize _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0A7B72), teal, blue]),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'AC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AutoChecker',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    // Avatar
                    GestureDetector(
                      onTap: () => setState(() => _tab = 4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: teal.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: -2,
                            ),
                          ],
                          border: Border.all(
                            color: teal.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF0D1A2E),
                          backgroundImage:
                              (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                          child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                              ? Text(
                                  _userName.isNotEmpty
                                      ? _userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: teal,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
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

  // ── Glass Bottom Bar ───────────────────────────────────────────────────────
  Widget _buildGlassBottomBar(double bottomPad) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI Strip
              GestureDetector(
                onTap: _toggleAi,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 5),
                      decoration: BoxDecoration(
                        color: _aiOpen
                            ? teal.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _aiOpen
                              ? teal.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                        boxShadow: _aiOpen
                            ? [
                                BoxShadow(
                                  color: teal.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  spreadRadius: -4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: _aiOpen ? teal : textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t('helper_ai'),
                            style: TextStyle(
                              color: _aiOpen ? teal : textMuted,
                              fontSize: 12,
                              fontWeight: _aiOpen
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Nav items
              _buildNavItems(bottomPad),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nav Items with Sliding Pill ────────────────────────────────────────────
  Widget _buildNavItems(double bottomPad) {
    final items = [
      (Icons.grid_view_rounded, Icons.grid_view_outlined,
          t('tab_dashboard')),
      (Icons.science_rounded, Icons.science_outlined, t('tab_supplements')),
      (Icons.fitness_center_rounded, Icons.fitness_center_outlined,
          t('tab_sessions')),
      (Icons.event_note_rounded, Icons.event_note_outlined,
          t('tab_program')),
      (Icons.person_rounded, Icons.person_outlined, t('tab_settings')),
    ];
    return Padding(
      padding:
          EdgeInsets.only(bottom: bottomPad > 0 ? bottomPad : 8, top: 2),
      child: SizedBox(
        height: 56,
        child: Stack(
          children: [
            // Animated pill indicator
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment:
                  Alignment(-1 + (_tab * 2.0 / (items.length - 1)), 0),
              child: FractionallySizedBox(
                widthFactor: 1.0 / items.length,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: teal.withValues(alpha: 0.28)),
                  ),
                ),
              ),
            ),
            // Nav items row
            Row(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final (activeIcon, inactiveIcon, label) = entry.value;
                final active = _tab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_tab == 4 && i != 4) _loadAvatar();
                      setState(() => _tab = i);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            active ? activeIcon : inactiveIcon,
                            key: ValueKey(active ? 'a$i' : 'i$i'),
                            color: active ? teal : textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: active ? teal : textMuted,
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          child: Text(label),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dashboard Tab ──────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: teal, strokeWidth: 2));
    }
    return RefreshIndicator(
      color: teal,
      backgroundColor: const Color(0xFF0C1525),
      onRefresh: _loadDashboard,
      child: ListView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 120,
        ),
        children: [
          // ROI card
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.08),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              child: _roi != null
                  ? _buildRoiCard(_roi!)
                  : const SizedBox.shrink(),
            ),
          ),
          if (_roi != null) const SizedBox(height: 16),
          // Profile card
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.08),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: _buildProfileCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoiCard(GymRoi roi) {
    return GlassCard(
      glowColor: teal,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            _roiStat('${roi.sessionsCount}', t('sessions_month'),
                Icons.calendar_month_rounded),
            VerticalDivider(
                color: Colors.white.withValues(alpha: 0.10), width: 1),
            _roiStat('\$${roi.monthlyCost.toStringAsFixed(0)}',
                t('gym_cost'), Icons.credit_card_rounded),
            VerticalDivider(
                color: Colors.white.withValues(alpha: 0.10), width: 1),
            _roiStat('\$${roi.costPerSession.toStringAsFixed(2)}',
                t('cost_per_session'), Icons.trending_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _roiStat(String value, String label, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 16, color: teal.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Opacity(opacity: v, child: child),
              child: Text(
                value,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: textMuted, fontSize: 10, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: teal, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                t('fitness_profile'),
                style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _costCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t('gym_cost_label')),
            style: const TextStyle(color: textPrimary),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _goal,
            dropdownColor: const Color(0xFF0C1525),
            style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: t('fitness_goal_label'),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: teal, width: 1.5),
              ),
            ),
            items: [
              DropdownMenuItem(
                  value: 'general', child: Text(t('goal_general'))),
              DropdownMenuItem(
                  value: 'strength', child: Text(t('goal_strength'))),
              DropdownMenuItem(
                  value: 'hypertrophy',
                  child: Text(t('goal_hypertrophy'))),
              DropdownMenuItem(
                  value: 'endurance', child: Text(t('goal_endurance'))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _goal = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _badgeCtrl,
            decoration: InputDecoration(labelText: t('badge_label')),
            style: const TextStyle(color: textPrimary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _saved ? const Color(0xFF16A34A) : teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _saved
                                ? Icons.check_rounded
                                : Icons.save_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _saved ? t('saved') : t('save_profile'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
