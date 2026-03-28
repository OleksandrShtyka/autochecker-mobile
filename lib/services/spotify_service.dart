import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class SpotifyTrack {
  final String id;
  final String title;
  final String artist;
  final String? albumArtUrl;
  final bool isPlaying;
  final int progressMs;
  final int durationMs;

  const SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArtUrl,
    required this.isPlaying,
    required this.progressMs,
    required this.durationMs,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    final artists = (item?['artists'] as List?)
            ?.map((a) => a['name'] as String)
            .join(', ') ??
        '';
    final images = item?['album']?['images'] as List?;
    final artUrl =
        (images != null && images.isNotEmpty) ? images.first['url'] as String? : null;
    return SpotifyTrack(
      id: item?['id'] as String? ?? '',
      title: item?['name'] as String? ?? 'Unknown',
      artist: artists,
      albumArtUrl: artUrl,
      isPlaying: json['is_playing'] as bool? ?? false,
      progressMs: json['progress_ms'] as int? ?? 0,
      durationMs: item?['duration_ms'] as int? ?? 0,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class SpotifyService {
  SpotifyService._();
  static final instance = SpotifyService._();

  static const _storage = FlutterSecureStorage();
  static const _keyAccess = 'spotify_access_token';
  static const _keyRefresh = 'spotify_refresh_token';
  static const _keyExpiry = 'spotify_token_expiry';

  static const _spotifyBase = 'https://api.spotify.com/v1/me/player';

  final ValueNotifier<SpotifyTrack?> currentTrack = ValueNotifier(null);

  // ── Token management ───────────────────────────────────────────────────────

  Future<bool> get isConnected async {
    final token = await _storage.read(key: _keyRefresh);
    return token != null && token.isNotEmpty;
  }

  Future<void> exchangeCode(String code) async {
    final data = await ApiService.instance.spotifyExchange(code);
    await _saveTokens(data);
  }

  Future<void> disconnect() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    await _storage.delete(key: _keyExpiry);
    currentTrack.value = null;
  }

  Future<String?> _getValidToken() async {
    final access = await _storage.read(key: _keyAccess);
    final refresh = await _storage.read(key: _keyRefresh);
    final expiryStr = await _storage.read(key: _keyExpiry);

    if (refresh == null) return null;

    final expiryMs = int.tryParse(expiryStr ?? '0') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Refresh 60 seconds early
    if (access == null || now >= expiryMs - 60000) {
      try {
        final data = await ApiService.instance.spotifyRefresh(refresh);
        final newRefresh = data['refresh_token'] as String?;
        await _saveTokens(data, keepRefresh: newRefresh == null ? refresh : null);
        return data['access_token'] as String?;
      } catch (_) {
        return null;
      }
    }

    return access;
  }

  Future<void> _saveTokens(Map<String, dynamic> data, {String? keepRefresh}) async {
    final access = data['access_token'] as String?;
    final refresh = (data['refresh_token'] as String?) ?? keepRefresh;
    final expiresIn = data['expires_in'] as int? ?? 3600;
    final expiry = DateTime.now().millisecondsSinceEpoch + expiresIn * 1000;

    if (access != null) await _storage.write(key: _keyAccess, value: access);
    if (refresh != null) await _storage.write(key: _keyRefresh, value: refresh);
    await _storage.write(key: _keyExpiry, value: '$expiry');
  }

  // ── Playback state ─────────────────────────────────────────────────────────

  Future<void> fetchCurrentTrack() async {
    try {
      final token = await _getValidToken();
      if (token == null) {
        currentTrack.value = null;
        return;
      }

      final res = await Dio().get(
        '$_spotifyBase/currently-playing',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 600,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (res.statusCode == 200 && res.data != null) {
        currentTrack.value =
            SpotifyTrack.fromJson(res.data as Map<String, dynamic>);
      } else {
        // 204 = nothing playing; 401/403 = auth issue
        currentTrack.value = null;
      }
    } catch (_) {
      // Network error — keep last known track
    }
  }

  // ── Playback control ───────────────────────────────────────────────────────

  Future<void> _playerAction(String method, String path) async {
    try {
      final token = await _getValidToken();
      if (token == null) return;
      await Dio().request(
        '$_spotifyBase/$path',
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 600,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      await fetchCurrentTrack();
    } catch (_) {}
  }

  Future<void> play() => _playerAction('PUT', 'play');
  Future<void> pause() => _playerAction('PUT', 'pause');
  Future<void> next() => _playerAction('POST', 'next');
  Future<void> previous() => _playerAction('POST', 'previous');
}
