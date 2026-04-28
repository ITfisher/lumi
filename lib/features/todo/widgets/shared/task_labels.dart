import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TaskLabelChip extends StatelessWidget {
  final String label;
  final bool compact;

  const TaskLabelChip({
    super.key,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.body(
          size: compact ? 11 : 12,
          weight: FontWeight.w600,
          color: AppTheme.accentBlueDeep,
          height: 1.2,
        ),
      ),
    );
  }
}

class TaskLabelWrap extends StatelessWidget {
  final List<String> labels;
  final bool compact;
  final double spacing;
  final double runSpacing;

  const TaskLabelWrap({
    super.key,
    required this.labels,
    this.compact = false,
    this.spacing = 6,
    this.runSpacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final label in labels)
          TaskLabelChip(label: label, compact: compact),
      ],
    );
  }
}

class SelectableTaskLabelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectableTaskLabelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? AppTheme.accentBlue.withValues(alpha: 0.14)
        : const Color(0x8CFFFFFF);
    final border = selected
        ? AppTheme.accentBlue.withValues(alpha: 0.45)
        : AppTheme.glassBorderMedium;
    final foreground =
        selected ? AppTheme.accentBlueDeep : AppTheme.fgSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        curve: AppTheme.easeStandard,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTheme.body(
                size: 12,
                weight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskLabelSelectorSection extends StatelessWidget {
  final List<String> labels;
  final Set<String> selectedLabels;
  final bool loading;
  final ValueChanged<String> onToggle;
  final VoidCallback? onOpenProfile;
  final String title;

  const TaskLabelSelectorSection({
    super.key,
    required this.labels,
    required this.selectedLabels,
    required this.loading,
    required this.onToggle,
    this.onOpenProfile,
    this.title = 'LABELS',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.label(size: 10)),
        const SizedBox(height: 8),
        if (loading && labels.isEmpty)
          Text(
            'Loading configured labels...',
            style: AppTheme.body(size: 13, color: AppTheme.fgTertiary),
          )
        else if (labels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorderMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'No labels configured yet. Add them in Profile before assigning them to tasks.',
                    style: AppTheme.body(
                      size: 13,
                      color: AppTheme.fgSecondary,
                    ),
                  ),
                ),
                if (onOpenProfile != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onOpenProfile,
                    child: const Text('Open Profile'),
                  ),
                ],
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in labels)
                SelectableTaskLabelChip(
                  label: label,
                  selected: selectedLabels.contains(label),
                  onTap: () => onToggle(label),
                ),
            ],
          ),
      ],
    );
  }
}
