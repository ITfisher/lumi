import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract class AppUpdateSettingsRepository {
  Future<bool> readAllowPrereleaseUpdates();
  Future<void> writeAllowPrereleaseUpdates(bool value);
}

class FileAppUpdateSettingsRepository implements AppUpdateSettingsRepository {
  static const _fileName = 'app_update_settings.json';
  static const _allowPrereleaseKey = 'allow_prerelease_updates';

  @override
  Future<bool> readAllowPrereleaseUpdates() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return false;

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return false;

      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) return false;

      return decoded[_allowPrereleaseKey] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> writeAllowPrereleaseUpdates(bool value) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({_allowPrereleaseKey: value}),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(path.join(directory.path, _fileName));
  }
}
