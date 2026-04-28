import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AppDirectoryService {
  Future<Directory> getAppDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Opening app directories is not supported on web.');
    }
    return getApplicationSupportDirectory();
  }

  Future<String> getAppDirectoryPath() async {
    final directory = await getAppDirectory();
    return directory.path;
  }

  Future<bool> openAppDirectory() async {
    if (kIsWeb) return false;

    final directory = await getAppDirectory();
    final path = directory.path;

    try {
      ProcessResult result;
      if (Platform.isMacOS) {
        result = await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        result = await Process.run('explorer', [path]);
      } else if (Platform.isLinux) {
        result = await Process.run('xdg-open', [path]);
      } else {
        return false;
      }

      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
