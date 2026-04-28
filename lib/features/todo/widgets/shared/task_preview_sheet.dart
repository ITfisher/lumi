import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/markdown_editor.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';
import 'task_labels.dart';

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
  late TodoStatus _status;
  late Priority _priority;
  late Set<String> _selectedLabels;
  String _currentNotes = '';
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _savedTodo = widget.todo;
    _titleCtrl = TextEditingController(text: widget.todo.title);
    _titleCtrl.addListener(_updateDirtyState);
    _notesCtrl = MarkdownEditorController();
    _status = widget.todo.status;
    _priority = widget.todo.priority;
    _selectedLabels = {...widget.todo.labels};
    _currentNotes = (widget.todo.notes ?? '').trim();
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
    final configuredLabelsAsync = ref.watch(taskLabelConfigProvider);
    final availableLabels = configuredLabelsAsync.maybeWhen(
      data: (labels) => TodoModel.normalizeLabels([
        ...labels,
        ..._selectedLabels,
      ]),
      orElse: () => TodoModel.normalizeLabels(_selectedLabels),
    );
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title + action buttons in one row — no wasted top whitespace
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TitleEditor(controller: _titleCtrl),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isDirty) ...[
                          _SaveIconButton(onTap: () => _save(currentTodo)),
                          const SizedBox(width: 8),
                        ],
                        _RoundIconButton(
                          tooltip: 'Task details',
                          icon: Icons.open_in_new_rounded,
                          color: AppTheme.accentBlueDeep,
                          background:
                              AppTheme.accentBlue.withValues(alpha: 0.14),
                          onTap: () => _openDetails(context, currentTodo),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Single inline row: status ▼ + priority ▼ + label chips
                _InlineProperties(
                  status: _status,
                  priority: _priority,
                  labels: availableLabels,
                  selectedLabels: _selectedLabels,
                  onStatusChanged: (status) {
                    if (status == _status) return;
                    setState(() => _status = status);
                    _updateDirtyState();
                  },
                  onPriorityChanged: (priority) {
                    if (priority == _priority) return;
                    setState(() => _priority = priority);
                    _updateDirtyState();
                  },
                  onLabelToggle: (label) {
                    setState(() {
                      if (_selectedLabels.contains(label)) {
                        _selectedLabels.remove(label);
                      } else {
                        _selectedLabels.add(label);
                      }
                    });
                    _updateDirtyState();
                  },
                ),
                const SizedBox(height: 16),
                MarkdownEditor(
                  initialMarkdown: currentTodo.notes,
                  controller: _notesCtrl,
                  onChanged: (value) {
                    _currentNotes = value.trim();
                    _updateDirtyState();
                  },
                  height: screenSize.height >= 900 ? 420 : 360,
                ),
                const SizedBox(height: 10),
                // Minimal creation timestamp
                Text(
                  'Created ${DateFormat('MMM d, yyyy').format(currentTodo.createdAt)}',
                  style: AppTheme.body(
                    size: 11,
                    color: AppTheme.fgTertiary,
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.right,
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
    final notesChanged = _currentNotes != (_savedTodo.notes ?? '').trim();
    final statusChanged = _status != _savedTodo.status;
    final priorityChanged = _priority != _savedTodo.priority;
    final labelsChanged =
        !setEquals(_selectedLabels, _savedTodo.labels.toSet());
    final next = titleChanged ||
        notesChanged ||
        statusChanged ||
        priorityChanged ||
        labelsChanged;
    if (next != _isDirty) {
      setState(() => _isDirty = next);
    }
  }

  void _save(TodoModel currentTodo) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    final notes = _currentNotes;
    final updated = currentTodo.copyWith(
      title: title,
      notes: notes.isEmpty ? null : notes,
      clearNotes: notes.isEmpty,
      status: _status,
      priority: _priority,
      labels: _selectedLabels.toList(),
      completedAt: _status == TodoStatus.done
          ? (currentTodo.completedAt ?? DateTime.now())
          : null,
      clearCompletedAt: _status != TodoStatus.done,
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

// ──────────────────────────────────────────────────────────────────
// Title editor (large, borderless)
// ──────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────
// Inline properties — status ▼ + priority ▼ + labels, all in a Wrap
// Replaces the previous separate _PropertyEditors + _MetaWrap combo.
// ──────────────────────────────────────────────────────────────────
class _InlineProperties extends StatelessWidget {
  final TodoStatus status;
  final Priority priority;
  final List<String> labels;
  final Set<String> selectedLabels;
  final ValueChanged<TodoStatus> onStatusChanged;
  final ValueChanged<Priority> onPriorityChanged;
  final ValueChanged<String> onLabelToggle;

  const _InlineProperties({
    required this.status,
    required this.priority,
    required this.labels,
    required this.selectedLabels,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onLabelToggle,
  });

  static Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return AppTheme.statusOverdue;
      case Priority.medium:
        return AppTheme.statusActiveDeep;
      case Priority.low:
        return AppTheme.statusDoneDeep;
    }
  }

  static Color _statusColor(TodoStatus s) {
    switch (s) {
      case TodoStatus.todo:
        return AppTheme.fgTertiary;
      case TodoStatus.doing:
        return AppTheme.statusActiveDeep;
      case TodoStatus.done:
        return AppTheme.statusDoneDeep;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _PropertyMenu<TodoStatus>(
          icon: Icons.radio_button_checked_rounded,
          value: status,
          options: TodoStatus.values,
          label: (s) => s.label,
          color: _statusColor,
          onSelected: onStatusChanged,
        ),
        _PropertyMenu<Priority>(
          icon: Icons.flag_rounded,
          value: priority,
          options: Priority.values,
          label: (p) => p.label,
          color: _priorityColor,
          onSelected: onPriorityChanged,
        ),
        for (final label in labels)
          SelectableTaskLabelChip(
            label: label,
            selected: selectedLabels.contains(label),
            onTap: () => onLabelToggle(label),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Popup chip for status / priority selection
// ──────────────────────────────────────────────────────────────────
class _PropertyMenu<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<T> options;
  final String Function(T) label;
  final Color Function(T) color;
  final ValueChanged<T> onSelected;

  const _PropertyMenu({
    required this.icon,
    required this.value,
    required this.options,
    required this.label,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentColor = color(value);

    return PopupMenuButton<T>(
      onSelected: onSelected,
      tooltip: 'Change ${label(value)}',
      color: AppTheme.glassMenuFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.glassBorderMedium),
      ),
      itemBuilder: (_) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option,
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color(option),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label(option),
                  style: AppTheme.body(
                    size: 13,
                    weight: option == value ? FontWeight.w700 : FontWeight.w500,
                    color:
                        option == value ? color(option) : AppTheme.fgSecondary,
                  ),
                ),
                const Spacer(),
                if (option == value)
                  Icon(Icons.check_rounded, size: 14, color: color(option)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: currentColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: currentColor.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: currentColor),
            const SizedBox(width: 5),
            Text(
              label(value),
              style: AppTheme.body(
                size: 12,
                weight: FontWeight.w600,
                color: currentColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.unfold_more_rounded,
              size: 13,
              color: currentColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Save icon button (gradient circle)
// ──────────────────────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────────────────────
// Round icon button
// ──────────────────────────────────────────────────────────────────
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
