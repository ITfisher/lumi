import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/markdown_editor.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';
import 'task_labels.dart';

/// "Add task / Edit task" modal.
///
/// • [isDialog] true  → shown as a centred dialog (new task via FAB)
/// • [isDialog] false → shown as a bottom sheet (edit task)
class TodoFormSheet extends ConsumerStatefulWidget {
  final TodoModel? todo;
  final bool isDialog;
  const TodoFormSheet({super.key, this.todo, this.isDialog = false});

  @override
  ConsumerState<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends ConsumerState<TodoFormSheet> {
  late final TextEditingController _titleCtrl;
  late final MarkdownEditorController _notesCtrl;
  late Priority _priority;
  late Set<String> _selectedLabels;
  bool _isDirty = false;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.todo?.title ?? '');
    _titleCtrl.addListener(_markDirty);
    _notesCtrl = MarkdownEditorController();
    _priority = widget.todo?.priority ?? Priority.medium;
    _selectedLabels = {...widget.todo?.labels ?? const <String>[]};
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_markDirty);
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configuredLabelsAsync = ref.watch(taskLabelConfigProvider);
    final availableLabels = configuredLabelsAsync.maybeWhen(
      data: (labels) => TodoModel.normalizeLabels([
        ...labels,
        ..._selectedLabels,
      ]),
      orElse: () => TodoModel.normalizeLabels(_selectedLabels),
    );
    final isDialog = widget.isDialog;
    final screenSize = MediaQuery.sizeOf(context);
    final bottomInset =
        isDialog ? 0.0 : MediaQuery.of(context).viewInsets.bottom;
    final radius = isDialog
        ? BorderRadius.circular(20)
        : const BorderRadius.vertical(top: Radius.circular(24));
    final maxWidth = isDialog ? 720.0 : 780.0;
    final maxHeight = screenSize.height * (isDialog ? 0.84 : 0.9);
    final editorHeight = isDialog ? 320.0 : 360.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassModalFill,
              borderRadius: radius,
              border: Border.all(color: AppTheme.glassBorderLight, width: 1),
              boxShadow: AppTheme.shadowElevated,
            ),
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    title: _isEditing ? 'Edit task' : 'New task',
                    isEditing: _isEditing,
                    onClose: () => Navigator.pop(context),
                    onDetail: _isEditing
                        ? () {
                            ref.read(navPageProvider.notifier).state =
                                NavPage.tasks;
                            ref.read(selectedTaskIdProvider.notifier).state =
                                widget.todo!.id;
                            Navigator.pop(context);
                          }
                        : null,
                    onDelete: _isEditing
                        ? () {
                            ref
                                .read(todoProvider.notifier)
                                .delete(widget.todo!.id);
                            Navigator.pop(context);
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _TitleField(controller: _titleCtrl, autofocus: !_isEditing),
                  const SizedBox(height: 10),
                  MarkdownEditor(
                    initialMarkdown: widget.todo?.notes,
                    controller: _notesCtrl,
                    onChanged: (_) => _markDirty(),
                    height: editorHeight,
                  ),
                  const SizedBox(height: 12),
                  // Compact inline bar: priority chips + label chips, no section headers
                  _AttributesBar(
                    priority: _priority,
                    labels: availableLabels,
                    selectedLabels: _selectedLabels,
                    loading: configuredLabelsAsync.isLoading,
                    onPriorityChanged: (p) {
                      if (p == _priority) return;
                      setState(() => _priority = p);
                      _markDirty();
                    },
                    onLabelToggle: (label) {
                      setState(() {
                        if (_selectedLabels.contains(label)) {
                          _selectedLabels.remove(label);
                        } else {
                          _selectedLabels.add(label);
                        }
                      });
                      _markDirty();
                    },
                    onOpenProfile: () {
                      ref.read(navPageProvider.notifier).state = NavPage.me;
                      Navigator.pop(context);
                    },
                  ),
                  if (!_isEditing || _isDirty) ...[
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: _isEditing ? 'Save changes' : 'Add task',
                      onTap: _save,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final notes = _notesCtrl.markdown;

    if (_isEditing) {
      ref.read(todoProvider.notifier).updateTodo(
            widget.todo!.copyWith(
              title: title,
              notes: notes.isEmpty ? null : notes,
              labels: _selectedLabels.toList(),
              clearNotes: notes.isEmpty,
              priority: _priority,
              updatedAt: DateTime.now(),
            ),
          );
    } else {
      ref.read(todoProvider.notifier).add(
            TodoModel.create(
              title: title,
              notes: notes.isEmpty ? null : notes,
              labels: _selectedLabels.toList(),
              priority: _priority,
            ),
          );
    }
    Navigator.pop(context);
  }
}

// ──────────────────────────────────────────────────────────────────
// Header
// ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String title;
  final bool isEditing;
  final VoidCallback onClose;
  final VoidCallback? onDetail;
  final VoidCallback? onDelete;

  const _Header({
    required this.title,
    required this.isEditing,
    required this.onClose,
    this.onDetail,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTheme.display(
            size: 18,
            weight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (onDetail != null) ...[
          _RoundIconButton(
            tooltip: 'Task details',
            icon: Icons.open_in_new_rounded,
            color: AppTheme.accentBlueDeep,
            background: AppTheme.accentBlue.withValues(alpha: 0.14),
            onTap: onDetail!,
          ),
          const SizedBox(width: 8),
        ],
        if (onDelete != null) ...[
          _RoundIconButton(
            tooltip: 'Delete task',
            icon: Icons.delete_outline_rounded,
            color: AppTheme.statusOverdue,
            background: AppTheme.statusOverdue.withValues(alpha: 0.10),
            onTap: onDelete!,
          ),
          const SizedBox(width: 8),
        ],
        _RoundIconButton(
          tooltip: 'Close',
          icon: Icons.close_rounded,
          color: AppTheme.fgSecondary,
          background: const Color(0x12000000),
          onTap: onClose,
        ),
      ],
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

// ──────────────────────────────────────────────────────────────────
// Title input (large glass field)
// ──────────────────────────────────────────────────────────────────
class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  const _TitleField({required this.controller, required this.autofocus});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x99FFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        cursorColor: AppTheme.accentBlue,
        style: AppTheme.body(size: 16, weight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Task name…',
          hintStyle: AppTheme.body(
            size: 16,
            color: AppTheme.fgTertiary,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Attributes bar — priority chips + label chips inline, no headers
// ──────────────────────────────────────────────────────────────────
class _AttributesBar extends StatelessWidget {
  final Priority priority;
  final List<String> labels;
  final Set<String> selectedLabels;
  final bool loading;
  final ValueChanged<Priority> onPriorityChanged;
  final ValueChanged<String> onLabelToggle;
  final VoidCallback? onOpenProfile;

  const _AttributesBar({
    required this.priority,
    required this.labels,
    required this.selectedLabels,
    required this.loading,
    required this.onPriorityChanged,
    required this.onLabelToggle,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final p in Priority.values)
          _PriorityChip(
            priority: p,
            active: priority == p,
            onTap: () => onPriorityChanged(p),
          ),
        if (!loading)
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
// Compact priority chip — dot indicator + short label
// ──────────────────────────────────────────────────────────────────
class _PriorityChip extends StatelessWidget {
  final Priority priority;
  final bool active;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.priority,
    required this.active,
    required this.onTap,
  });

  Color get _color {
    switch (priority) {
      case Priority.high:
        return AppTheme.statusOverdue;
      case Priority.medium:
        return AppTheme.statusActiveDeep;
      case Priority.low:
        return AppTheme.statusDoneDeep;
    }
  }

  String get _label {
    switch (priority) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Med';
      case Priority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? _color.withValues(alpha: 0.14)
              : const Color(0x80FFFFFF),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: active
                ? _color.withValues(alpha: 0.55)
                : AppTheme.glassBorderMedium,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _color.withValues(alpha: 0.45),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _label,
              style: AppTheme.body(
                size: 12,
                weight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? _color : AppTheme.fgSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Primary action button — gradient + blue glow
// ──────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
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
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.body(
            size: 16,
            weight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
