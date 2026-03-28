import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Monitors network connectivity by pinging a reliable host.
/// Uses [ValueNotifier<bool>] so UI can reactively rebuild.
class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  Timer? _timer;

  void startMonitoring() {
    _check();
    _timer ??= Timer.periodic(const Duration(seconds: 8), (_) => _check());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (isOnline.value != online) isOnline.value = online;
    } catch (_) {
      if (isOnline.value) isOnline.value = false;
    }
  }
}
