import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _googleLoading = false;
  String? _error;
  bool _obscure = true;

  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.instance.login(email, pass);
      if (!mounted) return;
      if (result['mfa_required'] == true) {
        Navigator.of(context).pushReplacement(
          _iosRoute((_) => const TotpScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          _iosRoute((_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('Google auth failed.');

      final result = await ApiService.instance.loginWithGoogle(idToken);
      if (!mounted) return;
      if (result['mfa_required'] == true) {
        Navigator.of(context).pushReplacement(_iosRoute((_) => const TotpScreen()));
      } else {
        Navigator.of(context).pushReplacement(_iosRoute((_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) return data['message'] as String;
      if (e.response?.statusCode != null) return 'Server error ${e.response!.statusCode}';
      return 'Network error. Check your connection.';
    }
    return e.toString();
  }

  PageRoute _iosRoute(WidgetBuilder builder) => PageRouteBuilder(
    pageBuilder: (ctx, __, ___) => builder(ctx),
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 380),
  );

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
                    teal.withValues(alpha: 0.07),
                    blue.withValues(alpha: 0.04),
                    c.bg,
                  ],
                ),
              ),
            ),
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
                            width: 72, height: 72,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A7B72), teal, blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: teal.withValues(alpha: 0.4),
                                  blurRadius: 28, spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.fitness_center_rounded,
                                color: Colors.white, size: 36),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text('GYM Tracker',
                            style: TextStyle(
                              color: c.text, fontSize: 28,
                              fontWeight: FontWeight.w800, letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text('Your personal fitness companion',
                            style: TextStyle(color: c.muted, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Google Sign-In button
                        _GoogleButton(
                          loading: _googleLoading,
                          onTap: _loginWithGoogle,
                          c: c,
                        ),

                        const SizedBox(height: 16),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: c.border, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text('or', style: TextStyle(color: c.muted, fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: c.border, thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Email/password card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: c.cardFill,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: c.cardBorder),
                                boxShadow: c.isDark ? null : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email
                                  TextField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    style: TextStyle(color: c.text),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: TextStyle(color: c.muted, fontSize: 13),
                                      prefixIcon: Icon(Icons.email_outlined,
                                          color: c.muted, size: 18),
                                      filled: true,
                                      fillColor: c.inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: c.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: c.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: teal, width: 1.5),
                                      ),
                                    ),
                                    onSubmitted: (_) => _login(),
                                  ),
                                  const SizedBox(height: 12),
                                  // Password
                                  TextField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    style: TextStyle(color: c.text),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(color: c.muted, fontSize: 13),
                                      prefixIcon: Icon(Icons.lock_outline_rounded,
                                          color: c.muted, size: 18),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: c.muted, size: 20,
                                        ),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                      filled: true,
                                      fillColor: c.inputFill,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: c.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide(color: c.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: teal, width: 1.5),
                                      ),
                                    ),
                                    onSubmitted: (_) => _login(),
                                  ),

                                  // Error
                                  if (_error != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                      ),
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color: Color(0xFFEF4444), fontSize: 13)),
                                    ),
                                  ],

                                  const SizedBox(height: 18),

                                  // Sign in button
                                  SizedBox(
                                    height: 52,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: _loading ? null : [
                                          BoxShadow(
                                            color: teal.withValues(alpha: 0.35),
                                            blurRadius: 18, spreadRadius: -4,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: teal,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14)),
                                          padding: EdgeInsets.zero,
                                          elevation: 0,
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 20, height: 20,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text('Sign in',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15)),
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
                            Text("Don't have an account? ",
                                style: TextStyle(color: c.muted, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                _iosRoute((_) => const RegisterScreen()),
                              ),
                              child: const Text('Sign up',
                                style: TextStyle(
                                  color: teal, fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                )),
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

// ── Google Sign-In Button ─────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  final AppColors c;

  const _GoogleButton({
    required this.loading,
    required this.onTap,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.08),
              blurRadius: 16, spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? Center(child: CircularProgressIndicator(color: c.muted, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Simple Google "G" logo using 4-color arcs
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
    final sw = size.width * 0.22;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(rect, start, sweep, false,
          Paint()..color = color..style = PaintingStyle.stroke
                ..strokeWidth = sw..strokeCap = StrokeCap.butt);
    }

    arc(-1.9, 1.2, const Color(0xFFEA4335)); // red
    arc(-0.7, 1.6, const Color(0xFF4285F4)); // blue
    arc( 0.9, 1.3, const Color(0xFF34A853)); // green
    arc( 2.2, 1.2, const Color(0xFFFBBC05)); // yellow

    // Blue horizontal arm of "G"
    canvas.drawRect(
      Rect.fromLTWH(cx - sw * 0.1, cy - size.height * 0.13, size.width * 0.44, size.height * 0.26),
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
