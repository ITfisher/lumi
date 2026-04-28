import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/todo_model.dart';
import '../../providers/todo_provider.dart';
import 'todo_list_item.dart';

class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(filteredTodosProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (todos) {
            if (todos.isEmpty) return const _EmptyState();

            final doing =
                todos.where((t) => t.status == TodoStatus.doing).toList();
            final todo =
                todos.where((t) => t.status == TodoStatus.todo).toList();
            final done =
                todos.where((t) => t.status == TodoStatus.done).toList();

            return _buildList([
              if (doing.isNotEmpty) ...[
                _SectionHeader(
                    label: 'IN PROGRESS', count: doing.length, accent: true),
                ...doing,
              ],
              if (todo.isNotEmpty) ...[
                if (doing.isNotEmpty)
                  _SectionHeader(
                      label: 'TODO', count: todo.length, accent: false),
                ...todo,
              ],
              if (done.isNotEmpty) ...[
                _SectionHeader(
                    label: 'COMPLETED', count: done.length, accent: false),
                ...done,
              ],
            ]);
          },
        );
  }

  Widget _buildList(List<Object> items) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (final (i, item) in items.indexed)
          if (item is _SectionHeader)
            item
          else if (item is TodoModel)
            TodoListItem(todo: item)
                .animate()
                .fadeIn(delay: (i * 20).ms, duration: 220.ms)
                .slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool accent;
  const _SectionHeader(
      {required this.label, required this.count, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.label(size: 11).copyWith(
              color: accent ? AppTheme.accentBlueDeep : null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: accent
                  ? AppTheme.accentBlue.withValues(alpha: 0.12)
                  : const Color(0x12000000),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '$count',
              style: AppTheme.body(
                size: 10,
                weight: FontWeight.w600,
                color: accent ? AppTheme.accentBlueDeep : AppTheme.fgTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentBlue.withValues(alpha: 0.1),
              border: Border.all(
                color: AppTheme.accentBlue.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppTheme.accentBlue.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No tasks here',
            style: AppTheme.display(
              size: 20,
              weight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one',
            style: AppTheme.body(
              size: 14,
              color: AppTheme.fgSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
