import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../core/services/app_directory_service.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/todo_model.dart';
import '../../../data/repositories/todo_repository.dart';
import '../data/task_view_cache.dart';

enum ViewMode { list, kanban }

enum NavPage { overview, tasks, me }

/// Date range filter options for task lists and overview stats.
enum DateRangeOption { today, week, month, custom }

extension DateRangeOptionX on DateRangeOption {
  String get label {
    switch (this) {
      case DateRangeOption.today:
        return 'Today';
      case DateRangeOption.week:
        return 'Last 7 days';
      case DateRangeOption.month:
        return 'Last 30 days';
      case DateRangeOption.custom:
        return 'Custom';
    }
  }

  /// Returns the start of this range (null = no lower bound for custom).
  DateTime? startDate([DateTimeRange? custom]) {
    final now = DateTime.now();
    switch (this) {
      case DateRangeOption.today:
        return DateTime(now.year, now.month, now.day);
      case DateRangeOption.week:
        return now.subtract(const Duration(days: 7));
      case DateRangeOption.month:
        return now.subtract(const Duration(days: 30));
      case DateRangeOption.custom:
        return custom?.start;
    }
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
final appDirectoryServiceProvider =
    Provider<AppDirectoryService>((ref) => AppDirectoryService());
final appDirectoryPathProvider = FutureProvider<String>(
  (ref) => ref.read(appDirectoryServiceProvider).getAppDirectoryPath(),
);

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  if (kIsWeb) return TodoRepository.memory();
  return TodoRepository(ref.watch(appDatabaseProvider));
});

final taskViewCacheProvider = Provider<TaskViewCache>(
  (ref) => FileTaskViewCache(),
);
final initialTaskViewModeNameProvider = Provider<String?>((ref) => null);

final viewModeProvider =
    NotifierProvider<ViewModeController, ViewMode>(ViewModeController.new);
final navPageProvider = StateProvider<NavPage>((ref) => NavPage.tasks);
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

// ── Task list date filters ─────────────────────────────────────────
final createdFilterProvider = StateProvider<DateRangeOption?>((ref) => null);
final completedFilterProvider =
    StateProvider<DateRangeOption?>((ref) => DateRangeOption.week);
final createdCustomRangeProvider = StateProvider<DateTimeRange?>((ref) => null);
final completedCustomRangeProvider =
    StateProvider<DateTimeRange?>((ref) => null);

// ── Overview date filter ───────────────────────────────────────────
final overviewFilterProvider =
    StateProvider<DateRangeOption>((ref) => DateRangeOption.month);
final overviewCustomRangeProvider =
    StateProvider<DateTimeRange?>((ref) => null);

class ViewModeController extends Notifier<ViewMode> {
  bool _hasUserSelection = false;

  @override
  ViewMode build() {
    final initialName = ref.watch(initialTaskViewModeNameProvider);
    final initialMode = _viewModeFromName(initialName);
    if (initialMode == null) {
      _restoreSavedSelection();
    }
    return initialMode ?? ViewMode.list;
  }

  Future<void> setViewMode(ViewMode mode) async {
    _hasUserSelection = true;
    if (state != mode) {
      state = mode;
    }
    await ref.read(taskViewCacheProvider).writeSelectedView(mode.name);
  }

  Future<void> _restoreSavedSelection() async {
    final cached = await ref.read(taskViewCacheProvider).readSelectedView();
    final restored = _viewModeFromName(cached);
    if (_hasUserSelection || restored == null || state == restored) return;
    state = restored;
  }

  ViewMode? _viewModeFromName(String? name) {
    if (name == null) return null;
    for (final mode in ViewMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}

// ──────────────────────────────────────────────────────────────────
class TodoNotifier extends AsyncNotifier<List<TodoModel>> {
  @override
  Future<List<TodoModel>> build() async {
    return ref.read(todoRepositoryProvider).getAll();
  }

  Future<void> add(TodoModel todo) async {
    await ref.read(todoRepositoryProvider).insert(todo);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateTodo(TodoModel todo) async {
    await ref.read(todoRepositoryProvider).update(todo);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(todoRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateStatus(String id, TodoStatus status) async {
    await ref.read(todoRepositoryProvider).updateStatus(id, status);
    ref.invalidateSelf();
    await future;
  }
}

final todoProvider =
    AsyncNotifierProvider<TodoNotifier, List<TodoModel>>(TodoNotifier.new);

final filteredTodosByStatusProvider =
    Provider.family<List<TodoModel>, TodoStatus>((ref, status) {
  return ref.watch(filteredTodosProvider).maybeWhen(
        data: (list) => list.where((t) => t.status == status).toList(),
        orElse: () => [],
      );
});

/// All tasks filtered by search + created/completed date range filters.
final filteredTodosProvider = Provider<AsyncValue<List<TodoModel>>>((ref) {
  final todosAsync = ref.watch(todoProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final createdOpt = ref.watch(createdFilterProvider);
  final completedOpt = ref.watch(completedFilterProvider);
  final createdCustom = ref.watch(createdCustomRangeProvider);
  final completedCustom = ref.watch(completedCustomRangeProvider);

  return todosAsync.whenData((todos) {
    var list = todos.toList();

    if (query.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(query)).toList();
    }

    if (createdOpt != null) {
      final start = createdOpt.startDate(createdCustom);
      final end =
          createdOpt == DateRangeOption.custom ? createdCustom?.end : null;
      if (start != null) {
        list = list.where((t) {
          if (t.createdAt.isBefore(start)) return false;
          if (end != null &&
              t.createdAt.isAfter(end.add(const Duration(days: 1)))) {
            return false;
          }
          return true;
        }).toList();
      }
    }

    if (completedOpt != null) {
      final start = completedOpt.startDate(completedCustom);
      final end =
          completedOpt == DateRangeOption.custom ? completedCustom?.end : null;
      list = list.where((t) {
        // Tasks without a completedAt (not done) always pass through
        if (t.completedAt == null) return true;
        if (start != null && t.completedAt!.isBefore(start)) return false;
        if (end != null &&
            t.completedAt!.isAfter(end.add(const Duration(days: 1)))) {
          return false;
        }
        return true;
      }).toList();
    }

    return list;
  });
});

/// Tasks filtered by the overview date range (based on createdAt).
final overviewTasksProvider = Provider<AsyncValue<List<TodoModel>>>((ref) {
  final todosAsync = ref.watch(todoProvider);
  final opt = ref.watch(overviewFilterProvider);
  final custom = ref.watch(overviewCustomRangeProvider);

  return todosAsync.whenData((todos) {
    final start = opt.startDate(custom);
    final end = opt == DateRangeOption.custom ? custom?.end : null;
    if (start == null) return todos;
    return todos.where((t) {
      if (t.createdAt.isBefore(start)) return false;
      if (end != null &&
          t.createdAt.isAfter(end.add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  });
});

/// Sidebar badge: incomplete tasks count for Tasks.
final navCountsProvider = Provider<Map<NavPage, int>>((ref) {
  return ref.watch(todoProvider).maybeWhen(
        data: (list) => {
          NavPage.tasks: list.where((t) => t.status != TodoStatus.done).length,
          NavPage.overview: 0,
          NavPage.me: 0,
        },
        orElse: () => const {},
      );
});
