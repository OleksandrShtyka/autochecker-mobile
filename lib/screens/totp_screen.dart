import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import 'home_screen.dart';

class TotpScreen extends StatefulWidget {
  const TotpScreen({super.key});

  @override
  State<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends State<TotpScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _error;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.trim();
    if (code.length != 6) return;

    setState(() { _loading = true; _error = null; });

    try {
      await ApiService.instance.verifyTotp(code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (e) {
      String msg = 'Invalid code. Try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) msg = data['message'] as String;
      }
      _controller.clear();
      setState(() { _error = msg; _loading = false; });
      _shakeCtrl.forward(from: 0);
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (c.isDark) const AnimatedBackground(),
          if (!c.isDark)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    teal.withValues(alpha: 0.08),
                    blue.withValues(alpha: 0.05),
                    c.bg,
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: CupertinoBackButton(color: c.text),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          // Shield icon
                          _buildIcon(c),
                          const SizedBox(height: 28),

                          Text(
                            'Two-Factor Auth',
                            style: TextStyle(
                              color: c.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 6-digit code\nfrom your authenticator app',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: c.muted,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 44),

                          // OTP boxes
                          AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(_shakeAnim.value, 0),
                              child: child,
                            ),
                            child: _OtpBoxes(
                              controller: _controller,
                              focusNode: _focusNode,
                              hasError: _error != null,
                              onCompleted: _verify,
                            ),
                          ),

                          // Error
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: _error != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 15,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 36),

                          // Verify button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: _loading
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: teal, strokeWidth: 2),
                                  )
                                : _GlassButton(
                                    label: 'Verify',
                                    onTap: _verify,
                                    c: c,
                                  ),
                          ),
                        ],
                      ),
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

  Widget _buildIcon(AppColors c) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A7B72), teal, blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: teal.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: -6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}

// ── OTP Boxes ─────────────────────────────────────────────────────────────────

class _OtpBoxes extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final VoidCallback onCompleted;

  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onCompleted,
  });

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    setState(() {});
    if (widget.controller.text.length == 6) {
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final code = widget.controller.text;

    return GestureDetector(
      onTap: () => widget.focusNode.requestFocus(),
      child: Stack(
        children: [
          // Hidden text field
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
          ),
          // Visible boxes overlay
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < code.length;
                final active = i == code.length && widget.focusNode.hasFocus;
                final digit = filled ? code[i] : '';
                final hasError = widget.hasError;

                Color borderColor;
                Color bgFill;
                if (hasError) {
                  borderColor = const Color(0xFFEF4444);
                  bgFill = const Color(0xFFEF4444).withValues(alpha: 0.08);
                } else if (active) {
                  borderColor = teal;
                  bgFill = teal.withValues(alpha: 0.06);
                } else if (filled) {
                  borderColor = teal.withValues(alpha: 0.5);
                  bgFill = teal.withValues(alpha: 0.06);
                } else {
                  borderColor = c.border;
                  bgFill = c.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bgFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: borderColor,
                      width: active || hasError ? 2.0 : 1.5,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: teal.withValues(alpha: 0.2),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: digit.isNotEmpty
                      ? Text(
                          digit,
                          style: TextStyle(
                            color: hasError
                                ? const Color(0xFFEF4444)
                                : c.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : active
                          ? _BlinkingCursor(color: teal)
                          : null,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 22,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ── Glass Button ──────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppColors c;

  const _GlassButton({required this.label, required this.onTap, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A7B72), teal, Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: teal.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Cupertino back button ─────────────────────────────────────────────────────

class CupertinoBackButton extends StatelessWidget {
  final Color color;
  const CupertinoBackButton({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left_rounded, color: color, size: 28),
            Text('Back',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
