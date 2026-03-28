import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/api_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  WebViewController? _ctrl;
  bool _loading = true;
  bool _success = false;

  static const _pricingUrl = 'https://autochecker-site.vercel.app/pricing';
  static const _host = 'autochecker-site.vercel.app';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Inject session cookie so the server recognises the user
    final cookie = await ApiService.instance.getSessionCookie();

    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF060F1A))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _loading = true);
          // Intercept PayPal return early (before page fully loads)
          if (url.contains('payment=success') && !_success) {
            _success = true;
            _handleSuccess();
          }
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _loading = false);
          if (url.contains('payment=success') && !_success) {
            _success = true;
            _handleSuccess();
          }
        },
        onNavigationRequest: (req) {
          if (req.url.contains('payment=success') && !_success) {
            _success = true;
            _handleSuccess();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));

    if (cookie != null) {
      await ctrl.runJavaScript(
        'document.cookie = "$cookie; path=/; domain=$_host";',
      );

      await WebViewCookieManager().setCookie(
        WebViewCookie(
          name: 'autochecker_session',
          value: cookie.replaceFirst('autochecker_session=', ''),
          domain: _host,
          path: '/',
        ),
      );
    }

    await ctrl.loadRequest(Uri.parse(_pricingUrl));

    if (mounted) setState(() => _ctrl = ctrl);
  }

  Future<void> _handleSuccess() async {
    await SubscriptionService.instance.refresh();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060F1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Premium',
          style: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (_ctrl != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: textMuted, size: 20),
              onPressed: () => _ctrl!.reload(),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_ctrl != null) WebViewWidget(controller: _ctrl!),
          if (_loading || _ctrl == null)
            const Center(
              child: CircularProgressIndicator(color: teal, strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
