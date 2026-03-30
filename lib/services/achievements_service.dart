import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Achievement model ─────────────────────────────────────────────────────────
class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int expReward;
  final AchievementRarity rarity;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.expReward,
    this.rarity = AchievementRarity.common,
  });
}

enum AchievementRarity { common, rare, epic, legendary }

// ── All achievements ──────────────────────────────────────────────────────────
const List<Achievement> kAllAchievements = [
  // Стартовые (1 при регистрации)
  Achievement(
    id: 'welcome',
    title: 'Welcome!',
    description: 'Joined GYM Tracker',
    emoji: '🎉',
    expReward: 50,
    rarity: AchievementRarity.common,
  ),

  // Сессии
  Achievement(
    id: 'first_session',
    title: 'First Rep',
    description: 'Log your first workout session',
    emoji: '💪',
    expReward: 100,
    rarity: AchievementRarity.common,
  ),
  Achievement(
    id: 'sessions_10',
    title: 'Iron Will',
    description: 'Log 10 workout sessions',
    emoji: '🔥',
    expReward: 200,
    rarity: AchievementRarity.rare,
  ),
  Achievement(
    id: 'sessions_50',
    title: 'Grind Mode',
    description: 'Log 50 workout sessions',
    emoji: '⚡',
    expReward: 500,
    rarity: AchievementRarity.epic,
  ),
  Achievement(
    id: 'sessions_100',
    title: 'Legend',
    description: 'Log 100 workout sessions',
    emoji: '🏆',
    expReward: 1000,
    rarity: AchievementRarity.legendary,
  ),

  // Стрик
  Achievement(
    id: 'streak_3',
    title: 'Hat Trick',
    description: '3-day activity streak',
    emoji: '🎯',
    expReward: 150,
    rarity: AchievementRarity.common,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Week Warrior',
    description: '7-day activity streak',
    emoji: '📅',
    expReward: 300,
    rarity: AchievementRarity.rare,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Unstoppable',
    description: '30-day activity streak',
    emoji: '🌟',
    expReward: 1000,
    rarity: AchievementRarity.legendary,
  ),

  // Supplements
  Achievement(
    id: 'first_supplement',
    title: 'Stacked',
    description: 'Add your first supplement',
    emoji: '💊',
    expReward: 75,
    rarity: AchievementRarity.common,
  ),
  Achievement(
    id: 'supplements_5',
    title: 'Supplement King',
    description: 'Track 5 different supplements',
    emoji: '🧪',
    expReward: 200,
    rarity: AchievementRarity.rare,
  ),

  // AI фичи
  Achievement(
    id: 'first_voice',
    title: 'Voice Activated',
    description: 'Use the voice AI for the first time',
    emoji: '🎤',
    expReward: 100,
    rarity: AchievementRarity.common,
  ),
  Achievement(
    id: 'first_cv',
    title: 'Form Check',
    description: 'Analyze workout technique with AI camera',
    emoji: '📸',
    expReward: 150,
    rarity: AchievementRarity.rare,
  ),
  Achievement(
    id: 'ai_chat_10',
    title: 'AI Buddy',
    description: 'Send 10 messages to the AI coach',
    emoji: '🤖',
    expReward: 200,
    rarity: AchievementRarity.rare,
  ),

  // Уровни EXP
  Achievement(
    id: 'level_5',
    title: 'Rising Star',
    description: 'Reach level 5',
    emoji: '⭐',
    expReward: 300,
    rarity: AchievementRarity.rare,
  ),
  Achievement(
    id: 'level_10',
    title: 'Elite',
    description: 'Reach level 10',
    emoji: '💎',
    expReward: 500,
    rarity: AchievementRarity.epic,
  ),

  // Возраст аккаунта
  Achievement(
    id: 'veteran_30',
    title: 'Veteran',
    description: 'Use the app for 30 days',
    emoji: '🎖️',
    expReward: 400,
    rarity: AchievementRarity.rare,
  ),
  Achievement(
    id: 'veteran_90',
    title: 'Hall of Fame',
    description: 'Use the app for 90 days',
    emoji: '👑',
    expReward: 1000,
    rarity: AchievementRarity.legendary,
  ),

  // Spotify
  Achievement(
    id: 'spotify_ai',
    title: 'DJ AI',
    description: 'Create an AI-generated playlist',
    emoji: '🎵',
    expReward: 150,
    rarity: AchievementRarity.rare,
  ),

  // Магазин
  Achievement(
    id: 'first_purchase',
    title: 'Big Spender',
    description: 'Buy your first item from the shop',
    emoji: '🛍️',
    expReward: 100,
    rarity: AchievementRarity.common,
  ),
];

// ── Service ───────────────────────────────────────────────────────────────────
class AchievementsService {
  AchievementsService._();
  static final instance = AchievementsService._();

  static const _keyUnlocked   = 'achievements_unlocked';
  static const _keyInstallDay = 'achievements_install_day';
  static const _keySessions   = 'achievements_session_count';
  static const _keySupplements= 'achievements_supplement_count';
  static const _keyVoiceUses  = 'achievements_voice_count';
  static const _keyAiChats    = 'achievements_ai_chat_count';

  final ValueNotifier<Set<String>> unlocked = ValueNotifier({});

  // Callback вызывается когда разблокируется новое достижение
  void Function(Achievement)? onUnlock;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    unlocked.value = (p.getStringList(_keyUnlocked) ?? ['welcome']).toSet();

    // Сохраняем дату установки если нет
    if (!p.containsKey(_keyInstallDay)) {
      await p.setInt(_keyInstallDay, DateTime.now().millisecondsSinceEpoch);
    }
  }

  bool isUnlocked(String id) => unlocked.value.contains(id);

  Future<void> unlock(String id) async {
    if (unlocked.value.contains(id)) return;
    final achievement = kAllAchievements.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Unknown achievement: $id'),
    );
    final p = await SharedPreferences.getInstance();
    final newSet = {...unlocked.value, id};
    await p.setStringList(_keyUnlocked, newSet.toList());
    unlocked.value = newSet;
    onUnlock?.call(achievement);
  }

  // ── Триггеры ─────────────────────────────────────────────────────────────

  Future<void> onSessionLogged() async {
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt(_keySessions) ?? 0) + 1;
    await p.setInt(_keySessions, count);

    await unlock('first_session');
    if (count >= 10)  await unlock('sessions_10');
    if (count >= 50)  await unlock('sessions_50');
    if (count >= 100) await unlock('sessions_100');
  }

  Future<void> onSupplementAdded() async {
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt(_keySupplements) ?? 0) + 1;
    await p.setInt(_keySupplements, count);

    await unlock('first_supplement');
    if (count >= 5) await unlock('supplements_5');
  }

  Future<void> onVoiceAiUsed() async {
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt(_keyVoiceUses) ?? 0) + 1;
    await p.setInt(_keyVoiceUses, count);
    await unlock('first_voice');
  }

  Future<void> onCvAnalysisUsed() async {
    await unlock('first_cv');
  }

  Future<void> onAiChatMessage() async {
    final p = await SharedPreferences.getInstance();
    final count = (p.getInt(_keyAiChats) ?? 0) + 1;
    await p.setInt(_keyAiChats, count);
    if (count >= 10) await unlock('ai_chat_10');
  }

  Future<void> onSpotifyAiUsed() async {
    await unlock('spotify_ai');
  }

  Future<void> onShopPurchase() async {
    await unlock('first_purchase');
  }

  Future<void> onStreakUpdate(int streakDays) async {
    if (streakDays >= 3)  await unlock('streak_3');
    if (streakDays >= 7)  await unlock('streak_7');
    if (streakDays >= 30) await unlock('streak_30');
  }

  Future<void> onLevelUp(int level) async {
    if (level >= 5)  await unlock('level_5');
    if (level >= 10) await unlock('level_10');
  }

  Future<void> checkAccountAge() async {
    final p = await SharedPreferences.getInstance();
    final installMs = p.getInt(_keyInstallDay) ?? DateTime.now().millisecondsSinceEpoch;
    final daysUsed = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(installMs))
        .inDays;
    if (daysUsed >= 30) await unlock('veteran_30');
    if (daysUsed >= 90) await unlock('veteran_90');
  }
}
