import 'package:flutter/services.dart';

class SamsungDeviceInfo {
  final bool isSamsung;
  final String? email;
  final String? model;

  const SamsungDeviceInfo({
    required this.isSamsung,
    this.email,
    this.model,
  });
}

class SamsungAuthService {
  static const _channel = MethodChannel('autochecker/device');

  static SamsungDeviceInfo? _cached;

  static Future<SamsungDeviceInfo> getDeviceInfo() async {
    if (_cached != null) return _cached!;
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceInfo');
      _cached = SamsungDeviceInfo(
        isSamsung: result?['isSamsung'] as bool? ?? false,
        email: result?['samsungEmail'] as String?,
        model: result?['model'] as String?,
      );
    } catch (_) {
      _cached = const SamsungDeviceInfo(isSamsung: false);
    }
    return _cached!;
  }
}
