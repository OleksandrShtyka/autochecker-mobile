import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'cache_service.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = 'https://autochecker-site.vercel.app';

  Dio? _dio;
  PersistCookieJar? _cookieJar;

  Future<Dio> get _client async {
    if (_dio != null) return _dio!;

    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/.cookies'));

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));

    _dio!.interceptors.add(CookieManager(_cookieJar!));
    return _dio!;
  }

  /// Returns the raw session cookie string (name=value) for injection into WebView.
  Future<String?> getSessionCookie() async {
    await _client; // ensure jar is initialised
    final cookies = await _cookieJar!.loadForRequest(Uri.parse(baseUrl));
    for (final c in cookies) {
      if (c.name == 'autochecker_session') {
        return '${c.name}=${c.value}';
      }
    }
    return null;
  }

  // ── Auth ──────────────────────────────────────────────────────

  /// Returns the response map. Check `data['mfa_required'] == true`
  /// to determine if a TOTP code is needed before a full session exists.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final dio = await _client;
    final res = await dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final dio = await _client;
    final res = await dio.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> verifyTotp(String code) async {
    final dio = await _client;
    await dio.post('/api/auth/totp/verify', data: {'code': code});
  }

  Future<void> logout() async {
    final dio = await _client;
    await dio.post('/api/auth/logout');
    await _cookieJar?.deleteAll();
  }

  Future<bool> checkSession() async {
    try {
      final dio = await _client;
      final res = await dio.get('/api/auth/session');
      final data = res.data as Map<String, dynamic>?;
      return data?['authenticated'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── AI ────────────────────────────────────────────────────────

  Future<String> sendAiMessage(
    List<Map<String, String>> messages, {
    String? context,
  }) async {
    final dio = await _client;
    final body = <String, dynamic>{'messages': messages};
    if (context != null && context.isNotEmpty) body['context'] = context;
    final res = await dio.post('/api/ai/chat', data: body);
    final data = res.data as Map<String, dynamic>;
    return data['reply'] as String;
  }

  // ── Fitness profile ───────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final dio = await _client;
      final res = await dio.get('/api/fitness/profile');
      final data = res.data as Map<String, dynamic>;
      await CacheService.instance.save('profile', data);
      return data['profile'] as Map<String, dynamic>?;
    } catch (_) {
      final cached = await CacheService.instance.load<Map<String, dynamic>>('profile');
      return cached?['profile'] as Map<String, dynamic>?;
    }
  }

  Future<void> saveProfile({
    required double monthlyGymCost,
    required String fitnessGoal,
    required String fitnessBadge,
  }) async {
    final dio = await _client;
    await dio.patch('/api/fitness/profile', data: {
      'monthlyGymCost': monthlyGymCost,
      'fitnessGoal': fitnessGoal,
      'fitnessBadge': fitnessBadge,
    });
  }

  // ── Supplements ───────────────────────────────────────────────

  Future<Map<String, dynamic>> getSupplements() async {
    try {
      final dio = await _client;
      final res = await dio.get('/api/fitness/supplements');
      final data = res.data as Map<String, dynamic>;
      await CacheService.instance.save('supplements', data);
      return data;
    } catch (_) {
      return await CacheService.instance.load<Map<String, dynamic>>('supplements') ?? {};
    }
  }

  Future<void> createSupplement(Map<String, dynamic> data) async {
    final dio = await _client;
    await dio.post('/api/fitness/supplements', data: data);
  }

  Future<void> updateSupplement(String id, Map<String, dynamic> data) async {
    final dio = await _client;
    await dio.patch('/api/fitness/supplements/$id', data: data);
  }

  Future<void> deleteSupplement(String id) async {
    final dio = await _client;
    await dio.delete('/api/fitness/supplements/$id');
  }

  // ── Sessions ──────────────────────────────────────────────────

  Future<List<dynamic>> getSessions() async {
    try {
      final dio = await _client;
      final res = await dio.get('/api/fitness/sessions');
      final data = res.data as Map<String, dynamic>;
      await CacheService.instance.save('sessions', data);
      return data['sessions'] as List<dynamic>? ?? [];
    } catch (_) {
      final cached = await CacheService.instance.load<Map<String, dynamic>>('sessions');
      return cached?['sessions'] as List<dynamic>? ?? [];
    }
  }

  Future<void> createSession(Map<String, dynamic> data) async {
    final dio = await _client;
    await dio.post('/api/fitness/sessions', data: data);
  }

  Future<void> deleteSession(String id) async {
    final dio = await _client;
    await dio.delete('/api/fitness/sessions/$id');
  }

  // ── ROI ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getRoi() async {
    try {
      final dio = await _client;
      final res = await dio.get('/api/fitness/roi');
      final data = res.data as Map<String, dynamic>;
      await CacheService.instance.save('roi', data);
      return data['roi'] as Map<String, dynamic>?;
    } catch (_) {
      final cached = await CacheService.instance.load<Map<String, dynamic>>('roi');
      return cached?['roi'] as Map<String, dynamic>?;
    }
  }

  // ── Account / Avatar ──────────────────────────────────────────

  Future<Map<String, dynamic>> getAccountProfile() async {
    final dio = await _client;
    final res = await dio.get('/api/cabinet/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<String?> uploadAvatar(Uint8List bytes, String mimeType) async {
    final dio = await _client;
    // Send bytes directly (not as a Stream) so Dio sets Content-Length
    // correctly and avoids chunked transfer encoding that Vercel can reject.
    final res = await dio.post(
      '/api/cabinet/avatar',
      data: bytes,
      options: Options(
        contentType: mimeType,
        responseType: ResponseType.json,
      ),
    );
    final data = res.data as Map<String, dynamic>;
    if (data['avatarUrl'] == null) {
      throw Exception(data['message'] as String? ?? 'Upload failed');
    }
    return data['avatarUrl'] as String;
  }

  Future<void> removeAvatar() async {
    final dio = await _client;
    await dio.delete('/api/cabinet/avatar');
  }

  // ── Spotify OAuth proxy ───────────────────────────────────────────────────

  Future<String> getSpotifyAuthUrl() async {
    final dio = await _client;
    final res = await dio.get('/api/spotify/auth-url');
    return (res.data as Map<String, dynamic>)['url'] as String;
  }

  Future<Map<String, dynamic>> spotifyExchange(String code) async {
    final dio = await _client;
    final res = await dio.post('/api/spotify/exchange', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> spotifyRefresh(String refreshToken) async {
    final dio = await _client;
    final res = await dio.post(
      '/api/spotify/refresh',
      data: {'refresh_token': refreshToken},
    );
    return res.data as Map<String, dynamic>;
  }

  // ── Subscription ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      final dio = await _client;
      final res = await dio.get('/api/subscriptions/status');
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return {'isPremium': false, 'plan': null};
    }
  }

  Future<Map<String, dynamic>> activateTrial() async {
    final dio = await _client;
    final res = await dio.post('/api/subscriptions/trial');
    return res.data as Map<String, dynamic>;
  }

  // ── Voice Action ─────────────────────────────────────────────────────────

  /// Sends a voice transcript to the AI and gets back a structured session JSON.
  Future<Map<String, dynamic>> voiceAction(String transcript) async {
    final dio = await _client;
    final res = await dio.post(
      '/api/ai/voice-action',
      data: {'transcript': transcript},
    );
    return res.data as Map<String, dynamic>;
  }

  // ── Food Calorie Analysis ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeFood(
      Uint8List bytes, String mimeType) async {
    final dio = await _client;
    try {
      final res = await dio.post(
        '/api/ai/food-analyze',
        data: {'image': base64Encode(bytes), 'mimeType': mimeType},
        options: Options(
          // Accept any status so Dio doesn't throw on 4xx — we read the body
          validateStatus: (s) => s != null && s < 600,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final data = res.data as Map<String, dynamic>;
      // Surface server-side errors as exceptions
      if (res.statusCode != 200) {
        throw Exception(
            data['message'] as String? ?? 'Server error ${res.statusCode}');
      }
      return data;
    } on DioException catch (e) {
      final msg = (e.response?.data as Map?)?.cast<String, dynamic>()?['message']
          as String?;
      throw Exception(msg ?? e.message ?? 'Network error');
    }
  }
}
