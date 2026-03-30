import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── EXP rewards ───────────────────────────────────────────────────────────────
class ExpReward {
  static const int session       = 50;
  static const int supplement    = 20;
  static const int voiceAi       = 30;
  static const int cvAnalysis    = 40;
  static const int streakDay     = 100;
  static const int aiChat        = 10;
  static const int photoFood     = 25;
}

// ── Level thresholds ──────────────────────────────────────────────────────────
const List<int> _levelThresholds = [
  0, 100, 250, 500, 900, 1500, 2300, 3300, 4600, 6200, 8200,
  10700, 13700, 17200, 21200, 25700, 30700, 36200, 42200, 48700,
];

int expToLevel(int exp) {
  for (int i = _levelThresholds.length - 1; i >= 0; i--) {
    if (exp >= _levelThresholds[i]) return i + 1;
  }
  return 1;
}

int expForNextLevel(int currentExp) {
  final level = expToLevel(currentExp);
  if (level >= _levelThresholds.length) return 0;
  return _levelThresholds[level] - currentExp;
}

double levelProgress(int currentExp) {
  final level = expToLevel(currentExp);
  if (level >= _levelThresholds.length) return 1.0;
  final start = _levelThresholds[level - 1];
  final end   = _levelThresholds[level];
  return (currentExp - start) / (end - start);
}

// ── Service ───────────────────────────────────────────────────────────────────
class ExpService {
  ExpService._();
  static final instance = ExpService._();

  static const _keyExp       = 'exp_total';
  static const _keyStreak    = 'exp_streak_days';
  static const _keyLastDate  = 'exp_last_active_date';
  static const _keyShopItems = 'exp_shop_items';

  final ValueNotifier<int> exp    = ValueNotifier(0);
  final ValueNotifier<int> streak = ValueNotifier(0);

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    exp.value    = p.getInt(_keyExp)    ?? 0;
    streak.value = p.getInt(_keyStreak) ?? 0;
    await _checkStreak(p);
  }

  Future<void> _checkStreak(SharedPreferences p) async {
    final lastDateStr = p.getString(_keyLastDate);
    final today = _dateKey(DateTime.now());
    if (lastDateStr == today) return;

    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDateStr == yesterday) {
      // Продолжаем стрик
      final newStreak = (p.getInt(_keyStreak) ?? 0) + 1;
      await p.setInt(_keyStreak, newStreak);
      streak.value = newStreak;
      if (newStreak > 1) await _addExp(ExpReward.streakDay, p);
    } else if (lastDateStr != null) {
      // Стрик сломан
      await p.setInt(_keyStreak, 1);
      streak.value = 1;
    }
    await p.setString(_keyLastDate, today);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> earn(int amount) async {
    final p = await SharedPreferences.getInstance();
    await _checkStreak(p);
    return await _addExp(amount, p);
  }

  Future<int> _addExp(int amount, SharedPreferences p) async {
    final newExp = (p.getInt(_keyExp) ?? 0) + amount;
    await p.setInt(_keyExp, newExp);
    exp.value = newExp;
    return newExp;
  }

  Future<bool> spend(int amount) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_keyExp) ?? 0;
    if (current < amount) return false;
    final newExp = current - amount;
    await p.setInt(_keyExp, newExp);
    exp.value = newExp;
    return true;
  }

  int get level => expToLevel(exp.value);
  double get progress => levelProgress(exp.value);
  int get expToNext => expForNextLevel(exp.value);

  // ── Shop: purchased items ──────────────────────────────────────────────────
  Future<Set<String>> getPurchasedItems() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_keyShopItems) ?? []).toSet();
  }

  Future<bool> buyItem(String itemId, int cost) async {
    final ok = await spend(cost);
    if (!ok) return false;
    final p = await SharedPreferences.getInstance();
    final items = (p.getStringList(_keyShopItems) ?? [])..add(itemId);
    await p.setStringList(_keyShopItems, items);
    return true;
  }

  Future<bool> hasItem(String itemId) async {
    final items = await getPurchasedItems();
    return items.contains(itemId);
  }
}
