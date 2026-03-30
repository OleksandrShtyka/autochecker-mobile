import 'package:flutter/material.dart';

import '../services/achievements_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    AchievementsService.instance.checkAccountAge();
    AchievementsService.instance.unlocked.addListener(_onUnlockChange);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    AchievementsService.instance.unlocked.removeListener(_onUnlockChange);
    super.dispose();
  }

  void _onUnlockChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final unlockedIds = AchievementsService.instance.unlocked.value;
    final total    = kAllAchievements.length;
    final earned   = kAllAchievements.where((a) => unlockedIds.contains(a.id)).length;
    final progress = earned / total;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(c, earned, total, progress),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (_, __) => _buildGrid(c, unlockedIds),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors c, int earned, int total, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
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
                  child: Icon(Icons.arrow_back_ios_rounded,
                      color: c.text, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievements',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  Text('$earned / $total unlocked',
                      style: TextStyle(color: c.muted, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            radius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress',
                        style: TextStyle(
                            color: c.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Text('${(progress * 100).round()}%',
                        style: const TextStyle(
                            color: teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
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
  }

  Widget _buildGrid(AppColors c, Set<String> unlockedIds) {
    // Группировка: unlocked сначала
    final unlocked = kAllAchievements
        .where((a) => unlockedIds.contains(a.id))
        .toList();
    final locked = kAllAchievements
        .where((a) => !unlockedIds.contains(a.id))
        .toList();
    final sorted = [...unlocked, ...locked];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final a = sorted[i];
        final isUnlocked = unlockedIds.contains(a.id);
        final delay = (i * 0.04).clamp(0.0, 0.6);
        final anim = CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(anim),
            child: _AchievementCard(
              achievement: a,
              isUnlocked: isUnlocked,
              c: c,
            ),
          ),
        );
      },
    );
  }
}

// ── Achievement card ──────────────────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final AppColors c;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
    required this.c,
  });

  Color get _rarityColor {
    switch (achievement.rarity) {
      case AchievementRarity.common:    return const Color(0xFF6B7280);
      case AchievementRarity.rare:      return const Color(0xFF3B82F6);
      case AchievementRarity.epic:      return const Color(0xFF8B5CF6);
      case AchievementRarity.legendary: return const Color(0xFFF59E0B);
    }
  }

  String get _rarityLabel {
    switch (achievement.rarity) {
      case AchievementRarity.common:    return 'Common';
      case AchievementRarity.rare:      return 'Rare';
      case AchievementRarity.epic:      return 'Epic';
      case AchievementRarity.legendary: return 'Legendary';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      glowColor: isUnlocked ? _rarityColor : null,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  achievement.emoji,
                  style: TextStyle(
                    fontSize: isUnlocked ? 32 : 28,
                  ),
                ),
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _rarityColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _rarityColor.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      _rarityLabel,
                      style: TextStyle(
                          color: _rarityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Icon(Icons.lock_outline_rounded,
                      color: c.muted, size: 16),
              ],
            ),
            const Spacer(),
            Text(
              achievement.title,
              style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2),
            ),
            const SizedBox(height: 3),
            Text(
              achievement.description,
              style: TextStyle(color: c.muted, fontSize: 11, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 3),
                Text(
                  '+${achievement.expReward} EXP',
                  style: TextStyle(
                      color: isUnlocked ? teal : c.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
