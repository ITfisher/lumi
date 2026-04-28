import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/markdown_utils.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';
import '../shared/task_preview_sheet.dart';

/// Single task row in the list.
///
/// Layout: [Checkbox] [Title + meta line] (delete button on hover only)
/// Swipe right → previous status, swipe left → next status.
class TodoListItem extends ConsumerStatefulWidget {
  final TodoModel todo;
  const TodoListItem({super.key, required this.todo});

  @override
  ConsumerState<TodoListItem> createState() => _TodoListItemState();
}

class _TodoListItemState extends ConsumerState<TodoListItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final isDone = todo.status == TodoStatus.done;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key('${todo.id}-${todo.status.name}'),
        direction: DismissDirection.horizontal,
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          color: AppTheme.statusActive,
          icon: Icons.arrow_back_rounded,
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          color: AppTheme.statusDone,
          icon: Icons.arrow_forward_rounded,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            final prev = todo.status.previous;
            if (prev != todo.status) {
              ref.read(todoProvider.notifier).updateStatus(todo.id, prev);
            }
          } else {
            final next = todo.status.next;
            if (next != todo.status) {
              ref.read(todoProvider.notifier).updateStatus(todo.id, next);
            }
          }
          return false;
        },
        onDismissed: (_) {},
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Opacity(
            opacity: isDone ? 0.6 : 1.0,
            child: GlassContainer(
              borderRadius: AppTheme.radiusMd,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              onTap: () => _openEdit(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Checkbox(todo: todo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            size: 15,
                            weight: FontWeight.w500,
                            color: isDone
                                ? AppTheme.fgTertiary
                                : AppTheme.fgPrimary,
                          ).copyWith(
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            decorationColor: AppTheme.fgTertiary,
                            decorationThickness: 1.5,
                          ),
                        ),
                        if (stripMarkdown(todo.notes).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            stripMarkdown(todo.notes),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(
                              size: 13,
                              color: isDone
                                  ? AppTheme.fgTertiary.withValues(alpha: 0.7)
                                  : AppTheme.fgSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        _MetaRow(todo: todo),
                      ],
                    ),
                  ),
                  // Delete button — only visible on hover
                  AnimatedOpacity(
                    duration: AppTheme.durMicro,
                    opacity: _hover ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !_hover,
                      child: _DeleteButton(
                        onTap: () =>
                            ref.read(todoProvider.notifier).delete(todo.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: TaskPreviewSheet(todo: widget.todo),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Round checkbox (24px)
// ──────────────────────────────────────────────────────────────────
class _Checkbox extends ConsumerWidget {
  final TodoModel todo;
  const _Checkbox({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = todo.status == TodoStatus.done;
    final color = isDone ? AppTheme.statusDoneDeep : AppTheme.fgTertiary;

    return GestureDetector(
      onTap: () => ref.read(todoProvider.notifier).updateStatus(
            todo.id,
            isDone
                ? TodoStatus.todo
                : (todo.status == TodoStatus.todo
                    ? TodoStatus.doing
                    : TodoStatus.done),
          ),
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        curve: AppTheme.easeSpring,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? color : Colors.transparent,
          border: Border.all(
            color: isDone
                ? color
                : todo.status == TodoStatus.doing
                    ? AppTheme.statusActiveDeep
                    : Colors.black.withValues(alpha: 0.18),
            width: isDone
                ? 2
                : todo.status == TodoStatus.doing
                    ? 2.5
                    : 2,
          ),
        ),
        alignment: Alignment.center,
        child: isDone
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : todo.status == TodoStatus.doing
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.statusActiveDeep,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Meta line — created date + completed date
// ──────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final TodoModel todo;
  const _MetaRow({required this.todo});

  static final _fmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == TodoStatus.done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add_circle_outline_rounded,
            size: 11, color: AppTheme.fgTertiary),
        const SizedBox(width: 3),
        Text(
          _fmt.format(todo.createdAt),
          style: AppTheme.mono(size: 11, color: AppTheme.fgTertiary),
        ),
        if (isDone && todo.completedAt != null) ...[
          const SizedBox(width: 10),
          Icon(Icons.check_circle_outline_rounded,
              size: 11, color: AppTheme.statusDoneDeep),
          const SizedBox(width: 3),
          Text(
            _fmt.format(todo.completedAt!),
            style: AppTheme.mono(size: 11, color: AppTheme.statusDoneDeep),
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Trash button (hover-only)
// ──────────────────────────────────────────────────────────────────
class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.statusOverdue.withValues(alpha: 0.10),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 16,
          color: AppTheme.statusOverdue,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Swipe reveal background
// ──────────────────────────────────────────────────────────────────
class _SwipeBackground extends StatelessWidget {
  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: isLeft ? 22 : 0,
        right: isLeft ? 0 : 22,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.65),
            color,
          ],
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
