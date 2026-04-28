import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/markdown_editor.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';

class TaskPreviewSheet extends ConsumerStatefulWidget {
  final TodoModel todo;

  const TaskPreviewSheet({super.key, required this.todo});

  @override
  ConsumerState<TaskPreviewSheet> createState() => _TaskPreviewSheetState();
}

class _TaskPreviewSheetState extends ConsumerState<TaskPreviewSheet> {
  late TodoModel _savedTodo;
  late final TextEditingController _titleCtrl;
  late final MarkdownEditorController _notesCtrl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _savedTodo = widget.todo;
    _titleCtrl = TextEditingController(text: widget.todo.title);
    _titleCtrl.addListener(_updateDirtyState);
    _notesCtrl = MarkdownEditorController();
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_updateDirtyState);
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final currentTodo = ref.watch(todoProvider).maybeWhen(
          data: (todos) => _findTodo(todos, widget.todo.id),
          orElse: () => _savedTodo,
        );

    if (currentTodo == null) {
      return const SizedBox.shrink();
    }

    final radius = BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: screenSize.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppTheme.glassModalFill,
            borderRadius: radius,
            border: Border.all(color: AppTheme.glassBorderLight, width: 1),
            boxShadow: AppTheme.shadowElevated,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top action row: save (when dirty) + open-details, no title
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isDirty) ...[
                      _SaveIconButton(onTap: () => _save(currentTodo)),
                      const SizedBox(width: 8),
                    ],
                    _RoundIconButton(
                      tooltip: 'Task details',
                      icon: Icons.open_in_new_rounded,
                      color: AppTheme.accentBlueDeep,
                      background: AppTheme.accentBlue.withValues(alpha: 0.14),
                      onTap: () => _openDetails(context, currentTodo),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TitleEditor(controller: _titleCtrl),
                const SizedBox(height: 12),
                _MetaWrap(todo: currentTodo),
                const SizedBox(height: 18),
                MarkdownEditor(
                  initialMarkdown: currentTodo.notes,
                  controller: _notesCtrl,
                  onChanged: (_) => _updateDirtyState(),
                  height: screenSize.height >= 900 ? 420 : 360,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateDirtyState() {
    final titleChanged = _titleCtrl.text.trim() != _savedTodo.title;
    final notesChanged = _notesCtrl.markdown != (_savedTodo.notes ?? '').trim();
    final next = titleChanged || notesChanged;
    if (next != _isDirty) {
      setState(() => _isDirty = next);
    }
  }

  void _save(TodoModel currentTodo) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final notes = _notesCtrl.markdown;
    final updated = currentTodo.copyWith(
      title: title,
      notes: notes.isEmpty ? null : notes,
      clearNotes: notes.isEmpty,
      updatedAt: DateTime.now(),
    );

    ref.read(todoProvider.notifier).updateTodo(updated);
    setState(() {
      _savedTodo = updated;
      _isDirty = false;
    });
  }

  void _openDetails(BuildContext context, TodoModel todo) {
    ref.read(navPageProvider.notifier).state = NavPage.tasks;
    ref.read(selectedTaskIdProvider.notifier).state = todo.id;
    Navigator.pop(context);
  }

  TodoModel? _findTodo(List<TodoModel> todos, String id) {
    for (final item in todos) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class _TitleEditor extends StatelessWidget {
  final TextEditingController controller;

  const _TitleEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: AppTheme.accentBlue,
      maxLines: null,
      style: AppTheme.display(
        size: 22,
        weight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.15,
      ),
      decoration: InputDecoration(
        hintText: 'Task name...',
        hintStyle: AppTheme.display(
          size: 22,
          weight: FontWeight.w700,
          color: AppTheme.fgTertiary,
          letterSpacing: -0.4,
          height: 1.15,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _MetaWrap extends StatelessWidget {
  final TodoModel todo;

  const _MetaWrap({required this.todo});

  static final _fmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaPill(
          icon: Icons.flag_rounded,
          label: todo.priority.label,
          color: _priorityColor(todo.priority),
        ),
        _MetaPill(
          icon: Icons.radio_button_checked_rounded,
          label: todo.status.label,
          color: _statusColor(todo.status),
        ),
        _MetaPill(
          icon: Icons.add_circle_outline_rounded,
          label: _fmt.format(todo.createdAt),
          color: AppTheme.fgTertiary,
        ),
      ],
    );
  }

  Color _priorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppTheme.statusOverdue;
      case Priority.medium:
        return AppTheme.statusActiveDeep;
      case Priority.low:
        return AppTheme.statusDoneDeep;
    }
  }

  Color _statusColor(TodoStatus status) {
    switch (status) {
      case TodoStatus.todo:
        return AppTheme.fgTertiary;
      case TodoStatus.doing:
        return AppTheme.statusActiveDeep;
      case TodoStatus.done:
        return AppTheme.statusDoneDeep;
    }
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.body(
              size: 12,
              weight: FontWeight.w600,
              color: color,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SaveIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Save changes',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.38),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
