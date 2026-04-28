import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/markdown_utils.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';
import '../shared/task_preview_sheet.dart';

class KanbanCard extends StatelessWidget {
  final TodoModel todo;
  const KanbanCard({super.key, required this.todo});

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  Widget _feedback(double width) => Material(
        color: Colors.transparent,
        child: Transform.rotate(
          angle: 0.025,
          child: SizedBox(
            width: width,
            child: Opacity(opacity: 0.92, child: _CardBody(todo: todo)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 240.0;
        final cardBody = _CardBody(todo: todo);
        final tappable = GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.18),
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TaskPreviewSheet(todo: todo),
            ),
          ),
          child: cardBody,
        );

        if (_isDesktop) {
          return Draggable<TodoModel>(
            data: todo,
            feedback: _feedback(cardWidth),
            childWhenDragging: Opacity(opacity: 0.3, child: cardBody),
            child: tappable,
          );
        }
        return LongPressDraggable<TodoModel>(
          data: todo,
          delay: const Duration(milliseconds: 250),
          feedback: _feedback(cardWidth),
          childWhenDragging: Opacity(opacity: 0.3, child: cardBody),
          child: tappable,
        );
      },
    );
  }
}

class _CardBody extends ConsumerWidget {
  final TodoModel todo;
  const _CardBody({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = todo.status == TodoStatus.done;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 88),
      child: GlassContainer(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BoardCheckbox(
              todo: todo,
              onToggle: () => ref.read(todoProvider.notifier).updateStatus(
                    todo.id,
                    isDone ? TodoStatus.todo : TodoStatus.done,
                  ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      size: 15,
                      weight: FontWeight.w700,
                      color: isDone ? AppTheme.fgTertiary : AppTheme.fgPrimary,
                      height: 1.22,
                    ).copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.fgTertiary,
                      decorationThickness: 1.8,
                    ),
                  ),
                  if (stripMarkdown(todo.notes).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      stripMarkdown(todo.notes),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                        size: 13,
                        color: isDone
                            ? AppTheme.fgTertiary.withValues(alpha: 0.7)
                            : AppTheme.fgSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _TimeRow(todo: todo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final TodoModel todo;
  const _TimeRow({required this.todo});

  static final _fmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == TodoStatus.done;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimeLabel(
          icon: Icons.add_circle_outline_rounded,
          label: _fmt.format(todo.createdAt),
          color: AppTheme.fgTertiary,
        ),
        if (isDone && todo.completedAt != null) ...[
          const SizedBox(height: 4),
          _TimeLabel(
            icon: Icons.check_circle_outline_rounded,
            label: _fmt.format(todo.completedAt!),
            color: AppTheme.statusDoneDeep,
          ),
        ],
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TimeLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.mono(size: 11, color: color),
        ),
      ],
    );
  }
}

class _BoardCheckbox extends StatelessWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  const _BoardCheckbox({required this.todo, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == TodoStatus.done;
    final color = isDone ? AppTheme.statusDoneDeep : AppTheme.fgTertiary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        curve: AppTheme.easeSpring,
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? color : Colors.transparent,
          border: Border.all(
            color: isDone ? color : Colors.black.withValues(alpha: 0.18),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: isDone
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}
