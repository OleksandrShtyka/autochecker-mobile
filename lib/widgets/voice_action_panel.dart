import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/achievements_service.dart';
import '../services/api_service.dart';
import '../services/bluetooth_service.dart';
import '../services/exp_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

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
    with TickerProviderStateMixin {
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();

  _Phase _phase = _Phase.idle;
  String _transcript = '';
  String _statusMsg = 'Tap the mic and speak';
  String _aiReply = '';
  Map<String, dynamic>? _parsed;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _waveCtrl;

  // Conversation history for multi-turn dialog
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.52);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (_phase == _Phase.speaking && mounted) {
        setState(() => _phase = _Phase.idle);
        _waveCtrl.stop();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    HapticFeedback.mediumImpact();
    final ok = await _speech.initialize(
      onError: (e) => _setStatus('Mic error: ${e.errorMsg}', _Phase.error),
    );
    if (!ok) {
      _setStatus('Microphone unavailable', _Phase.error);
      return;
    }
    setState(() {
      _phase = _Phase.listening;
      _transcript = '';
      _aiReply = '';
      _statusMsg = 'Listening…';
    });
    _pulseCtrl.repeat(reverse: true);

    _speech.listen(
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (_) {},
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );

    await Future.delayed(const Duration(seconds: 25));
    if (_phase == _Phase.listening) await _stopAndProcess();
  }

  Future<void> _stopAndProcess() async {
    await _speech.stop();
    _pulseCtrl.stop();

    if (_transcript.trim().isEmpty) {
      _setStatus('Nothing heard. Try again.', _Phase.idle);
      return;
    }

    _setStatus('Processing…', _Phase.parsing);

    // Add to history
    _history.add({'role': 'user', 'content': _transcript});

    try {
      // Try voice-action parsing first
      final result = await ApiService.instance.voiceAction(_transcript);
      final reply = result['reply'] as String? ??
          result['message'] as String? ??
          'Got it! I\'ll log that for you.';

      // Check if it contains a loggable workout
      final hasWorkout = result['workoutType'] != null ||
          result['exercises'] != null;

      _history.add({'role': 'assistant', 'content': reply});

      if (mounted) {
        setState(() {
          _aiReply = reply;
          if (hasWorkout) {
            _parsed = result;
            _phase = _Phase.confirm;
            _statusMsg = 'Confirm workout';
          } else {
            _phase = _Phase.speaking;
            _statusMsg = 'AI is responding…';
          }
        });
      }

      // Speak the reply
      await _speakReply(reply);

      await AchievementsService.instance.onVoiceAiUsed();
      await ExpService.instance.earn(ExpReward.voiceAi);
    } catch (e) {
      _setStatus('Error: $e', _Phase.error);
    }
  }

  Future<void> _speakReply(String text) async {
    setState(() {
      _phase = _Phase.speaking;
      _statusMsg = 'Responding…';
    });
    _waveCtrl.repeat(reverse: true);
    await _tts.speak(text);
  }

  Future<void> _logSession() async {
    if (_parsed == null) return;
    setState(() {
      _phase = _Phase.saving;
      _statusMsg = 'Saving…';
    });
    try {
      await ApiService.instance.createSession(_parsed!);
      final bt = BluetoothService.instance;
      final batt = bt.batteryLevel.value;
      if (batt != null && batt < 20) _showBatteryWarning();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _setStatus('Save error: $e', _Phase.error);
    }
  }

  void _setStatus(String msg, _Phase phase) {
    if (mounted) setState(() { _statusMsg = msg; _phase = phase; });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPad),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF0D0D1F) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: c.isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: teal.withValues(alpha: c.isDark ? 0.15 : 0.08),
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
              color: c.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Title row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mic_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice AI',
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  Text(_statusMsg,
                      style: TextStyle(color: c.muted, fontSize: 12)),
                ],
              ),
              const Spacer(),
              if (_phase == _Phase.speaking)
                _WaveIndicator(ctrl: _waveCtrl),
            ],
          ),

          const SizedBox(height: 20),

          // Transcript bubble
          if (_transcript.isNotEmpty) ...[
            _ChatBubble(
              text: _transcript,
              isUser: true,
              c: c,
            ),
            const SizedBox(height: 8),
          ],

          // AI reply bubble
          if (_aiReply.isNotEmpty) ...[
            _ChatBubble(
              text: _aiReply,
              isUser: false,
              c: c,
            ),
            const SizedBox(height: 12),
          ],

          // Parsed workout preview
          if (_phase == _Phase.confirm && _parsed != null) ...[
            _buildParsedCard(_parsed!, c),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    'Cancel', c,
                    color: c.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    textColor: c.muted,
                    onTap: () => setState(() {
                      _phase = _Phase.idle;
                      _parsed = null;
                      _transcript = '';
                      _aiReply = '';
                      _statusMsg = 'Tap the mic and speak';
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionBtn(
                    'Log Workout', c,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00E5CC), Color(0xFF4361EE)]),
                    onTap: _logSession,
                  ),
                ),
              ],
            ),
          ] else if (_phase == _Phase.saving) ...[
            const CircularProgressIndicator(color: teal, strokeWidth: 2),
            const SizedBox(height: 8),
          ] else if (_phase != _Phase.confirm) ...[
            // Mic button
            GestureDetector(
              onTap: _phase == _Phase.listening
                  ? _stopAndProcess
                  : (_phase == _Phase.speaking
                      ? () async {
                          await _tts.stop();
                          setState(() {
                            _phase = _Phase.idle;
                            _statusMsg = 'Tap the mic and speak';
                          });
                          _waveCtrl.stop();
                        }
                      : _startListening),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: _phase == _Phase.listening ? _pulse.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _phase == _Phase.listening
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : _phase == _Phase.speaking
                              ? [const Color(0xFF7C3AED), const Color(0xFF4361EE)]
                              : [const Color(0xFF00E5CC), const Color(0xFF4361EE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_phase == _Phase.listening
                                ? Colors.red
                                : _phase == _Phase.speaking
                                    ? const Color(0xFF7C3AED)
                                    : teal)
                            .withValues(alpha: 0.45),
                        blurRadius: 28,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _phase == _Phase.listening
                        ? Icons.stop_rounded
                        : _phase == _Phase.speaking
                            ? Icons.volume_up_rounded
                            : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _phase == _Phase.listening
                  ? 'Tap to stop'
                  : _phase == _Phase.speaking
                      ? 'Tap to stop speaking'
                      : _history.isEmpty
                          ? 'Tap to start'
                          : 'Tap to continue',
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParsedCard(Map<String, dynamic> data, AppColors c) {
    final entries = <Widget>[];
    if (data['workoutType'] != null) {
      entries.add(_parsedRow(Icons.fitness_center_rounded,
          'Type', '${data['workoutType']}', c));
    }
    if (data['durationMin'] != null) {
      entries.add(_parsedRow(Icons.timer_rounded,
          'Duration', '${data['durationMin']} min', c));
    }
    if (data['volumeKg'] != null) {
      entries.add(_parsedRow(Icons.monitor_weight_rounded,
          'Volume', '${data['volumeKg']} kg', c));
    }
    if (data['exercises'] is List) {
      entries.add(_parsedRow(Icons.list_alt_rounded,
          'Exercises', (data['exercises'] as List).join(', '), c));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: c.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recognized workout',
              style: TextStyle(
                  color: teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...entries,
        ],
      ),
    );
  }

  Widget _parsedRow(IconData icon, String label, String value, AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: teal.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: c.muted, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: c.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    AppColors c, {
    Color? color,
    Color? textColor,
    LinearGradient? gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final AppColors c;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (c.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : c.text,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ── Sound wave indicator ──────────────────────────────────────────────────────
class _WaveIndicator extends StatelessWidget {
  final AnimationController ctrl;
  const _WaveIndicator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final t = (ctrl.value + i * 0.25) % 1.0;
            final h = 8.0 + 14.0 * (0.5 + 0.5 * (t * 3.14159).clamp(0, 3.14159));
            return Container(
              width: 3,
              height: h.clamp(8, 22),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

void _showBatteryWarning() {}

enum _Phase { idle, listening, parsing, speaking, confirm, saving, error }
