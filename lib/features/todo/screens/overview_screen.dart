import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glass_date_range_picker.dart';
import '../../../data/models/todo_model.dart';
import '../providers/todo_provider.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opt = ref.watch(overviewFilterProvider);
    final custom = ref.watch(overviewCustomRangeProvider);
    final todosAsync = ref.watch(overviewTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: AppTheme.display(
                  size: 24,
                  weight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Task execution statistics',
                style: AppTheme.mono(size: 13, color: AppTheme.fgTertiary),
              ),
              const SizedBox(height: 16),
              _DateFilterRow(
                selected: opt,
                customRange: custom,
                onSelect: (v) =>
                    ref.read(overviewFilterProvider.notifier).state = v,
                onCustomRange: (r) =>
                    ref.read(overviewCustomRangeProvider.notifier).state = r,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        // ── Body ─────────────────────────────────────────────────
        Expanded(
          child: todosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (todos) => _StatsBody(todos: todos, opt: opt, custom: custom),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Date filter chip row
// ──────────────────────────────────────────────────────────────────
class _DateFilterRow extends StatelessWidget {
  final DateRangeOption selected;
  final DateTimeRange? customRange;
  final ValueChanged<DateRangeOption> onSelect;
  final ValueChanged<DateTimeRange?> onCustomRange;

  const _DateFilterRow({
    required this.selected,
    required this.customRange,
    required this.onSelect,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opt in DateRangeOption.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: opt == DateRangeOption.custom && customRange != null
                    ? _fmtRange(customRange!)
                    : opt.label,
                active: selected == opt,
                onTap: () async {
                  if (opt == DateRangeOption.custom) {
                    final r = await showGlassDateRangePicker(
                      context: context,
                      initial: customRange,
                    );
                    if (r != null) onCustomRange(r);
                  }
                  onSelect(opt);
                },
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtRange(DateTimeRange r) {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(r.start)} – ${fmt.format(r.end)}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentBlue.withValues(alpha: 0.14)
              : const Color(0x80FFFFFF),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: active
                ? AppTheme.accentBlue.withValues(alpha: 0.55)
                : AppTheme.glassBorderMedium,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            size: 13,
            weight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? AppTheme.accentBlueDeep : AppTheme.fgSecondary,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Stats body
// ──────────────────────────────────────────────────────────────────
class _StatsBody extends StatelessWidget {
  final List<TodoModel> todos;
  final DateRangeOption opt;
  final DateTimeRange? custom;
  const _StatsBody(
      {required this.todos, required this.opt, required this.custom});

  @override
  Widget build(BuildContext context) {
    final total = todos.length;
    final done = todos.where((t) => t.status == TodoStatus.done).length;
    final doing = todos.where((t) => t.status == TodoStatus.doing).length;
    final todo = todos.where((t) => t.status == TodoStatus.todo).length;
    final rate = total == 0 ? 0.0 : done / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        // Stat cards row
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: total,
                    label: 'Total',
                    color: AppTheme.accentBlue,
                    icon: Icons.format_list_bulleted_rounded)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: todo,
                    label: 'To Do',
                    color: AppTheme.fgTertiary,
                    icon: Icons.radio_button_unchecked_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: doing,
                    label: 'In Progress',
                    color: AppTheme.statusActiveDeep,
                    icon: Icons.pending_outlined)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: done,
                    label: 'Completed',
                    color: AppTheme.statusDoneDeep,
                    icon: Icons.check_circle_outline_rounded)),
          ],
        ),
        const SizedBox(height: 20),
        // Completion rate card
        GlassContainer(
          borderRadius: AppTheme.radiusMd,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Completion Rate',
                    style: AppTheme.body(size: 14, weight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${(rate * 100).toStringAsFixed(0)}%',
                    style: AppTheme.display(
                      size: 20,
                      weight: FontWeight.w700,
                      color: AppTheme.statusDoneDeep,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 10,
                  backgroundColor: const Color(0x14000000),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.statusDoneDeep),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _LegendDot(
                      color: AppTheme.statusDoneDeep, label: 'Done ($done)'),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: AppTheme.statusActiveDeep,
                      label: 'In Progress ($doing)'),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: AppTheme.fgTertiary, label: 'To Do ($todo)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Status breakdown bar
        if (total > 0)
          GlassContainer(
            borderRadius: AppTheme.radiusMd,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Breakdown',
                  style: AppTheme.body(size: 14, weight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: Row(
                    children: [
                      if (done > 0)
                        Flexible(
                          flex: done,
                          child: Container(
                            height: 12,
                            color: AppTheme.statusDoneDeep,
                          ),
                        ),
                      if (doing > 0)
                        Flexible(
                          flex: doing,
                          child: Container(
                            height: 12,
                            color: AppTheme.statusActiveDeep,
                          ),
                        ),
                      if (todo > 0)
                        Flexible(
                          flex: todo,
                          child: Container(
                            height: 12,
                            color: AppTheme.neutral300,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppTheme.radiusMd,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            '$value',
            style: AppTheme.display(
              size: 28,
              weight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.body(size: 13, color: AppTheme.fgSecondary),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTheme.body(size: 12, color: AppTheme.fgSecondary)),
      ],
    );
  }
}
