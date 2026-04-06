import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// Result of a Samsung Account OAuth sign-in.
class SamsungOAuthResult {
  final String email;
  final String? displayName;
  final String accessToken;

  const SamsungOAuthResult({
    required this.email,
    this.displayName,
    required this.accessToken,
  });
}

/// Presents Samsung Account OAuth 2.0 sign-in in an in-app WebView.
/// Returns [SamsungOAuthResult] on success, or null if cancelled.
class SamsungAuthWebView extends StatefulWidget {
  const SamsungAuthWebView({super.key});

  static Future<SamsungOAuthResult?> show(BuildContext context) {
    return Navigator.of(context).push<SamsungOAuthResult?>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => const SamsungAuthWebView(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  State<SamsungAuthWebView> createState() => _SamsungAuthWebViewState();
}

class _SamsungAuthWebViewState extends State<SamsungAuthWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  bool _exchanging = false;

  // ── Samsung OAuth constants ──────────────────────────────────────────────
  // Register your app at https://developer.samsung.com/samsung-account
  // Set your redirect_uri in Samsung Developer Portal to: autochecker://samsung-auth
  static const _clientId = 'YOUR_SAMSUNG_CLIENT_ID';
  static const _clientSecret = 'YOUR_SAMSUNG_CLIENT_SECRET';
  static const _redirectUri = 'autochecker://samsung-auth';
  static const _scope = 'openid email profile';
  static const _authorizeUrl =
      'https://account.samsung.com/accounts/v1/oauth2/authorize';
  static const _tokenUrl =
      'https://account.samsung.com/accounts/v1/oauth2/token';
  static const _userInfoUrl =
      'https://account.samsung.com/accounts/v1/oidc/userinfo';

  late final String _state;

  @override
  void initState() {
    super.initState();
    _state = _randomState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (e) =>
              setState(() => _error = 'Load error: ${e.description}'),
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(_buildAuthUrl()));
  }

  String _randomState() {
    final rng = Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  String _buildAuthUrl() {
    return '$_authorizeUrl'
        '?response_type=code'
        '&client_id=${Uri.encodeComponent(_clientId)}'
        '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
        '&scope=${Uri.encodeComponent(_scope)}'
        '&state=${Uri.encodeComponent(_state)}';
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;
    if (url.startsWith(_redirectUri)) {
      _handleCallback(url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _handleCallback(String url) async {
    if (_exchanging) return;
    setState(() => _exchanging = true);

    // Replace custom scheme with a dummy https so Uri.parse works
    final uri = Uri.parse(
      url.replaceFirst('autochecker://', 'https://autochecker.dummy/'),
    );
    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      if (mounted) Navigator.of(context).pop(null);
      return;
    }
    if (code == null || returnedState != _state) {
      setState(() {
        _error = 'Invalid auth response.';
        _exchanging = false;
      });
      return;
    }

    try {
      final result = await SamsungOAuthClient.exchangeCode(
        code: code,
        clientId: _clientId,
        clientSecret: _clientSecret,
        redirectUri: _redirectUri,
        tokenUrl: _tokenUrl,
        userInfoUrl: _userInfoUrl,
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      setState(() {
        _error = 'Sign-in failed: $e';
        _exchanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildHeader(c),
                Expanded(child: _buildBody(c)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1428A0).withValues(alpha: 0.15),
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: c.textMuted, size: 22),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1428A0),
            ),
            child: const Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sign in with Samsung',
              style: TextStyle(
                color: c.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_exchanging) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Verifying your Samsung Account…',
              style: TextStyle(color: c.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: c.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() => _error = null);
                  _controller.loadRequest(Uri.parse(_buildAuthUrl()));
                },
                child: Text('Retry', style: TextStyle(color: c.primary)),
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _controller);
  }
}

// ── Samsung OAuth HTTP client ────────────────────────────────────────────────

class SamsungOAuthClient {
  SamsungOAuthClient._();

  /// Exchange authorization code for access token, then fetch user info.
  static Future<SamsungOAuthResult> exchangeCode({
    required String code,
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required String tokenUrl,
    required String userInfoUrl,
  }) async {
    // 1. Exchange code for access token
    final tokenResp = await _postForm(tokenUrl, {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
    });
    final accessToken = tokenResp['access_token'] as String?;
    if (accessToken == null) throw Exception('No access token returned.');

    // 2. Get user info
    final userInfo = await _getWithBearer(userInfoUrl, accessToken);
    final email = userInfo['email'] as String?;
    if (email == null) {
      throw Exception('Could not retrieve email from Samsung Account.');
    }

    return SamsungOAuthResult(
      email: email,
      displayName: userInfo['name'] as String?,
      accessToken: accessToken,
    );
  }

  static Future<Map<String, dynamic>> _postForm(
    String url,
    Map<String, String> params,
  ) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded');
      req.write(
        params.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}='
                '${Uri.encodeQueryComponent(e.value)}')
            .join('&'),
      );
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> _getWithBearer(
    String url,
    String token,
  ) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}
