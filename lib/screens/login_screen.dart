import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api_service.dart';
import '../services/samsung_auth_service.dart';
import '../theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
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
  bool _samsungLoading = false;
  String? _error;
  bool _obscure = true;
  SamsungDeviceInfo? _samsungInfo;

  late AnimationController _entranceCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _logoFade;

  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
    ));
    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    Future.microtask(() async {
      _entranceCtrl.forward();
      final info = await SamsungAuthService.getDeviceInfo();
      if (mounted) setState(() => _samsungInfo = info);
    });
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
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.instance.login(email, pass);
      if (!mounted) return;
      if (result['mfa_required'] == true) {
        Navigator.of(context).pushReplacement(_slideRoute((_) => const TotpScreen()));
      } else {
        Navigator.of(context).pushReplacement(_slideRoute((_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    HapticFeedback.lightImpact();
    setState(() {
      _googleLoading = true;
      _error = null;
    });
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
        Navigator.of(context).pushReplacement(_slideRoute((_) => const TotpScreen()));
      } else {
        Navigator.of(context).pushReplacement(_slideRoute((_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _loginWithSamsung() async {
    final info = _samsungInfo;
    if (info == null || !info.isSamsung) return;

    HapticFeedback.lightImpact();

    // Pre-fill email if detected
    if (info.email != null && info.email!.isNotEmpty) {
      _emailCtrl.text = info.email!;
    }

    // If email is filled and password is empty → focus password
    if (_passCtrl.text.isEmpty) {
      setState(() {
        _error = null;
        _samsungLoading = false;
      });
      // Show snack to inform user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const _SamsungLogoIcon(size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info.email != null
                        ? 'Samsung Account: ${info.email}\nEnter your password to continue.'
                        : 'Enter your email and password.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1428A0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // If both fields are filled → attempt login
    setState(() {
      _samsungLoading = true;
      _error = null;
    });
    try {
      final result =
          await ApiService.instance.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (result['mfa_required'] == true) {
        Navigator.of(context)
            .pushReplacement(_slideRoute((_) => const TotpScreen()));
      } else {
        Navigator.of(context)
            .pushReplacement(_slideRoute((_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _error = _parseError(e));
    } finally {
      if (mounted) setState(() => _samsungLoading = false);
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

  PageRoute _slideRoute(WidgetBuilder builder) => PageRouteBuilder(
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
          // Animated background
          const AnimatedBackground(),

          SafeArea(
            child: Column(
              children: [
                // TOP SECTION — logo area (40%)
                Expanded(
                  flex: 4,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        // Logo icon
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: teal.withValues(alpha: 0.45),
                                blurRadius: 36,
                                spreadRadius: -4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // GYM text with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00E5CC), Color(0xFF4361EE)],
                          ).createShader(bounds),
                          child: const Text(
                            'GYM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2.0,
                              height: 1.0,
                            ),
                          ),
                        ),
                        // TRACKER subtitle
                        Text(
                          'TRACKER',
                          style: TextStyle(
                            color: c.muted,
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM SECTION — card slides up from bottom (60%)
                Expanded(
                  flex: 6,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        border: c.isDark
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              )
                            : null,
                        boxShadow: c.isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 40,
                                  spreadRadius: -8,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Handle
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: c.border,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            Text(
                              'Welcome back',
                              style: TextStyle(
                                color: c.text,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(color: c.muted, fontSize: 14),
                            ),
                            const SizedBox(height: 28),

                            // Google Sign-In button
                            _GoogleButton(
                              loading: _googleLoading,
                              onTap: _loginWithGoogle,
                              c: c,
                            ),

                            // Samsung Account button (only on Samsung devices)
                            if (_samsungInfo?.isSamsung == true) ...[
                              const SizedBox(height: 10),
                              _SamsungButton(
                                loading: _samsungLoading,
                                email: _samsungInfo?.email,
                                onTap: _loginWithSamsung,
                                c: c,
                              ),
                            ],

                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: c.border, thickness: 1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'or',
                                    style: TextStyle(color: c.muted, fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: c.border, thickness: 1),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Email TextField
                            _StyledTextField(
                              controller: _emailCtrl,
                              hint: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              c: c,
                              onSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 12),

                            // Password TextField
                            _StyledTextField(
                              controller: _passCtrl,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              c: c,
                              onSubmitted: (_) => _login(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: c.muted,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),

                            // Error text
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Color(0xFFEF4444), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Sign in button — gradient with SpringButton
                            SpringButton(
                              onTap: _loading ? null : _login,
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: _loading
                                      ? LinearGradient(
                                          colors: [
                                            teal.withValues(alpha: 0.5),
                                            blue.withValues(alpha: 0.5),
                                          ],
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF00E5CC),
                                            Color(0xFF4361EE),
                                          ],
                                        ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: _loading
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: teal.withValues(alpha: 0.40),
                                            blurRadius: 24,
                                            spreadRadius: -4,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                alignment: Alignment.center,
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white),
                                      )
                                    : const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style:
                                      TextStyle(color: c.muted, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).push(
                                      _slideRoute((_) => const RegisterScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      color: teal,
                                      fontSize: 14,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Styled TextField ──────────────────────────────────────────────────────────
class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final AppColors c;
  final void Function(String)? onSubmitted;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.c,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused && c.isDark
              ? [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.20),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          autocorrect: false,
          style: TextStyle(color: c.text, fontSize: 15),
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: c.muted, fontSize: 15),
            prefixIcon: Icon(widget.icon, color: _focused ? teal : c.muted, size: 20),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: c.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: teal, width: 1.5),
            ),
          ),
        ),
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
    return SpringButton(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: c.isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.07),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: loading
            ? Center(
                child: CircularProgressIndicator(
                    color: c.muted, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Google "G" logo via CustomPainter ────────────────────────────────────────
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

// ── Samsung Sign-In Button ────────────────────────────────────────────────────
class _SamsungButton extends StatelessWidget {
  final bool loading;
  final String? email;
  final VoidCallback onTap;
  final AppColors c;

  const _SamsungButton({
    required this.loading,
    required this.onTap,
    required this.c,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    const samsungBlue = Color(0xFF1428A0);
    const samsungBlueDark = Color(0xFF1E3FD4);

    return SpringButton(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [samsungBlue, samsungBlueDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: loading ? samsungBlue.withValues(alpha: 0.5) : null,
          borderRadius: BorderRadius.circular(28),
          boxShadow: loading
              ? null
              : [
                  BoxShadow(
                    color: samsungBlue.withValues(alpha: 0.45),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _SamsungLogoIcon(size: 22),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Continue with Samsung',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (email != null && email!.isNotEmpty)
                        Text(
                          email!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Samsung Logo (S letter) ───────────────────────────────────────────────────
class _SamsungLogoIcon extends StatelessWidget {
  final double size;
  const _SamsungLogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SamsungLogoPainter()),
    );
  }
}

class _SamsungLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round;

    // Draw stylized "S" for Samsung using arcs
    final topArc = Rect.fromLTWH(w * 0.1, h * 0.04, w * 0.8, h * 0.46);
    final bottomArc = Rect.fromLTWH(w * 0.1, h * 0.5, w * 0.8, h * 0.46);

    // Top arc (curves right to left)
    canvas.drawArc(topArc, -3.14, 2.9, false, paint);
    // Bottom arc (curves left to right)
    canvas.drawArc(bottomArc, 0.0, 2.9, false, paint);
  }

  @override
  bool shouldRepaint(_SamsungLogoPainter old) => false;
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
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }

    arc(-1.9, 1.2, const Color(0xFFEA4335)); // red
    arc(-0.7, 1.6, const Color(0xFF4285F4)); // blue
    arc(0.9, 1.3, const Color(0xFF34A853));  // green
    arc(2.2, 1.2, const Color(0xFFFBBC05));  // yellow

    // Blue horizontal arm
    canvas.drawRect(
      Rect.fromLTWH(
        cx - sw * 0.1,
        cy - size.height * 0.13,
        size.width * 0.44,
        size.height * 0.26,
      ),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
