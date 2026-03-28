import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// Full-screen WebView that handles the Spotify OAuth flow.
/// Pops with the authorization [code] on success, or null on cancel.
class SpotifyAuthScreen extends StatefulWidget {
  final String authUrl;
  const SpotifyAuthScreen({super.key, required this.authUrl});

  @override
  State<SpotifyAuthScreen> createState() => _SpotifyAuthScreenState();
}

class _SpotifyAuthScreenState extends State<SpotifyAuthScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  static const _redirectBase = 'https://autochecker-site.vercel.app/';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(bgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.startsWith(_redirectBase)) {
              final uri = Uri.parse(url);
              final code = uri.queryParameters['code'];
              if (code != null && mounted) {
                Navigator.of(context).pop(code);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: textPrimary,
        title: const Text(
          'Connect Spotify',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}
