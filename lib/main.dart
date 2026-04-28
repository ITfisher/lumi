import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/services/app_menu_service.dart';
import 'features/todo/data/task_view_cache.dart';
import 'features/todo/providers/todo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  if (!kIsWeb && Platform.isMacOS) {
    AppMenuService.instance.init();
  }
  final initialTaskViewModeName = await FileTaskViewCache().readSelectedView();
  runApp(
    ProviderScope(
      overrides: [
        initialTaskViewModeNameProvider.overrideWithValue(
          initialTaskViewModeName,
        ),
      ],
      child: const LumiApp(),
    ),
  );
}
