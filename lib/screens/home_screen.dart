import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/models.dart';
import '../services/achievements_service.dart';
import '../services/api_service.dart';
import '../services/bluetooth_service.dart' as bt_svc;
import '../services/connectivity_service.dart';
import '../services/exp_service.dart';
import '../services/locale_service.dart';
import '../services/nutrition_service.dart';
import '../services/spotify_service.dart';
import '../services/update_service.dart';
import '../theme.dart';
import '../widgets/ai_panel.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_gate.dart';
import '../widgets/voice_action_panel.dart';
import 'achievements_screen.dart';
import 'cv_workout_screen.dart';
import 'food_calorie_screen.dart';
import 'health_screen.dart';
import 'profile_screen.dart';
import 'sessions_screen.dart';
import 'shop_screen.dart';
import 'spotify_screen.dart';
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
  final _calKey = GlobalKey<FoodCalorieScreenState>();

  // Offline
  bool _isOnline = true;

  // avatar
  String? _avatarUrl;
  String _userName = '';

  // profile edit
  late TextEditingController _costCtrl;
  String _goal = 'general';
  late TextEditingController _badgeCtrl;
  bool _saving = false;
  bool _saved = false;

  // Spotify polling
  Timer? _spotifyTimer;

  // Bluetooth state
  int? _btBattery;
  bool _btConnected = false;

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
    _startSpotifyPolling();

    SpotifyService.instance.currentTrack.addListener(_onSpotifyTrackChange);
    ConnectivityService.instance.isOnline.addListener(_onConnectivityChange);
    LocaleService.instance.langCode.addListener(_onLocaleChange);

    // Bluetooth — request permissions then scan
    bt_svc.BluetoothService.instance.batteryLevel.addListener(_onBtBatteryChange);
    bt_svc.BluetoothService.instance.isConnected.addListener(_onBtConnectedChange);
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    await bt_svc.BluetoothService.instance.requestPermissionsAndScan();
  }

  void _onLocaleChange() {
    if (mounted) setState(() {});
  }

  void _onSpotifyTrackChange() {
    if (mounted) setState(() {});
  }

  void _onConnectivityChange() {
    if (mounted) setState(() => _isOnline = ConnectivityService.instance.isOnline.value);
  }

  void _onBtBatteryChange() {
    if (mounted) setState(() => _btBattery = bt_svc.BluetoothService.instance.batteryLevel.value);
  }

  void _onBtConnectedChange() {
    final connected = bt_svc.BluetoothService.instance.isConnected.value;
    if (mounted) {
      setState(() => _btConnected = connected);
      // Auto-open Program tab (tab 3) when headphones connect
      if (connected && _tab != 3) setState(() => _tab = 3);
    }
  }

  void _startSpotifyPolling() {
    _spotifyTimer?.cancel();
    // Poll immediately, then every 5 seconds
    SpotifyService.instance.fetchCurrentTrack();
    _spotifyTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => SpotifyService.instance.fetchCurrentTrack(),
    );
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
    _spotifyTimer?.cancel();
    _costCtrl.dispose();
    _badgeCtrl.dispose();
    _aiAnimCtrl.dispose();
    _entranceCtrl.dispose();
    SpotifyService.instance.currentTrack.removeListener(_onSpotifyTrackChange);
    ConnectivityService.instance.isOnline.removeListener(_onConnectivityChange);
    LocaleService.instance.langCode.removeListener(_onLocaleChange);
    bt_svc.BluetoothService.instance.batteryLevel.removeListener(_onBtBatteryChange);
    bt_svc.BluetoothService.instance.isConnected.removeListener(_onBtConnectedChange);
    bt_svc.BluetoothService.instance.stopScan();
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
    final info = await UpdateService.instance.getUpdateInfo();
    if (info == null || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => _UpdateDialog(info: info),
    );
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildGlassAppBar(),
      bottomNavigationBar: _buildGlassBottomBar(bottomPad),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background blobs
          const AnimatedBackground(),

          // Offline banner
          if (!_isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 6),
                      Text(
                        'Offline — showing cached data',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Tab content (6 tabs: Dashboard, Supplements, Sessions, Program, Calories, Settings)
          IndexedStack(
            index: _tab,
            children: [
              _buildDashboard(),
              SupplementsScreen(key: _suppKey),
              SessionsScreen(key: _sessKey),
              PremiumGate(
                featureName: 'Workout Program',
                featureDescription: 'AI-powered training plans, exercise library and progress tracking require Premium.',
                featureIcon: Icons.fitness_center_rounded,
                child: WorkoutProgramScreen(key: _progKey),
              ),
              PremiumGate(
                featureName: 'Food & Calories',
                featureDescription: 'AI photo food analysis and calorie tracking require Premium.',
                featureIcon: Icons.restaurant_rounded,
                child: FoodCalorieScreen(key: _calKey),
              ),
              const ProfileScreen(),
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
    // Nav bar height: pill nav + bottom safe area + padding
    final navH = 64.0 + (bottomPad > 0 ? bottomPad : 16) + 16 + 16;

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
    if (_tab == 4) {
      return Positioned(
        right: 16,
        bottom: navH + 12,
        child: _glowFab(
          icon: Icons.camera_alt_rounded,
          label: t('calorie_scan_btn'),
          color: accentPurple,
          onTap: () => _calKey.currentState?.showScanner(),
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
    );
  }

  // ── Calz AppBar — clean minimal ───────────────────────────────────────────
  PreferredSize _buildGlassAppBar() {
    final c = AppColors.of(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(
            bottom: BorderSide(color: c.border, width: 0.8),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo icon + brand ──────────────────────────────
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GymTracker',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),

                  // ── Action icons ──────────────────────────────────────
                  _appBarIcon(
                    icon: Icons.mic_rounded,
                    color: teal,
                    onTap: () async {
                      final logged = await showVoiceActionPanel(context);
                      if (logged && mounted) setState(() => _tab = 2);
                    },
                  ),
                  const SizedBox(width: 4),
                  _appBarIcon(
                    icon: Icons.favorite_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HealthScreen()),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _appBarIcon(
                    icon: Icons.music_note_rounded,
                    color: const Color(0xFF1DB954),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SpotifyScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Avatar circle ─────────────────────────────────
                  GestureDetector(
                        onTap: () => setState(() => _tab = 5),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _btConnected
                                      ? teal
                                      : teal.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: teal.withValues(alpha: 0.12),
                                backgroundImage: (_avatarUrl != null &&
                                        _avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                                child: (_avatarUrl == null ||
                                        _avatarUrl!.isEmpty)
                                    ? Text(
                                        _userName.isNotEmpty
                                            ? _userName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: teal,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            // BT battery badge
                            if (_btConnected && _btBattery != null)
                              Positioned(
                                right: -3,
                                bottom: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _btBattery! < 20
                                        ? const Color(0xFFEF4444)
                                        : _btBattery! < 50
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                        color: bgColor,
                                        width: 1.5),
                                  ),
                                  child: Text(
                                    '$_btBattery%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

  Widget _appBarIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border, width: 0.8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ── Calz BottomBar — clean solid pill ─────────────────────────────────────
  Widget _buildGlassBottomBar(double bottomPad) {
    final safeBottom = bottomPad > 0 ? bottomPad : 8.0;
    final c = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: safeBottom + 10,
        left: 20,
        right: 20,
      ),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: c.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.40 : 0.10),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _buildNavRow(c),
      ),
    );
  }

  // ── Nav row with embedded AI centre button ─────────────────────────────────
  Widget _buildNavRow(AppColors c) {
    // 3 normal tabs | AI centre | 3 normal tabs
    final leftItems = [
      (0, Icons.grid_view_rounded, Icons.grid_view_outlined, t('tab_dashboard')),
      (1, Icons.science_rounded, Icons.science_outlined, t('tab_supplements')),
      (2, Icons.fitness_center_rounded, Icons.fitness_center_outlined,
          t('tab_sessions')),
    ];
    final rightItems = [
      (3, Icons.event_note_rounded, Icons.event_note_outlined, t('tab_program')),
      (4, Icons.camera_alt_rounded, Icons.camera_alt_outlined, t('tab_calories')),
      (5, Icons.person_rounded, Icons.person_outlined, t('tab_profile')),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left tabs
        ...leftItems.map((item) {
          final (i, activeIcon, inactiveIcon, label) = item;
          return Expanded(child: _navItem(i, activeIcon, inactiveIcon, label, c));
        }),

        // ── AI centre button ───────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _toggleAi();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _aiOpen ? teal : teal.withValues(alpha: 0.12),
              border: Border.all(
                color: _aiOpen ? teal : teal.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: _aiOpen
                  ? [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.40),
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: _aiOpen ? Colors.white : teal,
              size: 21,
            ),
          ),
        ),

        // Right tabs
        ...rightItems.map((item) {
          final (i, activeIcon, inactiveIcon, label) = item;
          return Expanded(child: _navItem(i, activeIcon, inactiveIcon, label, c));
        }),
      ],
    );
  }

  // ── Nav item — Calz clean style ────────────────────────────────────────────
  Widget _navItem(int i, IconData activeIcon, IconData inactiveIcon,
      String label, AppColors c) {
    final active = _tab == i;
    final inactiveColor = c.muted;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (_tab == 5 && i != 5) {
          _loadAvatar();
          _startSpotifyPolling();
        }
        setState(() => _tab = i);
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 30,
              decoration: active
                  ? BoxDecoration(
                      color: teal.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : const BoxDecoration(),
              child: Icon(
                active ? activeIcon : inactiveIcon,
                color: active ? teal : inactiveColor,
                size: 19,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: active ? teal : inactiveColor,
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.clip),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dashboard Tab ──────────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final c = AppColors.of(context);
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: teal, strokeWidth: 2,
              backgroundColor: c.border));
    }
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t('greeting_morning')
        : hour < 17
            ? t('greeting_afternoon')
            : t('greeting_evening');

    return RefreshIndicator(
      color: teal,
      backgroundColor: c.surface,
      onRefresh: _loadDashboard,
      child: ListView(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
          left: 16,
          right: 16,
          bottom: 120,
        ),
        children: [
          // ── Greeting ────────────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.06),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName.isNotEmpty
                          ? '$greeting, ${_userName.split(' ').first} 👋'
                          : '$greeting 👋',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t('track_progress'),
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Today's nutrition card (Calz hero) ───────────────────────────
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 420),
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.06),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              child: _buildTodayNutritionCard(c),
            ),
          ),
          const SizedBox(height: 16),

          // ── ROI stat cards ────────────────────────────────────────────────
          if (_roi != null) ...[
            AnimatedOpacity(
              opacity: _entered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 480),
              child: AnimatedSlide(
                offset: _entered ? Offset.zero : const Offset(0, 0.06),
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutCubic,
                child: _buildRoiRow(_roi!, c),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── EXP level card ───────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 520),
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.06),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              child: _buildExpCard(c),
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick actions row ─────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 550),
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.06),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              child: _buildQuickActions(c),
            ),
          ),
          const SizedBox(height: 16),

          // ── Profile config card ──────────────────────────────────────────
          AnimatedOpacity(
            opacity: _entered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 580),
            child: AnimatedSlide(
              offset: _entered ? Offset.zero : const Offset(0, 0.06),
              duration: const Duration(milliseconds: 580),
              curve: Curves.easeOutCubic,
              child: _buildProfileCard(c),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's nutrition hero card (Calz style) ─────────────────────────────
  Widget _buildTodayNutritionCard(AppColors c) {
    return ValueListenableBuilder<List<NutritionEntry>>(
      valueListenable: NutritionService.instance.entries,
      builder: (_, __, ___) {
        final totals = NutritionService.instance.totalsForDate(DateTime.now());
        final goals = NutritionService.instance.goals.value;
        final calProgress = goals.calories > 0
            ? (totals.cal / goals.calories).clamp(0.0, 1.0)
            : 0.0;
        final remaining = goals.calories - totals.cal;

        return GestureDetector(
          onTap: () => setState(() => _tab = 4),
          child: Container(
            decoration: c.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Calorie ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(80, 80),
                        painter: _DashboardRingPainter(
                          progress: calProgress,
                          color: teal,
                          bg: c.border,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${totals.cal}',
                            style: TextStyle(
                              color: c.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'kcal',
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('today_nutrition'),
                        style: TextStyle(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining > 0
                            ? '$remaining ${t('kcal_remaining')}'
                            : t('goal_reached'),
                        style: TextStyle(
                          color: remaining > 0 ? c.muted : teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _macroRow(t('calorie_result_protein'), totals.protein, goals.protein.toDouble(),
                          macroProtein, c),
                      const SizedBox(height: 6),
                      _macroRow(t('calorie_result_carbs'), totals.carbs, goals.carbs.toDouble(),
                          macroCarbs, c),
                      const SizedBox(height: 6),
                      _macroRow(t('calorie_result_fat'), totals.fat, goals.fat.toDouble(),
                          macroFat, c),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _macroRow(String label, double val, double goal, Color color, AppColors c) {
    final progress = goal > 0 ? (val / goal).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: TextStyle(color: c.muted, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${val.round()}g',
          style: TextStyle(color: c.text, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── EXP level card ────────────────────────────────────────────────────────
  Widget _buildExpCard(AppColors c) {
    return ValueListenableBuilder<int>(
      valueListenable: ExpService.instance.exp,
      builder: (_, exp, __) {
        final level = ExpService.instance.level;
        final progress = ExpService.instance.progress;
        final streak = ExpService.instance.streak.value;
        return GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Level badge
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShopScreen())),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.30),
                        blurRadius: 12,
                        spreadRadius: -3,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('LVL', style: TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      Text('$level', style: const TextStyle(
                          color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text('⚡ $exp EXP',
                              style: TextStyle(
                                  color: c.text, fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                          if (streak > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Text('🔥 $streak days',
                                  style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ]),
                        Text('${ExpService.instance.expToNext} to next',
                            style: TextStyle(color: c.muted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: c.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(teal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Quick action buttons ───────────────────────────────────────────────────
  Widget _buildQuickActions(AppColors c) {
    final actions = [
      (
        '🏆',
        'Achievements',
        const Color(0xFFF59E0B),
        () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AchievementsScreen())),
      ),
      (
        '🛍️',
        'Shop',
        const Color(0xFF7C3AED),
        () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShopScreen())),
      ),
      (
        '📸',
        'Form AI',
        teal,
        () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CvWorkoutScreen())),
      ),
    ];

    return Row(
      children: actions.map((a) {
        final (emoji, label, color, onTap) = a;
        return Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              margin: EdgeInsets.only(
                  right: a == actions.last ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: c.isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: color.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 5),
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoiRow(GymRoi roi, AppColors c) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            value: '${roi.sessionsCount}',
            label: t('sessions_month'),
            icon: Icons.calendar_month_rounded,
            color: teal,
            c: c,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            value: '\$${roi.monthlyCost.toStringAsFixed(0)}',
            label: t('gym_cost'),
            icon: Icons.credit_card_rounded,
            color: blue,
            c: c,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            value: '\$${roi.costPerSession.toStringAsFixed(2)}',
            label: t('cost_per_session'),
            icon: Icons.trending_down_rounded,
            color: macroProtein,
            c: c,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      decoration: c.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: c.muted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AppColors c) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline_rounded,
                    color: teal, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                t('fitness_profile'),
                style: TextStyle(
                    color: c.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _costCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t('gym_cost_label')),
                  style: TextStyle(color: c.text),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final addCtrl = TextEditingController();
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: c.surface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(t('add_to_cost'),
                          style: TextStyle(color: c.text, fontSize: 16)),
                      content: TextField(
                        controller: addCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: t('add_amount'),
                          labelStyle: TextStyle(color: c.textMuted),
                          hintText: '0.00',
                          hintStyle: TextStyle(color: c.textMuted),
                        ),
                        style: TextStyle(color: c.text),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(t('cancel'),
                              style: TextStyle(color: c.textMuted)),
                        ),
                        TextButton(
                          onPressed: () {
                            final current =
                                double.tryParse(_costCtrl.text) ?? 0;
                            final add = double.tryParse(addCtrl.text) ?? 0;
                            _costCtrl.text =
                                (current + add).toStringAsFixed(2);
                            Navigator.pop(ctx);
                          },
                          child: Text(t('confirm'),
                              style: TextStyle(color: c.primary)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: c.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.add, color: c.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _goal,
            dropdownColor: c.surface,
            style: TextStyle(color: c.text),
            decoration: InputDecoration(
              labelText: t('fitness_goal_label'),
              filled: true,
              fillColor: c.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: teal, width: 1.5),
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
            style: TextStyle(color: c.text),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _saving ? null : _saveProfile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _saved ? const Color(0xFF22C55E) : teal,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (_saved ? const Color(0xFF22C55E) : teal)
                          .withValues(alpha: 0.30),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _saved ? t('saved') : t('save_profile'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Beautiful update download dialog ─────────────────────────────────────────
class _UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> info;
  const _UpdateDialog({required this.info});

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0;
  bool _downloading = false;
  bool _done = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() => _downloading = true);
    _pulseCtrl.repeat(reverse: true);

    await UpdateService.instance.downloadAndInstall(
      info: widget.info,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) {
      _pulseCtrl.stop();
      setState(() {
        _done = true;
        _progress = 1.0;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildNum = widget.info['build'] as int? ?? 0;
    final pct = (_progress * 100).toStringAsFixed(0);

    return PopScope(
      canPop: !_downloading,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: teal.withValues(alpha: 0.12),
                        blurRadius: 40,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, child) => Transform.scale(
                            scale: _downloading && !_done ? _pulse.value : 1.0,
                            child: child,
                          ),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _done
                                    ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                    : [teal, const Color(0xFFFF9B6B)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_done
                                          ? const Color(0xFF22C55E)
                                          : teal)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _done
                                  ? Icons.check_rounded
                                  : _downloading
                                      ? Icons.download_rounded
                                      : Icons.system_update_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          _done
                              ? 'Готово!'
                              : _downloading
                                  ? 'Завантаження…'
                                  : 'Доступне оновлення',
                          style: const TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _done
                              ? 'Оновлення встановлено'
                              : _downloading
                                  ? '$pct%'
                                  : 'Збірка #$buildNum',
                          style: const TextStyle(
                            color: textMuted,
                            fontSize: 14,
                          ),
                        ),

                        if (_downloading && !_done) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.10),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(teal),
                              minHeight: 6,
                            ),
                          ),
                        ],

                        if (!_downloading && !_done) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Пізніше',
                                    style: TextStyle(color: textMuted),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _startDownload,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: teal,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  child: const Text('Оновити'),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

// ── Dashboard Ring Painter ────────────────────────────────────────────────────
class _DashboardRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;

  const _DashboardRingPainter({
    required this.progress,
    required this.color,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 10) / 2;

    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawArc(rect, -1.57, 6.28, false, bgPaint);
    if (progress > 0) {
      canvas.drawArc(rect, -1.57, 6.28 * progress, false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(_DashboardRingPainter old) =>
      old.progress != progress || old.color != color;
}
