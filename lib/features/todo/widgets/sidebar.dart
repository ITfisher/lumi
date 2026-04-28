import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../providers/todo_provider.dart';

class GlassSidebar extends ConsumerWidget {
  final VoidCallback? onNavigate;
  final VoidCallback? onCollapse;

  const GlassSidebar({super.key, this.onNavigate, this.onCollapse});

  static const double widthExpanded = 220;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navPageProvider);
    final counts = ref.watch(navCountsProvider);

    return SizedBox(
      width: widthExpanded,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.glassShellFill,
              border: Border(
                right: BorderSide(color: AppTheme.glassBorderMedium, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 56, 0, 0),
                  child: _Wordmark(),
                ),
                const SizedBox(height: 28),
                for (final item in _navItems)
                  _NavItem(
                    item: item,
                    isActive: nav == item.page,
                    count: counts[item.page],
                    onTap: () {
                      ref.read(selectedTaskIdProvider.notifier).state = null;
                      ref.read(navPageProvider.notifier).state = item.page;
                      onNavigate?.call();
                    },
                  ),
                const Spacer(),
                _NavItem(
                  item: _meItem,
                  isActive: nav == _meItem.page,
                  count: null,
                  onTap: () {
                    ref.read(selectedTaskIdProvider.notifier).state = null;
                    ref.read(navPageProvider.notifier).state = _meItem.page;
                    onNavigate?.call();
                  },
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [AppTheme.accentBlue, AppTheme.accentPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 10, 0),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 10),
          Text(
            'Lumi',
            style: AppTheme.display(
              size: 16,
              weight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavSpec item;
  final bool isActive;
  final int? count;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? AppTheme.accentBlueDeep : AppTheme.fgSecondary;
    final iconFg = isActive ? AppTheme.accentBlueDeep : AppTheme.fgTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppTheme.durStd,
              curve: AppTheme.easeStandard,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xA6FFFFFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive ? AppTheme.shadowCard : null,
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 17, color: iconFg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTheme.body(
                        size: 14,
                        weight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: fg,
                      ),
                    ),
                  ),
                  if (item.page == NavPage.tasks && count != null && count! > 0)
                    _CountBadge(count: count!, isActive: isActive),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool isActive;

  const _CountBadge({required this.count, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accentBlue : const Color(0x14000000),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppTheme.body(
          size: 11,
          weight: FontWeight.w700,
          color: isActive ? Colors.white : AppTheme.fgTertiary,
          height: 1.0,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class SidebarMenuButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const SidebarMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        child: GlassContainer(
          width: 40,
          height: 40,
          borderRadius: AppTheme.radiusFull,
          surface: GlassSurface.menu,
          shadow: AppTheme.shadowCard,
          onTap: onTap,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppTheme.durStd,
              switchInCurve: AppTheme.easeStandard,
              switchOutCurve: AppTheme.easeExit,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 20,
                color: AppTheme.fgSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final NavPage page;
  final String label;
  final IconData icon;

  const _NavSpec(this.page, this.label, this.icon);
}

const List<_NavSpec> _navItems = [
  _NavSpec(NavPage.overview, 'Overview', Icons.bar_chart_rounded),
  _NavSpec(NavPage.tasks, 'Tasks', Icons.grid_view_rounded),
];

const _NavSpec _meItem = _NavSpec(
  NavPage.me,
  'Profile',
  Icons.person_rounded,
);
