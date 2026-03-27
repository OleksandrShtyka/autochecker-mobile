import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _obscureConfirm = true;

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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Fill in all fields.');
      return;
    }
    if (pass.length < 12) {
      setState(() => _error = 'Password must be at least 12 characters.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiService.instance.register(name, email, pass);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      String msg = 'Registration failed.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'] as String;
        }
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: textMuted, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logo
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A7B72), teal, blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: teal.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: const Text(
                            'AC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'Register to use Fitness Tracker',
                          style: TextStyle(color: textMuted, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 28),

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
                                  controller: _nameCtrl,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                    prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        color: textMuted,
                                        size: 18),
                                  ),
                                  style: const TextStyle(color: textPrimary),
                                ),
                                const SizedBox(height: 12),
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
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  decoration: InputDecoration(
                                    labelText: 'Password (min. 12 chars)',
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
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm password',
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: textMuted,
                                        size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: textMuted,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm),
                                    ),
                                  ),
                                  style: const TextStyle(color: textPrimary),
                                  onSubmitted: (_) => _register(),
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
                                    onPressed: _loading ? null : _register,
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
                                            'Create account',
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

                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Your account works on both the mobile app\nand the AutoChecker web app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textMuted, fontSize: 11),
                        ),
                      ),
                    ],
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
