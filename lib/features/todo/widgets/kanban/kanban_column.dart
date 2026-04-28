import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';
import 'kanban_card.dart';

/// Kanban column — pixel port of the design's `KanbanCol`.
///
/// Header is a FULL PILL (radius 999) with a soft column-coloured
/// wash background; the count sits on the right as a solid-fill
/// circular badge with white text.
class KanbanColumn extends ConsumerStatefulWidget {
  final TodoStatus status;
  const KanbanColumn({super.key, required this.status});

  @override
  ConsumerState<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends ConsumerState<KanbanColumn> {
  bool _highlighted = false;

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(filteredTodosByStatusProvider(widget.status));
    final scheme = _scheme(widget.status);

    return DragTarget<TodoModel>(
      onWillAcceptWithDetails: (d) {
        final ok = d.data.status != widget.status;
        setState(() => _highlighted = ok);
        return ok;
      },
      onLeave: (_) => setState(() => _highlighted = false),
      onAcceptWithDetails: (d) {
        setState(() => _highlighted = false);
        ref.read(todoProvider.notifier).updateStatus(d.data.id, widget.status);
      },
      builder: (context, _, __) {
        return AnimatedContainer(
          duration: AppTheme.durStd,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _highlighted
                  ? scheme.color.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PillHeader(
                title: scheme.title,
                count: todos.length,
                scheme: scheme,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: todos.isEmpty
                    ? _EmptyDropZone(
                        highlighted: _highlighted,
                        color: scheme.color,
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: todos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) => KanbanCard(todo: todos[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Full-pill header — matches design exactly:
///   `padding: 8px 12px; borderRadius: 999;
///    background: rgba(color, 0.10); border: 1px solid rgba(color, 0.10);`
/// Count badge: `width 18; height 18; background: color; color: white;`
class _PillHeader extends StatelessWidget {
  final String title;
  final int count;
  final _ColumnScheme scheme;

  const _PillHeader({
    required this.title,
    required this.count,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.headerBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: scheme.headerBg, width: 1),
      ),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.body(
              size: 12,
              weight: FontWeight.w700,
              color: scheme.color,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: scheme.color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: AppTheme.body(
                size: 12,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDropZone extends StatelessWidget {
  final bool highlighted;
  final Color color;
  const _EmptyDropZone({required this.highlighted, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        duration: AppTheme.durMicro,
        opacity: highlighted ? 1.0 : 0.5,
        child: Text(
          highlighted ? 'Release to move' : 'Drop here',
          style: AppTheme.body(
            size: 12,
            color: highlighted ? color : AppTheme.fgTertiary,
            weight: highlighted ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Column colour schemes
// ──────────────────────────────────────────────────────────────────
class _ColumnScheme {
  final String title;
  final Color color;
  final Color headerBg;
  const _ColumnScheme({
    required this.title,
    required this.color,
    required this.headerBg,
  });
}

_ColumnScheme _scheme(TodoStatus s) {
  switch (s) {
    case TodoStatus.todo:
      return const _ColumnScheme(
        title: 'To Do',
        color: AppTheme.accentBlue,
        headerBg: Color(0x1A5E8FFF), // rgba(94,143,255,0.10)
      );
    case TodoStatus.doing:
      return const _ColumnScheme(
        title: 'In Progress',
        color: AppTheme.statusActiveDeep,
        headerBg: Color(0x1AFAAC32), // rgba(250,172,50,0.10)
      );
    case TodoStatus.done:
      return const _ColumnScheme(
        title: 'Done',
        color: AppTheme.statusDoneDeep,
        headerBg: Color(0x1A009E2F), // rgba(0,158,47,0.10)
      );
  }
}
