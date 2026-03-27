import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

const int _currentBuild = 2;
const String _versionUrl = 'https://autochecker-site.vercel.app/api/app/version';

class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  /// Returns true if a new version was found and download+install triggered.
  Future<bool> checkAndUpdate({
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dio = Dio();
      final res = await dio.get<Map<String, dynamic>>(_versionUrl);
      final data = res.data;
      if (data == null) return false;

      final remoteBuild = data['build'] as int? ?? 0;
      if (remoteBuild <= _currentBuild) return false;

      final apkUrl = data['url'] as String?;
      if (apkUrl == null) return false;

      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/autochecker_update_b$remoteBuild.apk';

      await dio.download(
        apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      await OpenFilex.open(savePath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
