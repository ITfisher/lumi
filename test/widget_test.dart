import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/core/services/app_directory_service.dart';
import 'package:lumi/data/models/todo_model.dart';
import 'package:lumi/core/widgets/glass_container.dart';
import 'package:lumi/features/todo/data/task_view_cache.dart';
import 'package:lumi/features/todo/screens/home_screen.dart';
import 'package:lumi/features/todo/providers/todo_provider.dart';
import 'package:lumi/features/todo/widgets/kanban/kanban_card.dart';
import 'package:lumi/features/todo/widgets/shared/task_preview_sheet.dart';
import 'package:lumi/features/todo/widgets/shared/todo_form_sheet.dart';

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
    final container = _homeScreenContainer(
      overrides: [
        appDirectoryServiceProvider.overrideWithValue(directoryService),
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

      expect(container.read(navPageProvider), NavPage.me);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Directory path'), findsOneWidget);
      expect(find.text(directoryService.pathValue), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pump();

      expect(directoryService.openCount, 1);
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
}

Finder _textFieldWithValue(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller?.text == value,
  );
}

ProviderContainer _homeScreenContainer({
  List<Override> overrides = const [],
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
}) {
  final now = DateTime(2026, 4, 27, 9);
  return TodoModel(
    id: id,
    title: title,
    notes: notes,
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
