import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'totp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    Future.microtask(() => _entranceCtrl.forward());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.instance.login(email, pass);
      if (!mounted) return;
      if (result['mfa_required'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TotpScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      String msg;
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'] as String;
        } else if (e.response?.statusCode != null) {
          msg = 'Server error ${e.response!.statusCode}';
        } else {
          msg = 'DioError [${e.type.name}]: ${e.message}';
        }
      } else {
        msg = e.toString();
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A7B72), teal, blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withValues(alpha: 0.4),
                                  blurRadius: 28,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'GYM Tracker',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'Fitness Tracker',
                            style: TextStyle(color: textMuted, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Glass form card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.11),
                                    Colors.white.withValues(alpha: 0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.13)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined,
                                          color: textMuted, size: 18),
                                    ),
                                    style: const TextStyle(color: textPrimary),
                                    onSubmitted: (_) => _login(),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: textMuted,
                                          size: 18),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: textMuted,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    style: const TextStyle(color: textPrimary),
                                    onSubmitted: (_) => _login(),
                                  ),

                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Sign in button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: _loading
                                          ? null
                                          : [
                                              BoxShadow(
                                                color:
                                                    teal.withValues(alpha: 0.35),
                                                blurRadius: 18,
                                                spreadRadius: -4,
                                              ),
                                            ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15),
                                        elevation: 0,
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Text(
                                              'Sign in',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: textMuted, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: teal,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
