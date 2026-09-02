import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenFileLocationHelper {
  /// Opens the directory in the native system file manager and highlights [filePath] if supported.
  static Future<bool> openLocation(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      final dir = exists ? file.parent : Directory(filePath);
      final dirPath = dir.path;

      if (!kIsWeb) {
        if (Platform.isWindows) {
          if (exists) {
            final result = await Process.run('explorer.exe', ['/select,', filePath]);
            if (result.exitCode == 0) return true;
          }
          final result = await Process.run('explorer.exe', [dirPath]);
          return result.exitCode == 0;
        } else if (Platform.isMacOS) {
          if (exists) {
            final result = await Process.run('open', ['-R', filePath]);
            if (result.exitCode == 0) return true;
          }
          final result = await Process.run('open', [dirPath]);
          return result.exitCode == 0;
        } else if (Platform.isLinux) {
          final result = await Process.run('xdg-open', [dirPath]);
          return result.exitCode == 0;
        } else if (Platform.isAndroid || Platform.isIOS) {
          final uri = Uri.file(dirPath);
          if (await canLaunchUrl(uri)) {
            return await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
    } catch (e) {
      debugPrint('[OpenFileLocationHelper] Error opening file location: $e');
    }
    return false;
  }
}
