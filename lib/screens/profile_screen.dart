import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/bluetooth_service.dart' as bt_svc;
import '../services/subscription_service.dart';
import '../theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _diamondCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeIn;

  String _name = '';
  String _email = '';
  String? _avatarUrl;
  String _birthday = '';
  String _gender = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _diamondCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    _load();
  }

  Future<void> _load() async {
    try {
      final acc = await ApiService.instance.getAccountProfile();
      final accountData = acc['accountData'] as Map<String, dynamic>?;
      final profileData = acc['profile'] as Map<String, dynamic>?;
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _name = (profileData?['name'] as String?) ?? (acc['name'] as String?) ?? '';
          _email = (acc['email'] as String?) ?? (accountData?['email'] as String?) ?? '';
          _avatarUrl = (accountData?['avatarUrl'] as String?) ?? (acc['avatarUrl'] as String?);
          _birthday = prefs.getString('profile_birthday') ?? '';
          _gender = prefs.getString('profile_gender') ?? '';
          _loading = false;
        });
        _entranceCtrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _diamondCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Achievements ──────────────────────────────────────────────────────────

  List<_Achievement> _buildAchievements(SubscriptionStatus sub) {
    final btConnected = bt_svc.BluetoothService.instance.isConnected.value;
    return [
      _Achievement('🏋️', 'First Rep', 'Logged your first session', true),
      _Achievement('💊', 'Supplement Pro', 'Added first supplement', true),
      _Achievement('🔥', 'Committed', '7+ sessions logged', true),
      _Achievement('🎧', 'Audio Connect', 'Connected Gelius earphones', btConnected),
      _Achievement('🤖', 'AI Powered', 'Used AI voice action', true),
      _Achievement('💎', 'Premium', 'Subscribed to Premium', sub.isPremium),
      _Achievement('📊', 'Data Master', '30+ sessions logged', false),
      _Achievement('🏆', 'Elite', 'All achievements unlocked', false),
    ];
  }

  // ── Edit birthday/gender ──────────────────────────────────────────────────

  Future<void> _editBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday.isNotEmpty
          ? DateTime.tryParse(_birthday) ?? DateTime(2000)
          : DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: teal,
            onPrimary: Colors.white,
            surface: Color(0xFF0D1B2A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final str = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_birthday', str);
      if (mounted) setState(() => _birthday = str);
    }
  }

  Future<void> _editGender() async {
    final options = ['Male', 'Female', 'Other'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((o) => ListTile(
                title: Text(o, style: const TextStyle(color: textPrimary)),
                trailing: _gender == o
                    ? const Icon(Icons.check_rounded, color: teal)
                    : null,
                onTap: () => Navigator.pop(context, o),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_gender', picked);
      if (mounted) setState(() => _gender = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF060F1A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: teal, strokeWidth: 2))
          : FadeTransition(
              opacity: _fadeIn,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 24),
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildSubscriptionCard(),
                        const SizedBox(height: 20),
                        _buildAchievementsCard(),
                        const SizedBox(height: 20),
                        _buildSettingsButton(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Sliver AppBar with avatar ─────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      backgroundColor: const Color(0xFF060F1A),
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0A2540), Color(0xFF060F1A)],
                ),
              ),
            ),
            // Decorative glow
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: teal.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Avatar + name
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildAvatar(),
                const SizedBox(height: 14),
                Text(
                  _name.isNotEmpty ? _name : 'User',
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(color: textMuted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ValueListenableBuilder<SubscriptionStatus>(
      valueListenable: SubscriptionService.instance.status,
      builder: (_, sub, __) {
        final isPremium = sub.isPremium;
        final size = 90.0;
        final borderW = 3.0;

        Widget avatar = CircleAvatar(
          radius: size / 2 - borderW,
          backgroundColor: const Color(0xFF0D2137),
          backgroundImage:
              _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
          child: _avatarUrl == null
              ? Text(
                  _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: teal,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        );

        if (isPremium) {
          return AnimatedBuilder(
            animation: _diamondCtrl,
            builder: (_, child) => CustomPaint(
              painter: _DiamondBorderPainter(
                progress: _diamondCtrl.value,
                size: size,
                borderW: borderW + 1,
              ),
              child: child,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(child: avatar),
            ),
          );
        }

        // Free — simple gradient border
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [teal, Color(0xFF1B5BA0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.all(borderW),
          child: avatar,
        );
      },
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return _glassCard(
      child: Column(
        children: [
          _infoRow(
            Icons.cake_rounded,
            'Birthday',
            _birthday.isNotEmpty ? _formatDate(_birthday) : 'Tap to set',
            onTap: _editBirthday,
          ),
          _divider(),
          _infoRow(
            Icons.person_outline_rounded,
            'Gender',
            _gender.isNotEmpty ? _gender : 'Tap to set',
            onTap: _editGender,
          ),
        ],
      ),
    );
  }

  // ── Subscription Card ─────────────────────────────────────────────────────

  Widget _buildSubscriptionCard() {
    return ValueListenableBuilder<SubscriptionStatus>(
      valueListenable: SubscriptionService.instance.status,
      builder: (_, sub, __) {
        final isPremium = sub.isPremium;
        return _glassCard(
          gradient: isPremium
              ? const LinearGradient(
                  colors: [Color(0xFF0A3D62), Color(0xFF1B5BA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_outline_rounded,
                    color: isPremium ? Colors.amber : textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? 'Premium Member' : 'Free Plan',
                        style: TextStyle(
                          color: isPremium ? Colors.white : textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isPremium
                            ? sub.planLabel + (sub.expiryLabel.isNotEmpty ? ' · ${sub.expiryLabel}' : '')
                            : 'Upgrade to unlock all features',
                        style: TextStyle(
                          color: isPremium
                              ? Colors.white.withValues(alpha: 0.7)
                              : textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      '💎 PRO',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Achievements Card ─────────────────────────────────────────────────────

  Widget _buildAchievementsCard() {
    return ValueListenableBuilder<SubscriptionStatus>(
      valueListenable: SubscriptionService.instance.status,
      builder: (_, sub, __) {
        final achievements = _buildAchievements(sub);
        final unlocked = achievements.where((a) => a.unlocked).length;
        return _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Achievements',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$unlocked / ${achievements.length}',
                      style: const TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: unlocked / achievements.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(teal),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: achievements.map(_buildAchievementBadge).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementBadge(_Achievement a) {
    return Tooltip(
      message: '${a.title}\n${a.desc}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: a.unlocked
                  ? teal.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: a.unlocked
                    ? teal.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                a.icon,
                style: TextStyle(
                  fontSize: 22,
                  color: a.unlocked ? null : const Color(0xFF2A3A4A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a.title,
            style: TextStyle(
              color: a.unlocked ? textPrimary : textMuted.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Settings Button ───────────────────────────────────────────────────────

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      child: _glassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_rounded, color: textMuted, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _glassCard({required Widget child, Gradient? gradient}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? Colors.white.withValues(alpha: 0.04)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: teal, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: textMuted, fontSize: 13)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: value.contains('Tap') ? textMuted : textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, color: textMuted, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
        indent: 16,
        endIndent: 16,
      );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Diamond Border Painter ────────────────────────────────────────────────────

class _DiamondBorderPainter extends CustomPainter {
  final double progress;
  final double size;
  final double borderW;

  const _DiamondBorderPainter({
    required this.progress,
    required this.size,
    required this.borderW,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    // Diamond / crystal colours
    const colors = [
      Color(0xFF00FFFF),
      Color(0xFF7DF9FF),
      Color(0xFFFFFFFF),
      Color(0xFFB9F2FF),
      Color(0xFF89CFF0),
      Color(0xFFADD8E6),
      Color(0xFFFFFFFF),
      Color(0xFF00FFFF),
    ];

    final shader = SweepGradient(
      colors: colors,
      startAngle: 0,
      endAngle: 2 * pi,
      transform: GradientRotation(2 * pi * progress),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderW
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(center, radius - borderW / 2, paint);

    // Sparkle dots at rotating positions
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = 2 * pi * progress + (i * pi / 2);
      final x = center.dx + (radius - borderW / 2) * cos(angle);
      final y = center.dy + (radius - borderW / 2) * sin(angle);
      canvas.drawCircle(Offset(x, y), 2, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(_DiamondBorderPainter old) => old.progress != progress;
}

// ── Achievement model ─────────────────────────────────────────────────────────

class _Achievement {
  final String icon;
  final String title;
  final String desc;
  final bool unlocked;
  const _Achievement(this.icon, this.title, this.desc, this.unlocked);
}
