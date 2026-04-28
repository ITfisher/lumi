import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/markdown_editor.dart';
import '../../../data/models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../widgets/shared/task_labels.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTodo = ref.watch(todoProvider).maybeWhen(
          data: (todos) => _findTodo(todos, taskId),
          orElse: () => null,
        );

    return currentTodo == null
        ? const _DeletedState()
        // Keyed by id so internal editing state is reset when navigating
        // between different tasks.
        : _DetailBody(key: ValueKey(currentTodo.id), todo: currentTodo);
  }

  TodoModel? _findTodo(List<TodoModel> todos, String id) {
    for (final item in todos) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  final TodoModel todo;

  const _DetailBody({super.key, required this.todo});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  late final TextEditingController _titleCtrl;
  late final MarkdownEditorController _notesCtrl;

  late String _baselineTitle;
  late String _baselineNotes;
  late TodoStatus _baselineStatus;
  late Priority _baselinePriority;
  late Set<String> _baselineLabels;
  late TodoStatus _status;
  late Priority _priority;
  late Set<String> _selectedLabels;
  String _currentNotes = '';
  bool _isDirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _baselineTitle = widget.todo.title;
    _baselineNotes = (widget.todo.notes ?? '').trim();
    _baselineStatus = widget.todo.status;
    _baselinePriority = widget.todo.priority;
    _baselineLabels = {...widget.todo.labels};
    _currentNotes = _baselineNotes;
    _status = _baselineStatus;
    _priority = _baselinePriority;
    _selectedLabels = {..._baselineLabels};
    _titleCtrl = TextEditingController(text: _baselineTitle);
    _titleCtrl.addListener(_recomputeDirty);
    _notesCtrl = MarkdownEditorController();
  }

  @override
  void didUpdateWidget(covariant _DetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the underlying todo refreshes from the store (e.g. after a save
    // somewhere else), refresh the baseline so we don't keep showing dirty.
    if (!_isDirty && !_saving) {
      final newTitle = widget.todo.title;
      final newNotes = (widget.todo.notes ?? '').trim();
      final newStatus = widget.todo.status;
      final newPriority = widget.todo.priority;
      final newLabels = widget.todo.labels.toSet();
      if (newTitle != _baselineTitle) {
        _baselineTitle = newTitle;
        _titleCtrl.text = newTitle;
      }
      if (newNotes != _baselineNotes) {
        _baselineNotes = newNotes;
        _currentNotes = newNotes;
      }
      _baselineStatus = newStatus;
      _baselinePriority = newPriority;
      _baselineLabels = {...newLabels};
      _status = newStatus;
      _priority = newPriority;
      _selectedLabels = newLabels;
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_recomputeDirty);
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onNotesChanged(String md) {
    _currentNotes = md;
    _recomputeDirty();
  }

  void _recomputeDirty() {
    final titleChanged = _titleCtrl.text.trim() != _baselineTitle.trim();
    final notesChanged = _currentNotes.trim() != _baselineNotes.trim();
    final statusChanged = _status != _baselineStatus;
    final priorityChanged = _priority != _baselinePriority;
    final labelsChanged = !setEquals(_selectedLabels, _baselineLabels);
    final dirty = titleChanged ||
        notesChanged ||
        statusChanged ||
        priorityChanged ||
        labelsChanged;
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final notes = _currentNotes.trim();

    setState(() => _saving = true);
    try {
      await ref.read(todoProvider.notifier).updateTodo(
            widget.todo.copyWith(
              title: title,
              notes: notes.isEmpty ? null : notes,
              clearNotes: notes.isEmpty,
              status: _status,
              priority: _priority,
              labels: _selectedLabels.toList(),
              completedAt: _status == TodoStatus.done
                  ? (widget.todo.completedAt ?? DateTime.now())
                  : null,
              clearCompletedAt: _status != TodoStatus.done,
              updatedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _baselineTitle = title;
        _baselineNotes = notes;
        _baselineStatus = _status;
        _baselinePriority = _priority;
        _baselineLabels = {..._selectedLabels};
        _isDirty = false;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pinned header — does not scroll with content.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: _TopRow(
            todo: widget.todo,
            isDirty: _isDirty,
            saving: _saving,
            onSave: _save,
            onBack: () =>
                ref.read(selectedTaskIdProvider.notifier).state = null,
            onDelete: () {
              ref.read(todoProvider.notifier).delete(widget.todo.id);
              ref.read(selectedTaskIdProvider.notifier).state = null;
            },
          ),
        ),
        // Scrollable content fills available width.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            children: [
              GlassContainer(
                surface: GlassSurface.modal,
                borderRadius: AppTheme.radiusLg,
                padding: const EdgeInsets.all(24),
                shadow: AppTheme.shadowElevated,
                child: _DetailContent(
                  todo: widget.todo,
                  titleController: _titleCtrl,
                  notesController: _notesCtrl,
                  initialNotes: _baselineNotes,
                  onNotesChanged: _onNotesChanged,
                  status: _status,
                  priority: _priority,
                  selectedLabels: _selectedLabels,
                  onStatusChanged: (status) {
                    if (status == _status) return;
                    setState(() => _status = status);
                    _recomputeDirty();
                  },
                  onPriorityChanged: (priority) {
                    if (priority == _priority) return;
                    setState(() => _priority = priority);
                    _recomputeDirty();
                  },
                  onLabelToggle: (label) {
                    setState(() {
                      if (_selectedLabels.contains(label)) {
                        _selectedLabels.remove(label);
                      } else {
                        _selectedLabels.add(label);
                      }
                    });
                    _recomputeDirty();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailContent extends StatelessWidget {
  final TodoModel todo;
  final TextEditingController titleController;
  final MarkdownEditorController notesController;
  final String initialNotes;
  final ValueChanged<String> onNotesChanged;
  final TodoStatus status;
  final Priority priority;
  final Set<String> selectedLabels;
  final ValueChanged<TodoStatus> onStatusChanged;
  final ValueChanged<Priority> onPriorityChanged;
  final ValueChanged<String> onLabelToggle;

  const _DetailContent({
    required this.todo,
    required this.titleController,
    required this.notesController,
    required this.initialNotes,
    required this.onNotesChanged,
    required this.status,
    required this.priority,
    required this.selectedLabels,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onLabelToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final textPane = _TextPane(
          titleController: titleController,
          notesController: notesController,
          initialNotes: initialNotes,
          onNotesChanged: onNotesChanged,
        );
        final properties = _PropertiesPanel(
          todo: todo,
          status: status,
          priority: priority,
          selectedLabels: selectedLabels,
          onStatusChanged: onStatusChanged,
          onPriorityChanged: onPriorityChanged,
          onLabelToggle: onLabelToggle,
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textPane,
              const SizedBox(height: 24),
              properties,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textPane),
            const SizedBox(width: 28),
            SizedBox(width: 240, child: properties),
          ],
        );
      },
    );
  }
}

class _TextPane extends StatelessWidget {
  final TextEditingController titleController;
  final MarkdownEditorController notesController;
  final String initialNotes;
  final ValueChanged<String> onNotesChanged;

  const _TextPane({
    required this.titleController,
    required this.notesController,
    required this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleEditor(controller: titleController),
        const SizedBox(height: 28),
        Text('FILE CONTENT', style: AppTheme.label(size: 10)),
        const SizedBox(height: 10),
        MarkdownEditor(
          initialMarkdown: initialNotes,
          controller: notesController,
          onChanged: onNotesChanged,
          height: 420,
        ),
      ],
    );
  }
}

class _TitleEditor extends StatelessWidget {
  final TextEditingController controller;

  const _TitleEditor({required this.controller});

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.display(
      size: 30,
      weight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.12,
    );
    return TextField(
      controller: controller,
      cursorColor: AppTheme.accentBlue,
      maxLines: null,
      style: style,
      decoration: InputDecoration(
        hintText: 'Task name…',
        hintStyle: style.copyWith(color: AppTheme.fgTertiary),
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final TodoModel todo;
  final bool isDirty;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _TopRow({
    required this.todo,
    required this.isDirty,
    required this.saving,
    required this.onSave,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundAction(
          tooltip: 'Back',
          icon: Icons.arrow_back_rounded,
          color: AppTheme.fgSecondary,
          background: const Color(0x80FFFFFF),
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task details',
                style: AppTheme.display(
                  size: 22,
                  weight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                todo.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.mono(size: 11, color: AppTheme.fgTertiary),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: AppTheme.durStd,
          switchInCurve: AppTheme.easeStandard,
          switchOutCurve: AppTheme.easeStandard,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: anim, child: child),
          ),
          child: isDirty
              ? Padding(
                  key: const ValueKey('save'),
                  padding: const EdgeInsets.only(right: 8),
                  child: _SaveButton(saving: saving, onTap: onSave),
                )
              : const SizedBox.shrink(key: ValueKey('no-save')),
        ),
        _RoundAction(
          tooltip: 'Delete task',
          icon: Icons.delete_outline_rounded,
          color: AppTheme.statusOverdue,
          background: AppTheme.statusOverdue.withValues(alpha: 0.10),
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;

  const _SaveButton({required this.saving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Save changes',
      child: GestureDetector(
        onTap: saving ? null : onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentBlue.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saving)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              const SizedBox(width: 6),
              Text(
                saving ? 'Saving…' : 'Save',
                style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Properties panel — compact chips for status/priority + label wrap
// ──────────────────────────────────────────────────────────────────
class _PropertiesPanel extends ConsumerWidget {
  final TodoModel todo;
  final TodoStatus status;
  final Priority priority;
  final Set<String> selectedLabels;
  final ValueChanged<TodoStatus> onStatusChanged;
  final ValueChanged<Priority> onPriorityChanged;
  final ValueChanged<String> onLabelToggle;

  const _PropertiesPanel({
    required this.todo,
    required this.status,
    required this.priority,
    required this.selectedLabels,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onLabelToggle,
  });

  static final _fmt = DateFormat('MMM d, yyyy h:mm a');

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
  Widget build(BuildContext context, WidgetRef ref) {
    final configuredLabelsAsync = ref.watch(taskLabelConfigProvider);
    final availableLabels = configuredLabelsAsync.maybeWhen(
      data: (labels) => TodoModel.normalizeLabels([
        ...labels,
        ...selectedLabels,
      ]),
      orElse: () => TodoModel.normalizeLabels(selectedLabels),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status + Priority as compact popup chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PropChip<TodoStatus>(
              icon: Icons.radio_button_checked_rounded,
              value: status,
              options: TodoStatus.values,
              label: (s) => s.label,
              color: _statusColor,
              onSelected: onStatusChanged,
            ),
            _PropChip<Priority>(
              icon: Icons.flag_rounded,
              value: priority,
              options: Priority.values,
              label: (p) => p.label,
              color: _priorityColor,
              onSelected: onPriorityChanged,
            ),
          ],
        ),
        // Labels — inline selectable chips, no section header
        if (configuredLabelsAsync.isLoading && availableLabels.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Loading labels…',
              style: AppTheme.body(size: 12, color: AppTheme.fgTertiary),
            ),
          )
        else if (availableLabels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in availableLabels)
                SelectableTaskLabelChip(
                  label: label,
                  selected: selectedLabels.contains(label),
                  onTap: () => onLabelToggle(label),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        // Thin divider before timestamps
        Container(height: 1, color: const Color(0x18000000)),
        const SizedBox(height: 12),
        // Read-only timestamps
        _MetaRow(
          icon: Icons.add_circle_outline_rounded,
          label: 'Created',
          value: _fmt.format(todo.createdAt),
          color: AppTheme.fgTertiary,
        ),
        const SizedBox(height: 6),
        _MetaRow(
          icon: Icons.update_rounded,
          label: 'Updated',
          value: _fmt.format(todo.updatedAt),
          color: AppTheme.accentBlueDeep,
        ),
        if (todo.completedAt != null || status == TodoStatus.done) ...[
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Completed',
            value: _fmt.format(todo.completedAt ?? DateTime.now()),
            color: AppTheme.statusDoneDeep,
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Compact popup chip — replaces the old card-style _EditableTile
// ──────────────────────────────────────────────────────────────────
class _PropChip<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<T> options;
  final String Function(T) label;
  final Color Function(T) color;
  final ValueChanged<T> onSelected;

  const _PropChip({
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
      tooltip: 'Change ${label(value)}',
      offset: const Offset(0, 8),
      color: AppTheme.glassMenuFill,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: const BorderSide(color: AppTheme.glassBorderMedium),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final opt in options)
          PopupMenuItem<T>(
            value: opt,
            height: 36,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color(opt),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label(opt),
                  style: AppTheme.body(
                    size: 13,
                    weight: opt == value ? FontWeight.w700 : FontWeight.w500,
                    color: opt == value ? color(opt) : AppTheme.fgSecondary,
                  ),
                ),
                const Spacer(),
                if (opt == value)
                  Icon(Icons.check_rounded, size: 14, color: color(opt)),
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
            Icon(Icons.unfold_more_rounded, size: 13, color: currentColor),
          ],
        ),
      ),
    );
  }
}

/// A compact metadata row used for read-only timestamps.
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTheme.label(size: 10),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTheme.body(
                size: 11,
                weight: FontWeight.w500,
                color: AppTheme.fgSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedState extends StatelessWidget {
  const _DeletedState();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Center(
        child: GlassContainer(
          surface: GlassSurface.modal,
          borderRadius: AppTheme.radiusLg,
          padding: const EdgeInsets.all(24),
          shadow: AppTheme.shadowElevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 26,
                color: AppTheme.statusOverdue,
              ),
              const SizedBox(height: 12),
              Text(
                'Task was deleted',
                style: AppTheme.display(size: 18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    ref.read(selectedTaskIdProvider.notifier).state = null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x80FFFFFF),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(color: AppTheme.glassBorderMedium),
                  ),
                  child: Text(
                    'Back',
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppTheme.fgSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _RoundAction({
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.glassBorderLight),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
