import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/api_service.dart';
import '../services/bluetooth_service.dart';
import '../theme.dart';

/// Shows a bottom sheet for voice-to-action workout logging.
Future<bool> showVoiceActionPanel(BuildContext context) async {
  final logged = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VoiceActionSheet(),
  );
  return logged == true;
}

class _VoiceActionSheet extends StatefulWidget {
  const _VoiceActionSheet();

  @override
  State<_VoiceActionSheet> createState() => _VoiceActionSheetState();
}

class _VoiceActionSheetState extends State<_VoiceActionSheet>
    with SingleTickerProviderStateMixin {
  final _speech = stt.SpeechToText();

  _Phase _phase = _Phase.idle;
  String _transcript = '';
  String _statusMsg = 'Натисни мікрофон і говори';
  Map<String, dynamic>? _parsed;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseCtrl.stop();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    final ok = await _speech.initialize(
      onError: (e) => _setStatus('Помилка: ${e.errorMsg}', _Phase.error),
    );
    if (!ok) {
      _setStatus('Мікрофон недоступний', _Phase.error);
      return;
    }
    setState(() {
      _phase = _Phase.listening;
      _transcript = '';
      _statusMsg = 'Слухаю…';
    });
    _pulseCtrl.repeat(reverse: true);

    _speech.listen(
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      localeId: 'uk_UA',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (_) {},
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );

    // After speech stops
    await Future.delayed(const Duration(seconds: 25));
    if (_phase == _Phase.listening) await _stopAndParse();
  }

  Future<void> _stopAndParse() async {
    await _speech.stop();
    _pulseCtrl.stop();
    if (_transcript.trim().isEmpty) {
      _setStatus('Нічого не почуто. Спробуй ще раз.', _Phase.idle);
      return;
    }
    _setStatus('Обробляю…', _Phase.parsing);
    try {
      final result = await ApiService.instance.voiceAction(_transcript);
      setState(() {
        _parsed = result;
        _phase = _Phase.confirm;
        _statusMsg = 'Підтвердь тренування';
      });
    } catch (e) {
      _setStatus('Помилка: $e', _Phase.error);
    }
  }

  Future<void> _logSession() async {
    if (_parsed == null) return;
    setState(() {
      _phase = _Phase.saving;
      _statusMsg = 'Зберігаю…';
    });
    try {
      await ApiService.instance.createSession(_parsed!);
      // Battery guard
      final bt = BluetoothService.instance;
      final batt = bt.batteryLevel.value;
      if (batt != null && batt < 20) {
        // Fire local notification via flutter_local_notifications
        _triggerBatteryNotification();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _setStatus('Помилка збереження: $e', _Phase.error);
    }
  }

  void _triggerBatteryNotification() {
    // Notification is best-effort here; WorkManager handles the background case.
    // We call the helper that's set up in main.dart
    _showBatteryWarning();
  }

  void _setStatus(String msg, _Phase phase) {
    if (mounted) setState(() { _statusMsg = msg; _phase = phase; });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Голосове логування',
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusMsg,
            style: TextStyle(color: textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Transcript
          if (_transcript.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                _transcript,
                style: const TextStyle(color: textPrimary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Parsed preview
          if (_phase == _Phase.confirm && _parsed != null) ...[
            _buildParsedCard(_parsed!),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    'Скасувати',
                    Colors.white.withValues(alpha: 0.08),
                    () => setState(() { _phase = _Phase.idle; _parsed = null; _transcript = ''; _statusMsg = 'Натисни мікрофон і говори'; }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionBtn('Зберегти', teal, _logSession),
                ),
              ],
            ),
          ] else if (_phase == _Phase.saving) ...[
            const CircularProgressIndicator(color: teal, strokeWidth: 2),
          ] else ...[
            // Mic button
            GestureDetector(
              onTap: _phase == _Phase.listening ? _stopAndParse : _startListening,
              child: ScaleTransition(
                scale: _phase == _Phase.listening ? _pulse : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _phase == _Phase.listening
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF0A7B72), teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_phase == _Phase.listening ? Colors.red : teal)
                            .withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _phase == _Phase.listening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _phase == _Phase.listening ? 'Натисни щоб зупинити' : 'Натисни щоб почати',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedCard(Map<String, dynamic> data) {
    final entries = <Widget>[];
    final workoutType = data['workoutType'] as String?;
    final duration = data['durationMin'];
    final volume = data['volumeKg'];
    final exercises = data['exercises'] as List?;

    if (workoutType != null) {
      entries.add(_parsedRow(Icons.fitness_center_rounded, 'Тип', workoutType));
    }
    if (duration != null) {
      entries.add(_parsedRow(Icons.timer_rounded, 'Тривалість', '$duration хв'));
    }
    if (volume != null) {
      entries.add(_parsedRow(Icons.monitor_weight_rounded, "Об'єм", '$volume кг'));
    }
    if (exercises != null && exercises.isNotEmpty) {
      entries.add(_parsedRow(Icons.list_alt_rounded, 'Вправи', exercises.join(', ')));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Розпізнане тренування',
            style: TextStyle(
              color: teal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...entries,
        ],
      ),
    );
  }

  Widget _parsedRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: teal.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: textMuted, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// Keep this a no-op stub — real notification is wired in main.dart
void _showBatteryWarning() {}

enum _Phase { idle, listening, parsing, confirm, saving, error }
