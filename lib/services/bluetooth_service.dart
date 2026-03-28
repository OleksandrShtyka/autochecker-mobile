import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  BluetoothService._();
  static final instance = BluetoothService._();

  // GATT Battery Service
  static const _batteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
  static const _batteryCharUuid    = '00002a19-0000-1000-8000-00805f9b34fb';

  // Name fragments that match Gelius GP-TWS011
  static const _nameFragments = ['gelius', 'tws011', 'gp-tws', 'gp_tws'];

  final batteryLevel = ValueNotifier<int?>(null);
  final isConnected  = ValueNotifier<bool>(false);
  final deviceName   = ValueNotifier<String?>(null);

  BluetoothDevice?                        _device;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<ScanResult>>?   _scanSub;
  Timer?                                  _scanTimer;
  bool                                    _active = false;
  bool                                    _connecting = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Requests runtime BT permissions (Android 12+), then starts scanning.
  Future<void> requestPermissionsAndScan() async {
    // flutter_blue_plus handles runtime permission requests via startScan
    // when androidCheckLocationServices is false.
    // We just wait for adapter to be on, then begin.
    try {
      // If BT is off, request turn-on (no-op on platforms that don't support it)
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
        // Wait a moment for adapter to come up
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (_) {}
    startScan();
  }

  void startScan() {
    if (_active) return;
    _active = true;
    _scan();
    _scanTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isConnected.value && !_connecting) _scan();
    });
  }

  void stopScan() {
    _active = false;
    _scanTimer?.cancel();
    _scanSub?.cancel();
    _scanSub = null;
    FlutterBluePlus.stopScan();
  }

  Future<void> refreshBattery() async {
    if (_device != null && isConnected.value) await _readBattery(_device!);
  }

  void dispose() {
    stopScan();
    _connSub?.cancel();
    batteryLevel.dispose();
    isConnected.dispose();
    deviceName.dispose();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _scan() async {
    if (isConnected.value || _connecting) return;

    // Check BT adapter is on
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) return;

    // Cancel any previous scan subscription first
    await _scanSub?.cancel();
    _scanSub = null;

    // Attach listener BEFORE starting scan so we catch all results
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (_matchesGelius(r)) {
          FlutterBluePlus.stopScan();
          _connectTo(r.device);
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: false,
      );
    } catch (_) {
      _scanSub?.cancel();
      _scanSub = null;
    }
  }

  bool _matchesGelius(ScanResult r) {
    final name = r.device.platformName.toLowerCase();
    // Match known name fragments
    if (_nameFragments.any((f) => name.contains(f))) return true;
    // Also check advertised local name in raw advertisement data
    final advName = r.advertisementData.advName.toLowerCase();
    if (_nameFragments.any((f) => advName.contains(f))) return true;
    return false;
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    if (_connecting) return;
    if (isConnected.value && _device?.remoteId == device.remoteId) return;

    _connecting = true;
    _device = device;

    // Subscribe to connection state BEFORE connecting
    await _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        isConnected.value = true;
        deviceName.value = device.platformName.isNotEmpty
            ? device.platformName
            : 'Gelius GP-TWS011';
        _readBattery(device);
      } else if (state == BluetoothConnectionState.disconnected) {
        isConnected.value = false;
        batteryLevel.value = null;
        deviceName.value = null;
        _connecting = false;
        // Re-scan after disconnect
        Future.delayed(const Duration(seconds: 5), () {
          if (_active && !isConnected.value) _scan();
        });
      }
    });

    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );
    } catch (_) {
      _connecting = false;
      isConnected.value = false;
    } finally {
      _connecting = false;
    }
  }

  Future<void> _readBattery(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == _batteryServiceUuid) {
          for (final ch in svc.characteristics) {
            if (ch.uuid.toString().toLowerCase() == _batteryCharUuid) {
              if (ch.properties.read) {
                final val = await ch.read();
                if (val.isNotEmpty) batteryLevel.value = val[0];
              }
              if (ch.properties.notify) {
                await ch.setNotifyValue(true);
                ch.onValueReceived.listen((v) {
                  if (v.isNotEmpty) batteryLevel.value = v[0];
                });
              }
              return;
            }
          }
        }
      }
    } catch (_) {}
  }
}
