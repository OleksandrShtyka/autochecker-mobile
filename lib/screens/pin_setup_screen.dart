import 'package:flutter/material.dart';

import '../services/lock_service.dart';
import '../theme.dart';

/// Used both for setting a new PIN and confirming it.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _entered = '';
  String? _first; // first pass stored here
  bool _error = false;

  static const _pinLength = 4;

  void _addDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() { _entered += d; _error = false; });
    if (_entered.length == _pinLength) _next();
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _next() async {
    if (_first == null) {
      setState(() { _first = _entered; _entered = ''; });
    } else {
      if (_entered == _first) {
        await LockService.instance.setPin(_entered);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() { _error = true; _entered = ''; _first = null; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirming = _first != null;
    return Scaffold(
      appBar: AppBar(title: Text(confirming ? 'Confirm PIN' : 'Set PIN')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                confirming ? 'Re-enter your PIN' : 'Choose a 4-digit PIN',
                style: const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _error ? const Color(0xFFEF4444) : textMuted,
                  fontSize: 13,
                ),
                child: Text(_error ? "PINs don't match. Start over." : (confirming ? 'Enter the same PIN again' : 'You will use this to unlock the app')),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? teal : Colors.transparent,
                      border: Border.all(color: filled ? teal : borderColor, width: 2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    _numRow(['1', '2', '3']),
                    const SizedBox(height: 12),
                    _numRow(['4', '5', '6']),
                    const SizedBox(height: 12),
                    _numRow(['7', '8', '9']),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 56),
                        _numBtn(label: '0', onTap: () => _addDigit('0')),
                        _numBtn(
                          child: const Icon(Icons.backspace_outlined, color: textMuted, size: 20),
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
    );
  }

  Widget _numRow(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: digits.map((d) => _numBtn(label: d, onTap: () => _addDigit(d))).toList(),
  );

  Widget _numBtn({String? label, Widget? child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 56,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: label != null
            ? Text(label, style: const TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600))
            : child,
      ),
    );
  }
}
