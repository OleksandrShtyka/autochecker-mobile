import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Simple file-based JSON cache for offline support.
class CacheService {
  CacheService._();
  static final instance = CacheService._();

  Future<String> _path(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/cache_$key.json';
  }

  Future<void> save(String key, dynamic data) async {
    try {
      final file = File(await _path(key));
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<T?> load<T>(String key) async {
    try {
      final file = File(await _path(key));
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      return jsonDecode(raw) as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String key) async {
    try {
      final file = File(await _path(key));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
