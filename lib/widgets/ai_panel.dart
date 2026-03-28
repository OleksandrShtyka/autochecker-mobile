import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../services/health_service.dart';
import '../services/spotify_service.dart';
import '../theme.dart';

class AiPanel extends StatefulWidget {
  final VoidCallback onClose;
  const AiPanel({super.key, required this.onClose});

  @override
  State<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<AiPanel> {
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();

  final List<_Msg> _messages = [];
  bool _loading = false;
  bool _contextLoaded = false;
  String? _contextString;

  // Voice
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _sttListening = false;

  @override
  void initState() {
    super.initState();
    _initStt();
    _loadContext();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    _stt.stop();
    super.dispose();
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(onError: (_) {});
    if (mounted) setState(() {});
  }

  // ── Context: fetch user data and build a context string for AI ────────────
  Future<void> _loadContext() async {
    try {
      final sessions = await ApiService.instance.getSessions();
      final suppData = await ApiService.instance.getSupplements();
      final roi      = await ApiService.instance.getRoi();

      final sb = StringBuffer('Current user fitness data:\n');
      if (roi != null) {
        sb.writeln('- Sessions this month: ${roi['sessionsCount']}');
        sb.writeln('- Monthly gym cost: \$${roi['monthlyCost']}');
        sb.writeln('- Cost per session: \$${(roi['costPerSession'] as num?)?.toStringAsFixed(2)}');
      }
      final supps = (suppData['supplements'] as List?) ?? [];
      if (supps.isNotEmpty) {
        sb.writeln('- Supplements: ${supps.map((s) => '${s['name']} ${s['dose']}').join(', ')}');
      }
      final recent = sessions.take(8);
      if (recent.isNotEmpty) {
        sb.writeln('- Recent sessions:');
        for (final s in recent) {
          sb.writeln('  • ${s['workoutType'] ?? '?'} — ${s['durationMin'] ?? 0}min — ${s['volumeKg'] ?? 0}kg');
        }
      }
      // Health context
      final health = HealthService.instance.snapshot.value;
      if (health != null) {
        sb.writeln('- Steps today: ${health.steps}');
        if (health.totalCalories > 0) {
          sb.writeln('- Calories burned today: ${health.totalCalories.round()} kcal');
        }
        if (health.heartRateAvg != null) {
          sb.writeln('- Avg heart rate (last 6h): ${health.heartRateAvg!.round()} bpm');
        }
      }

      // Spotify context
      final track = SpotifyService.instance.currentTrack.value;
      if (track != null) {
        sb.writeln(
          '- Currently playing on Spotify: "${track.title}" by ${track.artist} '
          '(${track.isPlaying ? "playing" : "paused"})',
        );
      }

      if (mounted) {
        setState(() {
          _contextString = sb.toString();
          _contextLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _contextLoaded = true);
    }
  }

  // ── Send message ──────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    if (_sttListening) {
      _stt.stop();
      setState(() => _sttListening = false);
    }

    _inputCtrl.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', content: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();
      final reply = await ApiService.instance.sendAiMessage(
        history,
        context: _contextString,
      );
      if (mounted) setState(() => _messages.add(_Msg(role: 'assistant', content: reply)));
    } catch (e) {
      String err = 'Failed to get a response.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) err = data['message'] as String;
      }
      if (mounted) setState(() => _messages.add(_Msg(role: 'error', content: err)));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Voice input ───────────────────────────────────────────────────────────
  Future<void> _toggleVoice() async {
    if (!_sttAvailable) return;
    if (_sttListening) {
      await _stt.stop();
      setState(() => _sttListening = false);
    } else {
      setState(() => _sttListening = true);
      await _stt.listen(
        onResult: (result) {
          setState(() => _inputCtrl.text = result.recognizedWords);
          if (result.finalResult) {
            setState(() => _sttListening = false);
          }
        },
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHandle(),
            if (_contextLoaded && _contextString != null)
              _buildContextBanner(),
            Expanded(
              child: _messages.isEmpty ? _buildEmpty() : _buildMessages(),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          // Drag handle
          Expanded(
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, size: 14, color: teal),
          const SizedBox(width: 6),
          Text(
            t('ai_context_loaded'),
            style: const TextStyle(color: teal, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal, blue]),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              t('helper_ai'),
              style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              t('ai_empty_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTyping();
        return _buildMessage(_messages[i]);
      },
    );
  }

  Widget _buildMessage(_Msg msg) {
    final isUser  = msg.role == 'user';
    final isError = msg.role == 'error';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal]),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isUser
                    ? teal
                    : isError
                        ? const Color(0xFF7F1D1D)
                        : surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: isUser ? null : Border.all(color: borderColor),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : isError
                          ? const Color(0xFFFCA5A5)
                          : textPrimary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal]),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: const Text('...', style: TextStyle(color: textMuted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Mic button
            if (_sttAvailable)
              GestureDetector(
                onTap: _toggleVoice,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _sttListening
                        ? const Color(0xFFEF4444).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _sttListening ? const Color(0xFFEF4444) : borderColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _sttListening ? Icons.mic : Icons.mic_none_outlined,
                    size: 18,
                    color: _sttListening ? const Color(0xFFEF4444) : textMuted,
                  ),
                ),
              ),
            if (_sttAvailable) const SizedBox(width: 6),

            // Text input
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: t('ai_hint'),
                  hintStyle: const TextStyle(color: textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                ),
                style: const TextStyle(color: textPrimary, fontSize: 14),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),

            // Send button
            GestureDetector(
              onTap: _loading ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _loading ? borderColor : teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String role;
  final String content;
  _Msg({required this.role, required this.content});
}
