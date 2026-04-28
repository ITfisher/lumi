import 'dart:convert';

import 'package:uuid/uuid.dart';

enum TodoStatus { todo, doing, done }

enum Priority { high, medium, low }

extension TodoStatusX on TodoStatus {
  String get label {
    switch (this) {
      case TodoStatus.todo:
        return 'Todo';
      case TodoStatus.doing:
        return 'Doing';
      case TodoStatus.done:
        return 'Done';
    }
  }

  TodoStatus get next {
    switch (this) {
      case TodoStatus.todo:
        return TodoStatus.doing;
      case TodoStatus.doing:
        return TodoStatus.done;
      case TodoStatus.done:
        return TodoStatus.done;
    }
  }

  TodoStatus get previous {
    switch (this) {
      case TodoStatus.todo:
        return TodoStatus.todo;
      case TodoStatus.doing:
        return TodoStatus.todo;
      case TodoStatus.done:
        return TodoStatus.doing;
    }
  }
}

extension PriorityX on Priority {
  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }
}

class TodoModel {
  final String id;
  final String title;
  final String? notes;
  final List<String> labels;
  final TodoStatus status;
  final Priority priority;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  TodoModel({
    required this.id,
    required this.title,
    this.notes,
    List<String> labels = const [],
    required this.status,
    required this.priority,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  }) : labels = List.unmodifiable(normalizeLabels(labels));

  factory TodoModel.create({
    required String title,
    String? notes,
    List<String> labels = const [],
    Priority priority = Priority.medium,
    DateTime? deadline,
  }) {
    final now = DateTime.now();
    return TodoModel(
      id: const Uuid().v4(),
      title: title,
      notes: notes,
      labels: labels,
      status: TodoStatus.todo,
      priority: priority,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? notes,
    bool clearNotes = false,
    List<String>? labels,
    bool clearLabels = false,
    TodoStatus? status,
    Priority? priority,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      labels: clearLabels ? const [] : (labels ?? this.labels),
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'labels': jsonEncode(labels),
      'status': status.name,
      'priority': priority.name,
      'deadline': deadline?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      labels: _decodeLabels(map['labels']),
      status: TodoStatus.values.firstWhere((e) => e.name == map['status']),
      priority: Priority.values.firstWhere((e) => e.name == map['priority']),
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
    );
  }

  static List<String> normalizeLabels(Iterable<String> labels) {
    final seen = <String>{};
    final normalized = <String>[];

    for (final raw in labels) {
      final value = raw.trim();
      if (value.isEmpty) continue;

      final key = value.toLowerCase();
      if (!seen.add(key)) continue;
      normalized.add(value);
    }

    return normalized;
  }

  static List<String> _decodeLabels(dynamic rawLabels) {
    if (rawLabels == null) return const [];
    if (rawLabels is List) {
      return normalizeLabels(rawLabels.whereType<String>());
    }
    if (rawLabels is! String || rawLabels.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(rawLabels);
      if (decoded is List) {
        return normalizeLabels(decoded.whereType<String>());
      }
    } catch (_) {
      return normalizeLabels(rawLabels.split(','));
    }

    return const [];
  }
}
