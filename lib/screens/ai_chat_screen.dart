import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;

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
      final reply = await ApiService.instance.sendAiMessage(history);
      if (mounted) {
        setState(() => _messages.add(_Msg(role: 'assistant', content: reply)));
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal, blue]),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 10),
            const Text('Helper AI'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) return _buildTyping();
                      return _buildMessage(_messages[i]);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal, blue]),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          const Text('Helper AI', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Ask anything about GYM Tracker\nor your fitness data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_Msg msg) {
    final isUser = msg.role == 'user';
    final isError = msg.role == 'error';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal]),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  color: isUser ? Colors.white : isError ? const Color(0xFFFCA5A5) : textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0A7B72), teal]),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: const Text('...', style: TextStyle(color: textMuted, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ask something…',
                  hintStyle: TextStyle(color: textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: const TextStyle(color: textPrimary, fontSize: 14),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _loading ? null : _send,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _loading ? borderColor : teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
