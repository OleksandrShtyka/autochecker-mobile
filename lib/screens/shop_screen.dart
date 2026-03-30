import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/achievements_service.dart';
import '../services/exp_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';

// ── Shop items ────────────────────────────────────────────────────────────────
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int cost;
  final ShopCategory category;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.cost,
    required this.category,
  });
}

enum ShopCategory { badge, frame, theme, powerup }

const List<ShopItem> kShopItems = [
  // Badges
  ShopItem(
    id: 'badge_fire',
    name: 'Fire Badge',
    description: 'Show off your dedication',
    emoji: '🔥',
    cost: 200,
    category: ShopCategory.badge,
  ),
  ShopItem(
    id: 'badge_diamond',
    name: 'Diamond Badge',
    description: 'For the true elite',
    emoji: '💎',
    cost: 500,
    category: ShopCategory.badge,
  ),
  ShopItem(
    id: 'badge_crown',
    name: 'Crown Badge',
    description: 'Royalty status',
    emoji: '👑',
    cost: 1000,
    category: ShopCategory.badge,
  ),
  ShopItem(
    id: 'badge_lightning',
    name: 'Lightning Badge',
    description: 'Speed and power',
    emoji: '⚡',
    cost: 350,
    category: ShopCategory.badge,
  ),

  // Avatar frames
  ShopItem(
    id: 'frame_teal',
    name: 'Teal Frame',
    description: 'Glowing teal avatar border',
    emoji: '🟢',
    cost: 300,
    category: ShopCategory.frame,
  ),
  ShopItem(
    id: 'frame_gold',
    name: 'Gold Frame',
    description: 'Legendary golden border',
    emoji: '🌟',
    cost: 800,
    category: ShopCategory.frame,
  ),
  ShopItem(
    id: 'frame_rainbow',
    name: 'Rainbow Frame',
    description: 'Animated rainbow border',
    emoji: '🌈',
    cost: 1500,
    category: ShopCategory.frame,
  ),

  // Theme accents
  ShopItem(
    id: 'theme_rose',
    name: 'Rose Accent',
    description: 'Pink/rose UI accent color',
    emoji: '🌹',
    cost: 600,
    category: ShopCategory.theme,
  ),
  ShopItem(
    id: 'theme_purple',
    name: 'Purple Accent',
    description: 'Deep purple UI accent',
    emoji: '💜',
    cost: 600,
    category: ShopCategory.theme,
  ),
  ShopItem(
    id: 'theme_orange',
    name: 'Orange Accent',
    description: 'Warm orange UI accent',
    emoji: '🟠',
    cost: 600,
    category: ShopCategory.theme,
  ),

  // Powerups
  ShopItem(
    id: 'powerup_x2',
    name: 'EXP x2 (24h)',
    description: 'Double EXP for 24 hours',
    emoji: '⚡',
    cost: 400,
    category: ShopCategory.powerup,
  ),
  ShopItem(
    id: 'powerup_streak_shield',
    name: 'Streak Shield',
    description: 'Protect your streak once',
    emoji: '🛡️',
    cost: 250,
    category: ShopCategory.powerup,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  ShopCategory? _filter;
  Set<String> _purchased = {};
  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    ExpService.instance.exp.addListener(_onExpChange);
    _loadPurchased();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    ExpService.instance.exp.removeListener(_onExpChange);
    super.dispose();
  }

  void _onExpChange() => setState(() {});

  Future<void> _loadPurchased() async {
    final items = await ExpService.instance.getPurchasedItems();
    if (mounted) setState(() => _purchased = items);
  }

  Future<void> _buy(ShopItem item) async {
    if (_purchased.contains(item.id)) return;
    HapticFeedback.mediumImpact();

    final ok = await ExpService.instance.buyItem(item.id, item.cost);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Not enough EXP'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    await _loadPurchased();
    await AchievementsService.instance.onShopPurchase();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Text(item.emoji),
          const SizedBox(width: 8),
          Text('${item.name} purchased!',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: teal,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final exp = ExpService.instance.exp.value;
    final filtered = _filter == null
        ? kShopItems
        : kShopItems.where((i) => i.category == _filter).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(c, exp),
                _buildFilters(c),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (_, __) => _buildGrid(c, filtered),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors c, int exp) {
    final level = ExpService.instance.level;
    final progress = ExpService.instance.progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                  Text('Shop',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  Text('Spend your EXP on rewards',
                      style: TextStyle(color: c.muted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              // EXP balance pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: teal.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: -3,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('$exp',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Level progress bar
          GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level $level',
                              style: TextStyle(
                                  color: c.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text(
                            '${ExpService.instance.expToNext} to next',
                            style:
                                TextStyle(color: c.muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppColors c) {
    final cats = [
      (null, 'All', '🛍️'),
      (ShopCategory.badge, 'Badges', '🏅'),
      (ShopCategory.frame, 'Frames', '🖼️'),
      (ShopCategory.theme, 'Themes', '🎨'),
      (ShopCategory.powerup, 'Power-ups', '⚡'),
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: cats.map((cat) {
          final (value, label, icon) = cat;
          final selected = _filter == value;
          return GestureDetector(
            onTap: () => setState(() => _filter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                  color: selected ? Colors.transparent : c.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : c.muted,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGrid(AppColors c, List<ShopItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final owned = _purchased.contains(item.id);
        final canAfford =
            ExpService.instance.exp.value >= item.cost;
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
            child: _ShopCard(
              item: item,
              owned: owned,
              canAfford: canAfford,
              c: c,
              onBuy: () => _buy(item),
            ),
          ),
        );
      },
    );
  }
}

// ── Shop card ─────────────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final bool owned;
  final bool canAfford;
  final AppColors c;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.c,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      glowColor: owned ? teal : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 32)),
              if (owned)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: teal.withValues(alpha: 0.4)),
                  ),
                  child: const Text('Owned',
                      style: TextStyle(
                          color: teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const Spacer(),
          Text(
            item.name,
            style: TextStyle(
                color: c.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2),
          ),
          const SizedBox(height: 3),
          Text(
            item.description,
            style: TextStyle(color: c.muted, fontSize: 11, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          if (!owned)
            GestureDetector(
              onTap: canAfford ? onBuy : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: canAfford
                      ? const LinearGradient(
                          colors: [Color(0xFF00E5CC), Color(0xFF4361EE)])
                      : null,
                  color: canAfford
                      ? null
                      : (c.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '${item.cost}',
                      style: TextStyle(
                          color: canAfford ? Colors.white : c.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
