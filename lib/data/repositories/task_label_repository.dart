import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/todo_model.dart';

abstract class TaskLabelRepository {
  Future<List<String>> readLabels();
  Future<void> writeLabels(List<String> labels);
}

class FileTaskLabelRepository implements TaskLabelRepository {
  static const _fileName = 'task_label_settings.json';
  static const _labelsKey = 'labels';

  @override
  Future<List<String>> readLabels() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return const [];

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return const [];

      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) return const [];

      final rawLabels = decoded[_labelsKey];
      if (rawLabels is! List) return const [];

      return TodoModel.normalizeLabels(rawLabels.whereType<String>());
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writeLabels(List<String> labels) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({_labelsKey: TodoModel.normalizeLabels(labels)}),
      flush: true,
    );
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File(path.join(directory.path, _fileName));
  }
}
