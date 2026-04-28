import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// Shows a frosted-glass date-range picker dialog.
/// Returns the selected [DateTimeRange], or null if dismissed.
Future<DateTimeRange?> showGlassDateRangePicker({
  required BuildContext context,
  DateTimeRange? initial,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (_) => _GlassDateRangePickerDialog(initial: initial),
  );
}

class _GlassDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initial;
  const _GlassDateRangePickerDialog({this.initial});

  @override
  State<_GlassDateRangePickerDialog> createState() =>
      _GlassDateRangePickerDialogState();
}

class _GlassDateRangePickerDialogState
    extends State<_GlassDateRangePickerDialog> {
  late DateTime _focusedMonth;
  DateTime? _start;
  DateTime? _end;
  bool _selectingEnd = false;

  static final _monthFmt = DateFormat('MMMM yyyy');
  static final _dayFmt = DateFormat('MMM d');

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.start;
    _end = widget.initial?.end;
    _focusedMonth = _start != null
        ? DateTime(_start!.year, _start!.month)
        : DateTime(DateTime.now().year, DateTime.now().month);
    _selectingEnd = _start != null && _end == null;
  }

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  void _onDayTap(DateTime day) {
    setState(() {
      if (!_selectingEnd) {
        _start = day;
        _end = null;
        _selectingEnd = true;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
        _selectingEnd = false;
      }
    });
  }

  bool _inRange(DateTime day) {
    if (_start == null || _end == null) return false;
    return !day.isBefore(_start!) && !day.isAfter(_end!);
  }

  bool _isStart(DateTime day) => _start != null && _isSameDay(day, _start!);

  bool _isEnd(DateTime day) => _end != null && _isSameDay(day, _end!);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final canConfirm = _start != null && _end != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassModalFill.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 1,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 54,
                  offset: Offset(0, 24),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.28),
                  blurRadius: 1,
                  spreadRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 410),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ─────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Select Date Range',
                      style: AppTheme.display(
                        size: 18,
                        weight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    _IconBtn(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Selected range pill ─────────────────────────
                _GlassPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  borderRadius: 18,
                  child: _RangePill(
                    start: _start,
                    end: _end,
                    selectingEnd: _selectingEnd,
                    fmt: _dayFmt,
                  ),
                ),
                const SizedBox(height: 16),

                _GlassPanel(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  borderRadius: 22,
                  child: Column(
                    children: [
                      // ── Month navigation ──────────────────────
                      Row(
                        children: [
                          _IconBtn(
                            icon: Icons.chevron_left_rounded,
                            onTap: _prevMonth,
                          ),
                          Expanded(
                            child: Text(
                              _monthFmt.format(_focusedMonth),
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                size: 15,
                                weight: FontWeight.w700,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          _IconBtn(
                            icon: Icons.chevron_right_rounded,
                            onTap: _nextMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Weekday labels ───────────────────────
                      Row(
                        children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: AppTheme.label(
                                        size: 11,
                                        color: AppTheme.fgTertiary,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),

                      // ── Calendar grid ───────────────────────
                      _CalendarGrid(
                        focusedMonth: _focusedMonth,
                        onDayTap: _onDayTap,
                        isStart: _isStart,
                        isEnd: _isEnd,
                        inRange: _inRange,
                        today: DateTime.now(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Action buttons ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(
                        label: 'Cancel',
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrimaryBtn(
                        label: 'Apply',
                        enabled: canConfirm,
                        onTap: canConfirm
                            ? () => Navigator.pop(
                                  context,
                                  DateTimeRange(start: _start!, end: _end!),
                                )
                            : null,
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

// ──────────────────────────────────────────────────────────────────
// Calendar grid
// ──────────────────────────────────────────────────────────────────
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _GlassPanel({
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
          const BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final ValueChanged<DateTime> onDayTap;
  final bool Function(DateTime) isStart;
  final bool Function(DateTime) isEnd;
  final bool Function(DateTime) inRange;
  final DateTime today;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.onDayTap,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startOffset = firstDay.weekday % 7; // Sun=0
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 38));
            }
            final day = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
            final start = isStart(day);
            final end = isEnd(day);
            final inR = inRange(day);
            final isToday = day.year == today.year &&
                day.month == today.month &&
                day.day == today.day;

            return Expanded(
              child: _DayCell(
                day: dayNum,
                isToday: isToday,
                isEndpoint: start || end,
                inRange: inR,
                onTap: () => onDayTap(day),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _DayCell extends StatefulWidget {
  final int day;
  final bool isToday;
  final bool isEndpoint;
  final bool inRange;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isEndpoint,
    required this.inRange,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.isEndpoint;
    final bg = selected
        ? null
        : widget.inRange
            ? AppTheme.accentBlue.withValues(alpha: 0.13)
            : _hover
                ? Colors.white.withValues(alpha: 0.40)
                : Colors.transparent;
    final textColor = selected ? Colors.white : AppTheme.fgPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.durMicro,
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
          decoration: BoxDecoration(
            color: bg,
            gradient: selected
                ? const LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.42)
                  : _hover
                      ? Colors.white.withValues(alpha: 0.54)
                      : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.accentBlue.withValues(alpha: 0.26),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${widget.day}',
                style: AppTheme.body(
                  size: 13,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0,
                ),
              ),
              if (widget.isToday && !selected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentBlueDeep,
                      shape: BoxShape.circle,
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

// ──────────────────────────────────────────────────────────────────
// Range pill showing selected dates
// ──────────────────────────────────────────────────────────────────
class _RangePill extends StatelessWidget {
  final DateTime? start;
  final DateTime? end;
  final bool selectingEnd;
  final DateFormat fmt;

  const _RangePill({
    required this.start,
    required this.end,
    required this.selectingEnd,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateSlot(
            label: start != null ? fmt.format(start!) : 'Start',
            active: !selectingEnd,
            hasValue: start != null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 15,
            color: AppTheme.fgTertiary,
          ),
        ),
        Expanded(
          child: _DateSlot(
            label: end != null ? fmt.format(end!) : 'End',
            active: selectingEnd,
            hasValue: end != null,
          ),
        ),
      ],
    );
  }
}

class _DateSlot extends StatelessWidget {
  final String label;
  final bool active;
  final bool hasValue;
  const _DateSlot(
      {required this.label, required this.active, required this.hasValue});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.durMicro,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.accentBlue.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppTheme.accentBlue.withValues(alpha: 0.48)
              : Colors.white.withValues(alpha: 0.30),
        ),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body(
            size: 13,
            weight: hasValue || active ? FontWeight.w600 : FontWeight.w500,
            color: hasValue
                ? AppTheme.fgPrimary
                : active
                    ? AppTheme.accentBlueDeep
                    : AppTheme.fgTertiary,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Small helper widgets
// ──────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.close_rounded ? 'Close' : 'Change month',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppTheme.fgSecondary),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.body(
            size: 14,
            weight: FontWeight.w500,
            color: AppTheme.fgSecondary,
          ),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _PrimaryBtn({required this.label, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durMicro,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : Colors.white.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: enabled
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.30)),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.accentBlue.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.body(
            size: 14,
            weight: FontWeight.w600,
            color: enabled ? Colors.white : AppTheme.fgTertiary,
          ),
        ),
      ),
    );
  }
}
