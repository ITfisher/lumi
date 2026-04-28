import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract class TaskViewCache {
  Future<String?> readSelectedView();
  Future<void> writeSelectedView(String viewMode);
}

class FileTaskViewCache implements TaskViewCache {
  static const _fileName = 'task_view_cache.json';
  static const _selectedViewKey = 'selectedTaskView';

  @override
  Future<String?> readSelectedView() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return null;

      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) return null;

      final selectedView = decoded[_selectedViewKey];
      return selectedView is String ? selectedView : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeSelectedView(String viewMode) async {
    final file = await _cacheFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({_selectedViewKey: viewMode}),
      flush: true,
    );
  }

  Future<File> _cacheFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(path.join(directory.path, _fileName));
  }
}
