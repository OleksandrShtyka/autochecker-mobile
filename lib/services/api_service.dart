import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

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
    final dio = await _client;
    final res = await dio.get('/api/fitness/profile');
    return (res.data as Map<String, dynamic>)['profile'] as Map<String, dynamic>?;
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
    final dio = await _client;
    final res = await dio.get('/api/fitness/supplements');
    return res.data as Map<String, dynamic>;
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
    final dio = await _client;
    final res = await dio.get('/api/fitness/sessions');
    return (res.data as Map<String, dynamic>)['sessions'] as List<dynamic>? ?? [];
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
    final dio = await _client;
    final res = await dio.get('/api/fitness/roi');
    return (res.data as Map<String, dynamic>)['roi'] as Map<String, dynamic>?;
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
}
