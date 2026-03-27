import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'api_service.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const String _taskName = 'ai_workout_analysis';
const String _keyEnabled = 'ai_analysis_enabled';
const String _keyFrequency = 'ai_analysis_frequency_days'; // 0 = manual
const String _keyLastRun = 'ai_analysis_last_run_ms';

// ── Notification plugin (shared instance) ────────────────────────────────────

final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notif.initialize(const InitializationSettings(android: android));
  // Android 13+ потребує явного запиту дозволу на сповіщення
  await _notif
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> _showNotification(String title, String body) async {
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'ai_analysis_channel',
      'AI Workout Analysis',
      channelDescription: 'Periodic AI suggestions for your workout program',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    ),
  );
  await _notif.show(42, title, body, details);
}

// ── Background callback (top-level, required by workmanager) ─────────────────

@pragma('vm:entry-point')
void workmanagerCallback() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _taskName) return Future.value(true);
    try {
      await _runAnalysis();
    } catch (_) {}
    return Future.value(true);
  });
}

Future<void> _runAnalysis() async {
  // Fetch recent sessions
  final sessions = await ApiService.instance.getSessions();
  if (sessions.isEmpty) return;

  // Build summary for AI
  final recent = sessions.take(10).toList();
  final summary = recent.map((s) {
    final type = s['workoutType'] ?? 'workout';
    final dur = s['durationMin'] ?? 0;
    final vol = s['volumeKg'] ?? 0;
    return '- $type, ${dur}min, ${vol}kg volume';
  }).join('\n');

  final messages = [
    {
      'role': 'user',
      'content':
          'Here are my last ${recent.length} gym sessions:\n$summary\n\n'
          'Give me one specific, actionable suggestion to improve my workout program. '
          'Be concise — max 2 sentences.',
    }
  ];

  final reply = await ApiService.instance.sendAiMessage(messages);
  if (reply.isNotEmpty) {
    await initNotifications();
    await _showNotification('Workout Tip', reply);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastRun, DateTime.now().millisecondsSinceEpoch);
  }
}

// ── Public service API ────────────────────────────────────────────────────────

class AiAnalysisService {
  AiAnalysisService._();
  static final instance = AiAnalysisService._();

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyEnabled) ?? false;
  }

  /// frequencyDays: 0 = manual only, 1+ = every N days
  Future<int> getFrequencyDays() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyFrequency) ?? 1;
  }

  Future<void> setEnabled(bool val, {int? frequencyDays}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyEnabled, val);
    if (frequencyDays != null) await p.setInt(_keyFrequency, frequencyDays);

    if (val && (frequencyDays ?? await getFrequencyDays()) > 0) {
      await _schedule(frequencyDays ?? await getFrequencyDays());
    } else {
      await Workmanager().cancelByUniqueName(_taskName);
    }
  }

  Future<void> setFrequencyDays(int days) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyFrequency, days);
    if (await isEnabled() && days > 0) {
      await _schedule(days);
    } else if (days == 0) {
      await Workmanager().cancelByUniqueName(_taskName);
    }
  }

  Future<void> _schedule(int days) async {
    await Workmanager().cancelByUniqueName(_taskName);
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: Duration(days: days),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  /// Запустити аналіз зараз (кнопка "Аналізувати зараз")
  Future<void> analyzeNow() async {
    await initNotifications();
    await _runAnalysis();
  }
}
