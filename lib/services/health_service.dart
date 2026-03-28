import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class HealthSnapshot {
  final int steps;
  final double activeCalories; // kcal
  final double totalCalories;  // kcal
  final double? heartRateAvg;  // bpm
  final DateTime fetchedAt;

  const HealthSnapshot({
    required this.steps,
    required this.activeCalories,
    required this.totalCalories,
    this.heartRateAvg,
    required this.fetchedAt,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class HealthService {
  HealthService._();
  static final instance = HealthService._();

  final _health = Health();
  bool _configured = false;

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.HEART_RATE,
  ];
  static final _perms = _types.map((_) => HealthDataAccess.READ).toList();

  final ValueNotifier<HealthSnapshot?> snapshot = ValueNotifier(null);

  // ── Internal setup ─────────────────────────────────────────────────────────

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// True if Health Connect is installed on this device.
  Future<bool> get isAvailable async {
    try {
      await _configure();
      return await _health.isHealthConnectAvailable();
    } catch (_) {
      return false;
    }
  }

  /// True if the app already has health read permissions.
  Future<bool> get hasPermissions async {
    try {
      await _configure();
      return await _health.hasPermissions(_types, permissions: _perms) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests Health Connect permissions. Returns true if granted.
  Future<bool> requestPermissions() async {
    try {
      await _configure();
      return await _health.requestAuthorization(_types, permissions: _perms);
    } catch (_) {
      return false;
    }
  }

  /// Fetches today's health data and updates [snapshot].
  Future<void> refresh() async {
    try {
      await _configure();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Steps
      final steps =
          await _health.getTotalStepsInInterval(startOfDay, now) ?? 0;

      // Active calories
      final activePoints = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );
      final activeKcal = activePoints.fold<double>(0, (sum, p) {
        final v = p.value;
        if (v is NumericHealthValue) return sum + v.numericValue.toDouble();
        return sum;
      });

      // Total calories
      final totalPoints = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: now,
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
      );
      final totalKcal = totalPoints.fold<double>(0, (sum, p) {
        final v = p.value;
        if (v is NumericHealthValue) return sum + v.numericValue.toDouble();
        return sum;
      });

      // Heart rate — average of last 6 hours
      final hrStart = now.subtract(const Duration(hours: 6));
      final hrPoints = await _health.getHealthDataFromTypes(
        startTime: hrStart,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );
      double? avgHr;
      if (hrPoints.isNotEmpty) {
        final sum = hrPoints.fold<double>(0, (s, p) {
          final v = p.value;
          if (v is NumericHealthValue) return s + v.numericValue.toDouble();
          return s;
        });
        avgHr = sum / hrPoints.length;
      }

      snapshot.value = HealthSnapshot(
        steps: steps,
        activeCalories: activeKcal,
        totalCalories: totalKcal > 0 ? totalKcal : activeKcal,
        heartRateAvg: avgHr,
        fetchedAt: now,
      );
    } catch (_) {
      // Silently fail — permissions may have been revoked
    }
  }
}
