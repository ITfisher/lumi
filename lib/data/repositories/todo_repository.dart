import '../models/todo_model.dart';
import '../database/app_database.dart';

class TodoRepository {
  final AppDatabase? _db;
  final List<TodoModel>? _memory;

  TodoRepository(AppDatabase db)
      : _db = db,
        _memory = null;

  TodoRepository.memory()
      : _db = null,
        _memory = _sampleTodos();

  static const _table = 'todos';

  Future<List<TodoModel>> getAll() async {
    if (_memory != null) return List.unmodifiable(_memory);
    final db = await _db!.database;
    final maps = await db.query(_table, orderBy: 'created_at DESC');
    return maps.map(TodoModel.fromMap).toList();
  }

  Future<void> insert(TodoModel todo) async {
    if (_memory != null) {
      _memory.insert(0, todo);
      return;
    }
    final db = await _db!.database;
    await db.insert(_table, todo.toMap());
  }

  Future<void> update(TodoModel todo) async {
    if (_memory != null) {
      final i = _memory.indexWhere((t) => t.id == todo.id);
      if (i != -1) _memory[i] = todo;
      return;
    }
    final db = await _db!.database;
    await db.update(
      _table,
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> delete(String id) async {
    if (_memory != null) {
      _memory.removeWhere((t) => t.id == id);
      return;
    }
    final db = await _db!.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateStatus(String id, TodoStatus status) async {
    final now = DateTime.now();
    final completedAt = status == TodoStatus.done ? now.millisecondsSinceEpoch : null;

    if (_memory != null) {
      final i = _memory.indexWhere((t) => t.id == id);
      if (i != -1) {
        _memory[i] = _memory[i].copyWith(
          status: status,
          updatedAt: now,
          completedAt: status == TodoStatus.done ? now : null,
          clearCompletedAt: status != TodoStatus.done,
        );
      }
      return;
    }
    final db = await _db!.database;
    await db.update(
      _table,
      {
        'status': status.name,
        'updated_at': now.millisecondsSinceEpoch,
        'completed_at': completedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static List<TodoModel> _sampleTodos() {
    final now = DateTime.now();
    final done = now.subtract(const Duration(days: 2));

    TodoModel make(
      String id,
      String title,
      TodoStatus status,
      Priority priority,
      int order, {
      DateTime? completedAt,
    }) {
      final created = now.subtract(Duration(minutes: order));
      return TodoModel(
        id: id,
        title: title,
        status: status,
        priority: priority,
        createdAt: created,
        updatedAt: created,
        completedAt: completedAt,
      );
    }

    return [
      make('sample-1', 'Design onboarding flow', TodoStatus.todo, Priority.high, 1),
      make('sample-2', 'Write API documentation', TodoStatus.todo, Priority.medium, 2),
      make('sample-3', 'Kanban board component', TodoStatus.doing, Priority.high, 3),
      make('sample-4', 'Integrate push notifications', TodoStatus.doing, Priority.low, 4),
      make('sample-8', 'Accessibility audit', TodoStatus.todo, Priority.low, 5),
      make('sample-5', 'Set up CI/CD pipeline', TodoStatus.done, Priority.low, 6, completedAt: done),
      make('sample-6', 'Color token system', TodoStatus.done, Priority.medium, 7, completedAt: done.subtract(const Duration(days: 1))),
      make('sample-7', 'Review pull requests', TodoStatus.done, Priority.medium, 8, completedAt: done.add(const Duration(days: 1))),
    ];
  }
}
