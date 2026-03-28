import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SubscriptionStatus {
  final bool isPremium;
  final String? plan;
  final DateTime? expiresAt;

  const SubscriptionStatus({
    required this.isPremium,
    this.plan,
    this.expiresAt,
  });

  bool get isLifetime => plan == 'lifetime';
  bool get isTrial    => plan == 'trial';

  String get planLabel {
    switch (plan) {
      case 'lifetime': return 'Lifetime';
      case 'trial':    return '15-Day Trial';
      case 'monthly':  return '1 Month';
      case '6month':   return '6 Months';
      case '12month':  return '12 Months';
      case '24month':  return '24 Months';
      default:         return 'Free';
    }
  }

  String get expiryLabel {
    if (expiresAt == null) return '';
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Expired';
    if (diff == 1) return 'Expires tomorrow';
    return 'Expires in $diff days';
  }
}

class SubscriptionService {
  SubscriptionService._();
  static final instance = SubscriptionService._();

  final status = ValueNotifier<SubscriptionStatus>(
    const SubscriptionStatus(isPremium: false),
  );

  bool _loaded = false;

  /// Fetch subscription status from backend. Call once after login.
  Future<void> refresh() async {
    try {
      final data = await ApiService.instance.getSubscriptionStatus();
      final isPremium = data['isPremium'] == true;
      final plan = data['plan'] as String?;
      final expiresAtStr = data['expiresAt'] as String?;
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

      status.value = SubscriptionStatus(
        isPremium: isPremium,
        plan: plan,
        expiresAt: expiresAt,
      );
      _loaded = true;
    } catch (_) {
      // Keep current status on network error
    }
  }

  Future<void> ensureLoaded() async {
    if (!_loaded) await refresh();
  }

  bool get isPremium => status.value.isPremium;
}
