import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _currentBuild = 13;
const String _versionUrl =
    'https://autochecker-site.vercel.app/api/app/version';
const String _prefKeyDismissed = 'update_dismissed_build';

class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  // Ensures we only show the dialog once per app session, no matter
  // how many times HomeScreen is recreated (lock screen, navigation, etc.)
  static bool _checkedThisSession = false;

  /// Returns update info if a newer, non-dismissed build is available.
  /// Returns null if no update, already dismissed, or already checked this session.
  Future<Map<String, dynamic>?> getUpdateInfo() async {
    if (_checkedThisSession) return null;
    _checkedThisSession = true;

    try {
      final res = await Dio().get<Map<String, dynamic>>(_versionUrl);
      final data = res.data;
      if (data == null) return null;

      final remoteBuild = data['build'] as int? ?? 0;
      if (remoteBuild <= _currentBuild) return null;
      if (data['url'] == null) return null;

      // Don't re-prompt for a build the user already dismissed
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getInt(_prefKeyDismissed) ?? 0;
      if (dismissed >= remoteBuild) return null;

      return data;
    } catch (_) {
      return null;
    }
  }

  /// Call this when the user taps "Later" — suppresses the prompt for this build.
  Future<void> dismissBuild(int build) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyDismissed, build);
  }

  /// Downloads and opens the APK installer.
  Future<void> downloadAndInstall({
    required Map<String, dynamic> info,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final apkUrl = info['url'] as String;
      final remoteBuild = info['build'] as int? ?? 0;
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/gymtracker_update_b$remoteBuild.apk';

      await Dio().download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      await OpenFilex.open(savePath);
    } catch (_) {}
  }
}
