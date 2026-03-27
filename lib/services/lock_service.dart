import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LockService {
  LockService._();
  static final LockService instance = LockService._();

  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  static const _keyPin = 'app_pin';
  static const _keyBiometric = 'app_biometric';

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _keyPin);
    return pin != null && pin.isNotEmpty;
  }

  Future<String?> getPin() => _storage.read(key: _keyPin);

  Future<void> setPin(String pin) => _storage.write(key: _keyPin, value: pin);

  Future<void> clearPin() async {
    await _storage.delete(key: _keyPin);
    await _storage.delete(key: _keyBiometric);
  }

  Future<bool> biometricEnabled() async {
    final val = await _storage.read(key: _keyBiometric);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _keyBiometric, value: enabled.toString());

  Future<bool> canUseBiometrics() async {
    try {
      final available = await _auth.canCheckBiometrics;
      final deviceSupported = await _auth.isDeviceSupported();
      return available && deviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock AutoChecker',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyPin(String input) async {
    final stored = await getPin();
    return stored == input;
  }
}
