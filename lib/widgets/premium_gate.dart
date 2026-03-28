import 'dart:ui';

import 'package:flutter/material.dart';

import '../screens/payment_screen.dart';
import '../services/subscription_service.dart';
import '../theme.dart';

/// Wraps [child] and shows a beautiful premium paywall if the user doesn't
/// have an active subscription. Re-checks on resume.
class PremiumGate extends StatefulWidget {
  final Widget child;
  final String featureName;
  final String featureDescription;
  final IconData featureIcon;

  const PremiumGate({
    super.key,
    required this.child,
    required this.featureName,
    this.featureDescription = 'Upgrade to Premium to unlock this feature.',
    this.featureIcon = Icons.auto_awesome_rounded,
  });

  @override
  State<PremiumGate> createState() => _PremiumGateState();
}

class _PremiumGateState extends State<PremiumGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await SubscriptionService.instance.ensureLoaded();
    if (mounted) setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Center(
        child: CircularProgressIndicator(color: teal, strokeWidth: 2),
      );
    }

    return ValueListenableBuilder<SubscriptionStatus>(
      valueListenable: SubscriptionService.instance.status,
      builder: (context, status, _) {
        if (status.isPremium) return widget.child;
        return _PremiumPaywall(
          featureName: widget.featureName,
          featureDescription: widget.featureDescription,
          featureIcon: widget.featureIcon,
          onRefresh: () async {
            await SubscriptionService.instance.refresh();
          },
        );
      },
    );
  }
}

class _PremiumPaywall extends StatefulWidget {
  final String featureName;
  final String featureDescription;
  final IconData featureIcon;
  final Future<void> Function() onRefresh;

  const _PremiumPaywall({
    required this.featureName,
    required this.featureDescription,
    required this.featureIcon,
    required this.onRefresh,
  });

  @override
  State<_PremiumPaywall> createState() => _PremiumPaywallState();
}

class _PremiumPaywallState extends State<_PremiumPaywall>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  bool _checking = false;

  static const _highlights = [
    (Icons.psychology_rounded,       'AI Coach',              'Real-time form feedback'),
    (Icons.bar_chart_rounded,        'Advanced ROI',          'Trends & break-even analysis'),
    (Icons.medication_outlined,      'Supplement Forecast',   'Smart destock alerts'),
    (Icons.balance_rounded,          'Muscle Balance Audit',  'Injury risk score'),
    (Icons.headphones_rounded,       'BLE Auto-Session',      'Hands-free workout logging'),
    (Icons.all_inclusive_rounded,    'Unlimited AI',          'No message caps'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _openPricing() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentScreen()),
    );
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    await widget.onRefresh();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred background hint
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    color: const Color(0xFF060F1A).withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),

            // Content
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
              child: Column(
                children: [
                  // ── Icon ─────────────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A7B72), teal, Color(0xFF1B5BA0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: 0.45),
                          blurRadius: 30,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Icon(widget.featureIcon, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ─────────────────────────────────────────────────
                  const Text(
                    'Premium Feature',
                    style: TextStyle(
                      color: teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.featureName,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.featureDescription,
                    style: TextStyle(
                      color: textMuted.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Features grid ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.09)),
                    ),
                    child: Column(
                      children: _highlights
                          .map((h) => _highlightRow(h.$1, h.$2, h.$3))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Pricing chips ─────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _priceChip('15 days', 'FREE', Colors.green),
                      _priceChip('1 month', '\$7.99', teal),
                      _priceChip('6 months', '\$34.99', blue),
                      _priceChip('12 months', '\$49.99', const Color(0xFF7C3AED)),
                      _priceChip('24 months', '\$79.99', const Color(0xFF0EA5E9)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── CTA ───────────────────────────────────────────────────
                  GestureDetector(
                    onTap: _openPricing,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A7B72), teal, Color(0xFF1B5BA0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: -6,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Already paid? refresh
                  GestureDetector(
                    onTap: _checking ? null : _checkStatus,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      alignment: Alignment.center,
                      child: _checking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: teal, strokeWidth: 2),
                            )
                          : Text(
                              'Already subscribed? Tap to refresh',
                              style: TextStyle(
                                color: textMuted.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightRow(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: teal, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(sub,
                    style: const TextStyle(
                        color: textMuted, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: teal, size: 16),
        ],
      ),
    );
  }

  Widget _priceChip(String period, String price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(price,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          Text(period,
              style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
