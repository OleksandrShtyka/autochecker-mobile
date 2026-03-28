import 'dart:ui';
import 'package:flutter/material.dart';

import '../services/lock_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';

class LockScreen extends StatefulWidget {
  final Widget destination;
  const LockScreen({super.key, required this.destination});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _error = false;
  bool _biometricAvailable = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _initBiometric();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    final enabled = await LockService.instance.biometricEnabled();
    final can = await LockService.instance.canUseBiometrics();
    if (mounted) setState(() => _biometricAvailable = enabled && can);
    if (_biometricAvailable) _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final ok = await LockService.instance.authenticateWithBiometrics();
    if (ok && mounted) _unlock();
  }

  void _unlock() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.destination),
    );
  }

  void _addDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = false;
    });
    if (_entered.length == _pinLength) _verify();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    final ok = await LockService.instance.verifyPin(_entered);
    if (ok) {
      _unlock();
    } else {
      setState(() {
        _error = true;
        _entered = '';
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A7B72), teal, blue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter PIN',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: _error
                          ? const Color(0xFFEF4444)
                          : textMuted,
                      fontSize: 13,
                    ),
                    child: Text(
                      _error
                          ? 'Incorrect PIN. Try again.'
                          : 'Enter your 4-digit PIN to continue',
                    ),
                  ),
                  const SizedBox(height: 36),

                  // PIN dots with shake animation
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pinLength, (i) {
                        final filled = i < _entered.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? (_error
                                    ? const Color(0xFFEF4444)
                                    : teal)
                                : Colors.transparent,
                            border: Border.all(
                              color: _error
                                  ? const Color(0xFFEF4444)
                                  : filled
                                      ? teal
                                      : Colors.white.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: filled && !_error
                                ? [
                                    BoxShadow(
                                      color: teal.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: -2,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Numpad
                  SizedBox(
                    width: 280,
                    child: Column(
                      children: [
                        _numRow(['1', '2', '3']),
                        const SizedBox(height: 14),
                        _numRow(['4', '5', '6']),
                        const SizedBox(height: 14),
                        _numRow(['7', '8', '9']),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_biometricAvailable)
                              _numBtn(
                                child: const Icon(Icons.fingerprint,
                                    color: teal, size: 26),
                                onTap: _tryBiometric,
                              )
                            else
                              const SizedBox(width: 76, height: 58),
                            _numBtn(
                                label: '0',
                                onTap: () => _addDigit('0')),
                            _numBtn(
                              child: const Icon(
                                  Icons.backspace_outlined,
                                  color: textMuted,
                                  size: 20),
                              onTap: _backspace,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _numBtn(label: d, onTap: () => _addDigit(d)))
          .toList(),
    );
  }

  Widget _numBtn(
      {String? label, Widget? child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 76,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.11),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.13)),
            ),
            alignment: Alignment.center,
            child: label != null
                ? Text(
                    label,
                    style: const TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}
