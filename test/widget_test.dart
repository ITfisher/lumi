import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/core/services/app_directory_service.dart';
import 'package:lumi/core/services/app_update_service.dart';
import 'package:lumi/data/models/todo_model.dart';
import 'package:lumi/data/repositories/app_update_settings_repository.dart';
import 'package:lumi/data/repositories/task_label_repository.dart';
import 'package:lumi/data/repositories/todo_repository.dart';
import 'package:lumi/core/widgets/glass_container.dart';
import 'package:lumi/features/todo/data/task_view_cache.dart';
import 'package:lumi/features/todo/screens/home_screen.dart';
import 'package:lumi/features/todo/screens/me_screen.dart';
import 'package:lumi/features/todo/providers/todo_provider.dart';
import 'package:lumi/features/todo/widgets/kanban/kanban_card.dart';
import 'package:lumi/features/todo/widgets/shared/task_preview_sheet.dart';
import 'package:lumi/features/todo/widgets/shared/todo_form_sheet.dart';
import 'package:lumi/features/todo/screens/task_detail_screen.dart';

void main() {
  testWidgets(
      'wide layout starts expanded and exposes the floating menu button after collapse',
      (tester) async {
    await _withScreenSize(tester, const Size(1000, 800), () async {
      final container = _homeScreenContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.byTooltip('Collapse menu'), findsOneWidget);
      expect(find.byTooltip('Open menu'), findsNothing);

      await tester.tap(find.byTooltip('Collapse menu'));
      await _pumpLayoutAnimation(tester);

      expect(find.byTooltip('Open menu'), findsOneWidget);
      expect(find.byTooltip('Collapse menu'), findsNothing);

      await tester.tap(find.byTooltip('Open menu'));
      await _pumpLayoutAnimation(tester);

      expect(find.byTooltip('Open menu'), findsNothing);
      expect(find.byTooltip('Collapse menu'), findsOneWidget);
    });
  });

  testWidgets(
      'compact layout starts collapsed and menu button expands the sidebar',
      (tester) async {
    await _withScreenSize(tester, const Size(500, 800), () async {
      final container = _homeScreenContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.byTooltip('Open menu'), findsOneWidget);

      await tester.tap(find.byTooltip('Open menu'));
      await _pumpLayoutAnimation(tester);

      expect(find.byTooltip('Open menu'), findsNothing);
      expect(find.byTooltip('Collapse menu'), findsOneWidget);

      await tester.tap(find.text('Overview'));
      await _pumpLayoutAnimation(tester);

      expect(container.read(navPageProvider), NavPage.overview);
      expect(find.byTooltip('Open menu'), findsOneWidget);
      expect(find.byTooltip('Collapse menu'), findsNothing);
    });
  });

  testWidgets('sidebar keeps Profile at the bottom and opens profile settings',
      (tester) async {
    final directoryService = _FakeAppDirectoryService();
    final updateService = _FakeAppUpdateService();
    final container = _homeScreenContainer(
      overrides: [
        appDirectoryServiceProvider.overrideWithValue(directoryService),
        appUpdateServiceProvider.overrideWithValue(updateService),
      ],
    );
    addTearDown(container.dispose);

    await _withScreenSize(tester, const Size(1000, 800), () async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await _pumpLayoutAnimation(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(navPageProvider), NavPage.me);
      expect(find.text(directoryService.pathValue), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(directoryService.openCount, 1);
    });
  });

  testWidgets('profile can check GitHub updates and open the dmg asset',
      (tester) async {
    await _withScreenSize(tester, const Size(1000, 1000), () async {
      final settingsRepository = _FakeAppUpdateSettingsRepository();
      final updateService = _FakeAppUpdateService(
        latestResult: const AppUpdateCheckResult(
          currentVersion: '1.0.0+1',
          latestRelease: AppReleaseInfo(
            version: '1.0.0+7',
            releaseUrl:
                'https://github.com/ITfisher/lumi/releases/tag/v1.0.0+7',
            downloadUrl: 'https://example.com/lumi-1.1.0.dmg',
            assetName: 'lumi-1.1.0.dmg',
            publishedAt: null,
            isPrerelease: true,
          ),
          hasUpdate: true,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appUpdateServiceProvider.overrideWithValue(updateService),
          appUpdateSettingsRepositoryProvider
              .overrideWithValue(settingsRepository),
          appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MeScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('v1.0.0+1'), findsOneWidget);
      expect(find.text('Check for updates'), findsNothing);
      expect(find.text('Prerelease'), findsOneWidget);

      await tester.tap(find.byTooltip('Check for updates'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Up to date'), findsOneWidget);
      expect(updateService.checkCount, 1);
      expect(updateService.lastIncludePrerelease, isFalse);

      await container
          .read(allowPrereleaseUpdatesProvider.notifier)
          .saveAllowPrereleaseUpdates(true);
      await tester.pump();
      await tester.pump();

      expect(settingsRepository.savedValue, isTrue);

      await tester.tap(find.byTooltip('Check for updates'));
      await tester.pump();
      await tester.pump();

      expect(find.text('v1.0.0+7 available'), findsOneWidget);
      expect(updateService.checkCount, 2);
      expect(updateService.lastIncludePrerelease, isTrue);

      await tester.tap(find.text('Download DMG'));
      await tester.pump();

      expect(updateService.openedUrls, ['https://example.com/lumi-1.1.0.dmg']);
    });
  });

  test('kanban status buckets are based on the filtered task set', () {
    final visibleTodo = _todo(
      id: 'visible-todo',
      title: 'Visible todo',
      status: TodoStatus.todo,
    );
    final visibleDone = _todo(
      id: 'visible-done',
      title: 'Visible done',
      status: TodoStatus.done,
    );

    final container = ProviderContainer(
      overrides: [
        filteredTodosProvider.overrideWithValue(
          AsyncData([visibleTodo, visibleDone]),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(filteredTodosByStatusProvider(TodoStatus.todo)),
      [visibleTodo],
    );
    expect(
      container.read(filteredTodosByStatusProvider(TodoStatus.doing)),
      isEmpty,
    );
    expect(
      container.read(filteredTodosByStatusProvider(TodoStatus.done)),
      [visibleDone],
    );
  });

  test('task label filters match tasks containing any selected label', () {
    final designTask = _todo(
      id: 'design-task',
      title: 'Design flow',
      status: TodoStatus.todo,
      labels: const ['Design', 'UX'],
    );
    final qaTask = _todo(
      id: 'qa-task',
      title: 'QA review',
      status: TodoStatus.doing,
      labels: const ['QA'],
    );
    final unlabeledTask = _todo(
      id: 'plain-task',
      title: 'Inbox cleanup',
      status: TodoStatus.done,
    );

    final filtered = applyTodoFilters(
      todos: [designTask, qaTask, unlabeledTask],
      query: '',
      selectedLabels: const {'Design', 'Backend'},
      createdOpt: null,
      createdCustom: null,
      completedOpt: null,
      completedCustom: null,
    );

    expect(filtered, [designTask]);
  });

  testWidgets('task view restores saved selection and persists updates',
      (tester) async {
    await _withScreenSize(tester, const Size(1000, 800), () async {
      final cache = _FakeTaskViewCache(initialSelection: ViewMode.kanban.name);
      final container = _homeScreenContainer(
        overrides: [
          taskViewCacheProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      expect(container.read(viewModeProvider), ViewMode.kanban);

      await tester.tap(find.text('List'));
      await tester.pump();

      expect(container.read(viewModeProvider), ViewMode.list);
      expect(cache.savedSelections, [ViewMode.list.name]);
    });
  });

  testWidgets('kanban drag feedback keeps the rendered card width',
      (tester) async {
    final todo = _todo(
      id: 'drag-task',
      title: 'Drag me',
      status: TodoStatus.todo,
      notes: 'Keep my size stable while dragging',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: KanbanCard(todo: todo),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final cardFinder = find.byType(GlassContainer);
    final originalWidth = tester.getSize(cardFinder.first).width;

    final gesture =
        await tester.startGesture(tester.getCenter(cardFinder.first));
    await gesture.moveBy(const Offset(24, 24));
    await tester.pump();

    final widths = tester
        .renderObjectList<RenderBox>(cardFinder)
        .map((box) => box.size.width)
        .toList();

    expect(widths, isNotEmpty);
    expect(widths, everyElement(closeTo(originalWidth, 0.01)));

    await gesture.up();
  });

  testWidgets('editing a task shows save only after content changes',
      (tester) async {
    final todo = _todo(
      id: 'editable-task',
      title: 'Original title',
      status: TodoStatus.todo,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TodoFormSheet(todo: todo, isDialog: true),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Save changes'), findsNothing);

    await tester.enterText(
        _textFieldWithValue('Original title'), 'Updated title');
    await tester.pump();

    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('preview sheet edits inline and only shows save after changes',
      (tester) async {
    final todo = _todo(
      id: 'preview-task',
      title: 'Preview title',
      status: TodoStatus.todo,
      notes: 'Initial notes',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TaskPreviewSheet(todo: todo),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Edit task'), findsNothing);
    expect(find.byTooltip('Save changes'), findsNothing);

    await tester.enterText(
        _textFieldWithValue('Preview title'), 'Changed title');
    await tester.pump();

    expect(find.byTooltip('Save changes'), findsOneWidget);
  });

  testWidgets('preview sheet can edit labels and save them', (tester) async {
    await _withScreenSize(tester, const Size(1000, 1000), () async {
      final repo = TodoRepository.memory();
      final todo = _todo(
        id: 'preview-editable',
        title: 'Preview editable',
        status: TodoStatus.todo,
        labels: const ['Bug'],
      );
      await repo.insert(todo);

      final container = ProviderContainer(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repo),
          taskLabelRepositoryProvider.overrideWithValue(
            _FakeTaskLabelRepository(
              initialLabels: const ['Bug', 'Urgent', 'Research'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: TaskPreviewSheet(todo: todo),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Urgent'));
      await tester.pump();
      expect(_saveTapTarget(find.byTooltip('Save changes')), findsOneWidget);
      await _triggerSave(tester, find.byTooltip('Save changes'));

      final todos = await container.read(todoProvider.future);
      final updated = todos.firstWhere((item) => item.id == todo.id);
      expect(updated.labels, containsAll(['Bug', 'Urgent']));
    });
  });

  testWidgets('detail screen can edit labels and save them', (tester) async {
    await _withScreenSize(tester, const Size(1200, 1000), () async {
      final repo = TodoRepository.memory();
      final todo = _todo(
        id: 'detail-editable',
        title: 'Detail editable',
        status: TodoStatus.todo,
        labels: const ['Bug'],
      );
      await repo.insert(todo);

      final container = ProviderContainer(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repo),
          taskLabelRepositoryProvider.overrideWithValue(
            _FakeTaskLabelRepository(
              initialLabels: const ['Bug', 'Urgent', 'Research'],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TaskDetailScreen(taskId: 'detail-editable'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Research'));
      await tester.pump();
      expect(_saveTapTarget(find.byTooltip('Save changes')), findsOneWidget);
      await _triggerSave(tester, find.byTooltip('Save changes'));

      final todos = await container.read(todoProvider.future);
      final updated = todos.firstWhere((item) => item.id == todo.id);
      expect(updated.labels, containsAll(['Bug', 'Research']));
    });
  });

  testWidgets('new task sheet saves multiple configured labels',
      (tester) async {
    await _withScreenSize(tester, const Size(1000, 1000), () async {
      final labelRepository = _FakeTaskLabelRepository(
        initialLabels: const ['Bug', 'Urgent', 'Research'],
      );
      final todoRepository = TodoRepository.memory();
      final container = ProviderContainer(
        overrides: [
          todoRepositoryProvider.overrideWithValue(todoRepository),
          taskLabelRepositoryProvider.overrideWithValue(labelRepository),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TodoFormSheet(isDialog: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Tagged task');
      await tester.pump();

      await tester.tap(find.text('Bug'));
      await tester.pump();
      await tester.tap(find.text('Urgent'));
      await tester.pump();
      await tester.tap(find.text('Add task'));
      await tester.pumpAndSettle();

      final todos = await container.read(todoProvider.future);
      final created = todos.firstWhere((todo) => todo.title == 'Tagged task');

      expect(created.labels, ['Bug', 'Urgent']);
    });
  });
}

Finder _textFieldWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller?.text == value,
  );
}

Finder _saveTapTarget(Finder tooltipFinder) {
  final saveIcon = find.descendant(
    of: tooltipFinder,
    matching: find.byIcon(Icons.check_rounded),
  );
  return find
      .ancestor(
        of: saveIcon,
        matching: find.byType(GestureDetector),
      )
      .first;
}

Future<void> _triggerSave(WidgetTester tester, Finder tooltipFinder) async {
  final target = _saveTapTarget(tooltipFinder);
  final widget = tester.widget<GestureDetector>(target);
  widget.onTap!.call();
  await tester.pumpAndSettle();
}

ProviderContainer _homeScreenContainer({
  List<dynamic> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      filteredTodosProvider.overrideWithValue(const AsyncData([])),
      navCountsProvider.overrideWithValue(const {
        NavPage.overview: 0,
        NavPage.tasks: 0,
        NavPage.me: 0,
      }),
      ...overrides,
    ],
  );
}

Future<void> _withScreenSize(
  WidgetTester tester,
  Size size,
  Future<void> Function() body,
) async {
  final view = tester.view;
  final oldSize = view.physicalSize;
  final oldDevicePixelRatio = view.devicePixelRatio;
  view.physicalSize = size;
  view.devicePixelRatio = 1;
  addTearDown(() {
    view.physicalSize = oldSize;
    view.devicePixelRatio = oldDevicePixelRatio;
  });

  await body();
}

Future<void> _pumpLayoutAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

TodoModel _todo({
  required String id,
  required String title,
  required TodoStatus status,
  String? notes,
  List<String> labels = const [],
}) {
  final now = DateTime(2026, 4, 27, 9);
  return TodoModel(
    id: id,
    title: title,
    notes: notes,
    labels: labels,
    status: status,
    priority: Priority.medium,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeTaskViewCache implements TaskViewCache {
  _FakeTaskViewCache({this.initialSelection});

  final String? initialSelection;
  final List<String> savedSelections = [];

  @override
  Future<String?> readSelectedView() async => initialSelection;

  @override
  Future<void> writeSelectedView(String viewMode) async {
    savedSelections.add(viewMode);
  }
}

class _FakeAppDirectoryService extends AppDirectoryService {
  int openCount = 0;
  final String pathValue = '/tmp/lumi-test-data';

  @override
  Future<String> getAppDirectoryPath() async => pathValue;

  @override
  Future<bool> openAppDirectory() async {
    openCount += 1;
    return true;
  }
}

class _FakeTaskLabelRepository implements TaskLabelRepository {
  _FakeTaskLabelRepository({this.initialLabels = const []})
      : _labels = List.of(initialLabels);

  final List<String> initialLabels;
  final List<String> _labels;

  @override
  Future<List<String>> readLabels() async => List.unmodifiable(_labels);

  @override
  Future<void> writeLabels(List<String> labels) async {
    _labels
      ..clear()
      ..addAll(labels);
  }
}

class _FakeAppUpdateService extends AppUpdateService {
  _FakeAppUpdateService({
    this.latestResult = const AppUpdateCheckResult(
      currentVersion: '1.0.0',
      latestRelease: AppReleaseInfo(
        version: '1.0.0',
        releaseUrl: 'https://github.com/ITfisher/lumi/releases/tag/v1.0.0',
        downloadUrl: 'https://github.com/ITfisher/lumi/releases/tag/v1.0.0',
        assetName: null,
        publishedAt: null,
        isPrerelease: false,
      ),
      hasUpdate: false,
    ),
  });

  final AppUpdateCheckResult latestResult;
  int checkCount = 0;
  bool? lastIncludePrerelease;
  final List<String> openedUrls = [];

  @override
  Future<String> getCurrentVersion() async => latestResult.currentVersion;

  @override
  Future<AppUpdateCheckResult> checkForUpdates({
    bool includePrerelease = false,
  }) async {
    checkCount += 1;
    lastIncludePrerelease = includePrerelease;
    if (!includePrerelease && latestResult.latestRelease.isPrerelease) {
      return AppUpdateCheckResult(
        currentVersion: latestResult.currentVersion,
        latestRelease: latestResult.latestRelease,
        hasUpdate: false,
      );
    }
    return latestResult;
  }

  @override
  Future<bool> openUrl(String url) async {
    openedUrls.add(url);
    return true;
  }
}

class _FakeAppUpdateSettingsRepository implements AppUpdateSettingsRepository {
  bool savedValue = false;

  @override
  Future<bool> readAllowPrereleaseUpdates() async => savedValue;

  @override
  Future<void> writeAllowPrereleaseUpdates(bool value) async {
    savedValue = value;
  }
}
