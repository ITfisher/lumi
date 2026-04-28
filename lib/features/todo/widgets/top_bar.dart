import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_date_range_picker.dart';
import '../providers/todo_provider.dart';

class GlassTopBar extends ConsumerStatefulWidget {
  const GlassTopBar({super.key});

  @override
  ConsumerState<GlassTopBar> createState() => _GlassTopBarState();
}

class _GlassTopBarState extends ConsumerState<GlassTopBar> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(viewModeProvider);
    final filtered = ref.watch(filteredTodosProvider);
    final totalCount =
        filtered.maybeWhen(data: (l) => l.length, orElse: () => 0);
    final hasFilter = ref.watch(createdFilterProvider) != null ||
        ref.watch(completedFilterProvider) != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Title row ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks',
                      style: AppTheme.display(
                        size: 24,
                        weight: FontWeight.w700,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalCount task${totalCount == 1 ? '' : 's'}',
                      style:
                          AppTheme.mono(size: 13, color: AppTheme.fgTertiary),
                    ),
                  ],
                ),
              ),
              _ViewToggle(
                value: viewMode,
                onChanged: (v) => unawaited(
                    ref.read(viewModeProvider.notifier).setViewMode(v)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Search + filter button ────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(hasFilter: hasFilter),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Filter button — opens a glass overlay menu with Created/Completed
// ──────────────────────────────────────────────────────────────────
class _FilterButton extends ConsumerWidget {
  final bool hasFilter;
  const _FilterButton({required this.hasFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showFilterMenu(context, ref),
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: hasFilter
              ? AppTheme.accentBlue.withValues(alpha: 0.14)
              : const Color(0x8CFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFilter
                ? AppTheme.accentBlue.withValues(alpha: 0.50)
                : AppTheme.glassBorderLight,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.tune_rounded,
          size: 17,
          color: hasFilter ? AppTheme.accentBlueDeep : AppTheme.fgSecondary,
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) => _FilterMenuDialog(
        anchorContext: context,
        onCreatedTap: () async {
          Navigator.pop(ctx);
          await _pickFilter(
            context: context,
            ref: ref,
            isCreated: true,
          );
        },
        onCompletedTap: () async {
          Navigator.pop(ctx);
          await _pickFilter(
            context: context,
            ref: ref,
            isCreated: false,
          );
        },
        onClearAll: () {
          ref.read(createdFilterProvider.notifier).state = null;
          ref.read(completedFilterProvider.notifier).state = null;
          ref.read(createdCustomRangeProvider.notifier).state = null;
          ref.read(completedCustomRangeProvider.notifier).state = null;
          Navigator.pop(ctx);
        },
        createdOpt: ref.read(createdFilterProvider),
        completedOpt: ref.read(completedFilterProvider),
        createdCustom: ref.read(createdCustomRangeProvider),
        completedCustom: ref.read(completedCustomRangeProvider),
      ),
    );
  }

  Future<void> _pickFilter({
    required BuildContext context,
    required WidgetRef ref,
    required bool isCreated,
  }) async {
    final currentOpt = isCreated
        ? ref.read(createdFilterProvider)
        : ref.read(completedFilterProvider);
    final currentCustom = isCreated
        ? ref.read(createdCustomRangeProvider)
        : ref.read(completedCustomRangeProvider);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) => _DateFilterDialog(
        title: isCreated ? 'Created Date' : 'Completed Date',
        selected: currentOpt,
        customRange: currentCustom,
        onApply: (opt, range) {
          if (isCreated) {
            ref.read(createdFilterProvider.notifier).state = opt;
            if (range != null) {
              ref.read(createdCustomRangeProvider.notifier).state = range;
            }
          } else {
            ref.read(completedFilterProvider.notifier).state = opt;
            if (range != null) {
              ref.read(completedCustomRangeProvider.notifier).state = range;
            }
          }
          Navigator.pop(ctx);
        },
        onClear: () {
          if (isCreated) {
            ref.read(createdFilterProvider.notifier).state = null;
            ref.read(createdCustomRangeProvider.notifier).state = null;
          } else {
            ref.read(completedFilterProvider.notifier).state = null;
            ref.read(completedCustomRangeProvider.notifier).state = null;
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Glass dropdown menu — anchored near top-right of screen
// ──────────────────────────────────────────────────────────────────
class _FilterMenuDialog extends StatelessWidget {
  final BuildContext anchorContext;
  final VoidCallback onCreatedTap;
  final VoidCallback onCompletedTap;
  final VoidCallback onClearAll;
  final DateRangeOption? createdOpt;
  final DateRangeOption? completedOpt;
  final DateTimeRange? createdCustom;
  final DateTimeRange? completedCustom;

  const _FilterMenuDialog({
    required this.anchorContext,
    required this.onCreatedTap,
    required this.onCompletedTap,
    required this.onClearAll,
    required this.createdOpt,
    required this.completedOpt,
    required this.createdCustom,
    required this.completedCustom,
  });

  static final _fmt = DateFormat('MMM d');

  String _rangeLabel(DateRangeOption opt, DateTimeRange? custom) {
    if (opt == DateRangeOption.custom && custom != null) {
      return '${_fmt.format(custom.start)} – ${_fmt.format(custom.end)}';
    }
    return opt.label;
  }

  @override
  Widget build(BuildContext context) {
    final hasAny = createdOpt != null || completedOpt != null;

    return Stack(
      children: [
        // Transparent full-screen tap-to-dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        // Menu anchored to top-right area
        Positioned(
          top: 120,
          right: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                width: 240,
                decoration: BoxDecoration(
                  color: AppTheme.glassMenuFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorderLight),
                  boxShadow: AppTheme.shadowElevated,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Filter',
                            style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.fgPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (hasAny)
                            GestureDetector(
                              onTap: onClearAll,
                              child: Text(
                                'Clear all',
                                style: AppTheme.body(
                                  size: 12,
                                  color: AppTheme.statusOverdue,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Created Date',
                      value: createdOpt != null
                          ? _rangeLabel(createdOpt!, createdCustom)
                          : null,
                      onTap: onCreatedTap,
                    ),
                    _MenuItem(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Completed Date',
                      value: completedOpt != null
                          ? _rangeLabel(completedOpt!, completedCustom)
                          : null,
                      onTap: onCompletedTap,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppTheme.glassBorderMedium,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.durMicro,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          color: _hover
              ? AppTheme.accentBlue.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppTheme.fgTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: AppTheme.body(size: 13, weight: FontWeight.w500),
                    ),
                    if (widget.value != null)
                      Text(
                        widget.value!,
                        style: AppTheme.body(
                          size: 11,
                          color: AppTheme.accentBlueDeep,
                          weight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 15, color: AppTheme.fgTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Date filter dialog — quick-pick chips + custom glass picker
// ──────────────────────────────────────────────────────────────────
class _DateFilterDialog extends StatefulWidget {
  final String title;
  final DateRangeOption? selected;
  final DateTimeRange? customRange;
  final void Function(DateRangeOption, DateTimeRange?) onApply;
  final VoidCallback onClear;

  const _DateFilterDialog({
    required this.title,
    required this.selected,
    required this.customRange,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<_DateFilterDialog> {
  DateRangeOption? _picked;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _picked = widget.selected;
    _customRange = widget.customRange;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassModalFill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorderLight),
              boxShadow: AppTheme.shadowElevated,
            ),
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.display(
                        size: 17,
                        weight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0x12000000),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.close_rounded,
                            size: 14, color: AppTheme.fgSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quick-pick options
                for (final opt in DateRangeOption.values)
                  if (opt != DateRangeOption.custom)
                    _QuickOption(
                      label: opt.label,
                      active: _picked == opt,
                      onTap: () => setState(() => _picked = opt),
                    ),
                const SizedBox(height: 8),
                // Custom range row
                _CustomRangeRow(
                  active: _picked == DateRangeOption.custom,
                  range: _customRange,
                  onTap: () async {
                    final r = await showGlassDateRangePicker(
                      context: context,
                      initial: _customRange,
                    );
                    if (r != null) {
                      setState(() {
                        _customRange = r;
                        _picked = DateRangeOption.custom;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onClear,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0x80FFFFFF),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                            border:
                                Border.all(color: AppTheme.glassBorderMedium),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Clear',
                            style: AppTheme.body(
                              size: 14,
                              weight: FontWeight.w500,
                              color: AppTheme.fgSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _picked == null
                            ? null
                            : () => widget.onApply(_picked!, _customRange),
                        child: AnimatedContainer(
                          duration: AppTheme.durMicro,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            gradient: _picked != null
                                ? const LinearGradient(
                                    colors: [
                                      AppTheme.accentBlue,
                                      AppTheme.accentPurpleDeep
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _picked == null
                                ? const Color(0x20000000)
                                : null,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Apply',
                            style: AppTheme.body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: _picked != null
                                  ? Colors.white
                                  : AppTheme.fgTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickOption extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _QuickOption(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentBlue.withValues(alpha: 0.12)
              : const Color(0x66FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppTheme.accentBlue.withValues(alpha: 0.45)
                : AppTheme.glassBorderMedium,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTheme.body(
                size: 14,
                weight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppTheme.accentBlueDeep : AppTheme.fgPrimary,
              ),
            ),
            const Spacer(),
            if (active)
              Icon(Icons.check_rounded,
                  size: 16, color: AppTheme.accentBlueDeep),
          ],
        ),
      ),
    );
  }
}

class _CustomRangeRow extends StatelessWidget {
  final bool active;
  final DateTimeRange? range;
  final VoidCallback onTap;
  const _CustomRangeRow(
      {required this.active, required this.range, required this.onTap});

  static final _fmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final label = active && range != null
        ? '${_fmt.format(range!.start)} – ${_fmt.format(range!.end)}'
        : 'Custom range…';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.accentBlue.withValues(alpha: 0.12)
              : const Color(0x66FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppTheme.accentBlue.withValues(alpha: 0.45)
                : AppTheme.glassBorderMedium,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_rounded,
                size: 16,
                color: active ? AppTheme.accentBlueDeep : AppTheme.fgTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTheme.body(
                  size: 14,
                  weight: active ? FontWeight.w600 : FontWeight.w400,
                  color:
                      active ? AppTheme.accentBlueDeep : AppTheme.fgSecondary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 15, color: AppTheme.fgTertiary),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// View toggle pill
// ──────────────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final ViewMode value;
  final ValueChanged<ViewMode> onChanged;
  const _ViewToggle({required this.value, required this.onChanged});

  static const double _h = 32;
  static const double _padding = 3;
  static const double _segW = 86;

  @override
  Widget build(BuildContext context) {
    final r = _h / 2;
    final innerR = (_h - _padding * 2) / 2;
    final selectedIndex = value == ViewMode.list ? 0 : 1;
    final innerWidth = _segW * 2;
    final outerWidth = innerWidth + _padding * 2;

    return Container(
      width: outerWidth,
      height: _h,
      decoration: BoxDecoration(
        color: const Color(0x6BFFFFFF),
        borderRadius: BorderRadius.circular(r),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: AppTheme.durStd,
              curve: AppTheme.easeStandard,
              left: selectedIndex * _segW,
              top: 0,
              bottom: 0,
              width: _segW,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xE0FFFFFF),
                  borderRadius: BorderRadius.circular(innerR),
                  boxShadow: AppTheme.shadowCard,
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  _segment(ViewMode.list, Icons.format_list_bulleted_rounded,
                      'List', value == ViewMode.list),
                  _segment(ViewMode.kanban, Icons.dashboard_outlined, 'Board',
                      value == ViewMode.kanban),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(ViewMode mode, IconData icon, String label, bool active) {
    final fg = active ? AppTheme.accentBlueDeep : AppTheme.fgTertiary;
    return SizedBox(
      width: _segW,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(mode),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTheme.body(
                    size: 13,
                    weight: active ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Search field
// ──────────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x8CFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorderLight, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppTheme.accentBlue,
        style: AppTheme.body(size: 14),
        decoration: InputDecoration(
          hintText: 'Search tasks…',
          hintStyle: AppTheme.body(size: 14, color: AppTheme.fgTertiary),
          isDense: true,
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search_rounded,
                size: 17, color: AppTheme.fgTertiary),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 36),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        ),
      ),
    );
  }
}
