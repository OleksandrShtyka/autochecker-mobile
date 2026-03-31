import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum MealType { breakfast, lunch, dinner, snacks }

extension MealTypeExt on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch:     return 'Lunch';
      case MealType.dinner:    return 'Dinner';
      case MealType.snacks:    return 'Snacks';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast: return '🌅';
      case MealType.lunch:     return '☀️';
      case MealType.dinner:    return '🌙';
      case MealType.snacks:    return '🍎';
    }
  }
}

class NutritionEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double weight;
  final MealType meal;
  final DateTime loggedAt;

  const NutritionEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.weight,
    required this.meal,
    required this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'weight': weight,
    'meal': meal.index,
    'loggedAt': loggedAt.millisecondsSinceEpoch,
  };

  factory NutritionEntry.fromJson(Map<String, dynamic> j) => NutritionEntry(
    id: j['id'] as String,
    name: j['name'] as String,
    calories: (j['calories'] as num).toInt(),
    protein: (j['protein'] as num).toDouble(),
    carbs: (j['carbs'] as num).toDouble(),
    fat: (j['fat'] as num).toDouble(),
    weight: (j['weight'] as num? ?? 0).toDouble(),
    meal: MealType.values[(j['meal'] as int).clamp(0, 3)],
    loggedAt: DateTime.fromMillisecondsSinceEpoch(j['loggedAt'] as int),
  );
}

class NutritionGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const NutritionGoals({
    this.calories = 2000,
    this.protein  = 150,
    this.carbs    = 200,
    this.fat      = 65,
  });

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory NutritionGoals.fromJson(Map<String, dynamic> j) => NutritionGoals(
    calories: (j['calories'] as num?)?.toInt() ?? 2000,
    protein:  (j['protein']  as num?)?.toInt() ?? 150,
    carbs:    (j['carbs']    as num?)?.toInt() ?? 200,
    fat:      (j['fat']      as num?)?.toInt() ?? 65,
  );
}

class WeightEntry {
  final DateTime date;
  final double kg;

  const WeightEntry({required this.date, required this.kg});

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'kg': kg,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
    date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
    kg: (j['kg'] as num).toDouble(),
  );
}

// ── NutritionService ──────────────────────────────────────────────────────────

class NutritionService {
  NutritionService._();
  static final instance = NutritionService._();

  static const _keyEntries = 'nutrition_entries';
  static const _keyGoals   = 'nutrition_goals';
  static const _keyWeight  = 'nutrition_weight';

  final ValueNotifier<List<NutritionEntry>> entries = ValueNotifier([]);
  final ValueNotifier<NutritionGoals> goals =
      ValueNotifier(const NutritionGoals());
  final ValueNotifier<List<WeightEntry>> weightHistory = ValueNotifier([]);

  Future<void> init() async {
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final p = await SharedPreferences.getInstance();

    // Entries
    final raw = p.getString(_keyEntries);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => NutritionEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.value = list;
    }

    // Goals
    final rawGoals = p.getString(_keyGoals);
    if (rawGoals != null) {
      goals.value = NutritionGoals.fromJson(
          jsonDecode(rawGoals) as Map<String, dynamic>);
    }

    // Weight
    final rawW = p.getString(_keyWeight);
    if (rawW != null) {
      final list = (jsonDecode(rawW) as List)
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      weightHistory.value = list;
    }
  }

  // ── Diary ──────────────────────────────────────────────────────────────────

  List<NutritionEntry> entriesForDate(DateTime date) {
    return entries.value
        .where((e) =>
            e.loggedAt.year  == date.year &&
            e.loggedAt.month == date.month &&
            e.loggedAt.day   == date.day)
        .toList();
  }

  Future<void> addEntry(NutritionEntry entry) async {
    final list = [...entries.value, entry];
    entries.value = list;
    await _saveEntries(list);
  }

  Future<void> removeEntry(String id) async {
    final list = entries.value.where((e) => e.id != id).toList();
    entries.value = list;
    await _saveEntries(list);
  }

  Future<void> _saveEntries(List<NutritionEntry> list) async {
    final p = await SharedPreferences.getInstance();
    // Keep only last 90 days to avoid bloat
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final pruned = list.where((e) => e.loggedAt.isAfter(cutoff)).toList();
    await p.setString(_keyEntries, jsonEncode(pruned.map((e) => e.toJson()).toList()));
  }

  // ── Totals for a day ────────────────────────────────────────────────────────

  ({int cal, double protein, double carbs, double fat}) totalsForDate(DateTime date) {
    final day = entriesForDate(date);
    return (
      cal:     day.fold(0,   (s, e) => s + e.calories),
      protein: day.fold(0.0, (s, e) => s + e.protein),
      carbs:   day.fold(0.0, (s, e) => s + e.carbs),
      fat:     day.fold(0.0, (s, e) => s + e.fat),
    );
  }

  // ── Goals ──────────────────────────────────────────────────────────────────

  Future<void> setGoals(NutritionGoals g) async {
    goals.value = g;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyGoals, jsonEncode(g.toJson()));
  }

  // ── Weight ─────────────────────────────────────────────────────────────────

  Future<void> logWeight(double kg) async {
    final entry = WeightEntry(date: DateTime.now(), kg: kg);
    final list = [...weightHistory.value, entry];
    weightHistory.value = list;
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _keyWeight, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  double? get latestWeight {
    if (weightHistory.value.isEmpty) return null;
    return weightHistory.value.last.kg;
  }
}
