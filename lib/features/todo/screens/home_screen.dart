import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_menu_service.dart';
import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_blobs.dart';
import '../providers/todo_provider.dart';
import '../widgets/kanban/kanban_board.dart';
import '../widgets/list/todo_list_view.dart';
import '../widgets/shared/todo_form_sheet.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';
import 'me_screen.dart';
import 'overview_screen.dart';
import 'task_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool? _lastIsWide;
  bool? _sidebarCollapsed;
  StreamSubscription<void>? _menuUpdateSub;

  @override
  void initState() {
    super.initState();
    _menuUpdateSub = AppMenuService.instance.onCheckForUpdates.listen((_) {
      if (mounted) _checkForUpdatesFromMenu();
    });
  }

  @override
  void dispose() {
    _menuUpdateSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    if (_lastIsWide == isWide) return;

    _lastIsWide = isWide;
    _sidebarCollapsed = !isWide;
  }

  Future<void> _checkForUpdatesFromMenu() async {
    final messenger = ScaffoldMessenger.of(context);
    final allowPrerelease = ref.read(allowPrereleaseUpdatesProvider).maybeWhen(
          data: (v) => v,
          orElse: () => false,
        );

    try {
      final result = await ref
          .read(appUpdateServiceProvider)
          .checkForUpdates(includePrerelease: allowPrerelease);
      if (!mounted) return;

      if (result.hasUpdate) {
        _showUpdateAvailableDialog(result);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Already on the latest version')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Check for updates failed')),
      );
    }
  }

  void _showUpdateAvailableDialog(AppUpdateCheckResult result) {
    final release = result.latestRelease;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'v${release.version} is available.\n'
          'You are currently on v${result.currentVersion}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(appUpdateServiceProvider)
                  .openUrl(release.downloadUrl);
            },
            child: Text(release.hasDmgAsset ? 'Download' : 'View Release'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 720;
    final sidebarCollapsed = _sidebarCollapsed ?? !isWide;

    return Scaffold(
      body: Stack(
        children: [
          const _CanvasGradient(),
          const AnimatedBlobs(),
          SafeArea(
            child: isWide
                ? _DesktopShell(
                    collapsed: sidebarCollapsed,
                    onCollapse: _collapseSidebar,
                  )
                : _CompactShell(
                    collapsed: sidebarCollapsed,
                    onCollapse: _collapseSidebar,
                  ),
          ),
          _SidebarMenuButtonOverlay(
            collapsed: sidebarCollapsed,
            onOpen: _expandSidebar,
            onCollapse: _collapseSidebar,
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final page = ref.watch(navPageProvider);
          final selectedTaskId = ref.watch(selectedTaskIdProvider);
          return page == NavPage.tasks && selectedTaskId == null
              ? const _Fab()
              : const SizedBox.shrink();
        },
      ),
    );
  }

  void _collapseSidebar() {
    if (_sidebarCollapsed == true) return;
    setState(() => _sidebarCollapsed = true);
  }

  void _expandSidebar() {
    if (_sidebarCollapsed == false) return;
    setState(() => _sidebarCollapsed = false);
  }
}

class _CanvasGradient extends StatelessWidget {
  const _CanvasGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.canvasGradient,
          stops: AppTheme.canvasStops,
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onCollapse;

  const _DesktopShell({
    required this.collapsed,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: AppTheme.durLayout,
          curve: AppTheme.easeStandard,
          width: collapsed ? 0 : GlassSidebar.widthExpanded,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: GlassSidebar.widthExpanded,
              maxWidth: GlassSidebar.widthExpanded,
              child: GlassSidebar(onCollapse: onCollapse),
            ),
          ),
        ),
        Expanded(
          child: _ContentPane(reserveMenuButtonSpace: collapsed),
        ),
      ],
    );
  }
}

class _CompactShell extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onCollapse;

  const _CompactShell({
    required this.collapsed,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ContentPane(reserveMenuButtonSpace: collapsed),
        if (!collapsed)
          Positioned.fill(
            left: GlassSidebar.widthExpanded,
            child: GestureDetector(
              onTap: onCollapse,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
        AnimatedPositioned(
          duration: AppTheme.durLayout,
          curve: AppTheme.easeStandard,
          left: collapsed ? -GlassSidebar.widthExpanded : 0,
          top: 0,
          bottom: 0,
          width: GlassSidebar.widthExpanded,
          child: IgnorePointer(
            ignoring: collapsed,
            child: GlassSidebar(
              onNavigate: onCollapse,
              onCollapse: onCollapse,
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarMenuButtonOverlay extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onOpen;
  final VoidCallback onCollapse;

  const _SidebarMenuButtonOverlay({
    required this.collapsed,
    required this.onOpen,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final top = safeTop + 52;
    final left = collapsed ? 12.0 : GlassSidebar.widthExpanded - 20;

    return AnimatedPositioned(
      duration: AppTheme.durLayout,
      curve: AppTheme.easeStandard,
      top: top,
      left: left,
      child: SidebarMenuButton(
        icon: collapsed ? Icons.menu_rounded : Icons.chevron_left_rounded,
        tooltip: collapsed ? 'Open menu' : 'Collapse menu',
        onTap: collapsed ? onOpen : onCollapse,
      ),
    );
  }
}

/// Routes between Overview and Tasks panes based on navPageProvider.
class _ContentPane extends ConsumerWidget {
  final bool reserveMenuButtonSpace;

  const _ContentPane({this.reserveMenuButtonSpace = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(navPageProvider);
    final selectedTaskId = ref.watch(selectedTaskIdProvider);
    return AnimatedPadding(
      duration: AppTheme.durLayout,
      curve: AppTheme.easeStandard,
      padding: EdgeInsets.only(left: reserveMenuButtonSpace ? 40 : 0),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x14FFFFFF)),
        child: selectedTaskId != null
            ? TaskDetailScreen(taskId: selectedTaskId)
            : page == NavPage.overview
                ? const OverviewScreen()
                : page == NavPage.me
                    ? const MeScreen()
                    : const _TasksPane(),
      ),
    );
  }
}

class _TasksPane extends ConsumerWidget {
  const _TasksPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    return Column(
      children: [
        const GlassTopBar(),
        Expanded(
          child: viewMode == ViewMode.list
              ? const TodoListView()
              : const KanbanBoard(),
        ),
      ],
    );
  }
}

class _Fab extends StatefulWidget {
  const _Fab();

  @override
  State<_Fab> createState() => _FabState();
}

class _FabState extends State<_Fab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.18),
          builder: (_) => const Dialog(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TodoFormSheet(isDialog: true),
          ),
        ),
        child: AnimatedScale(
          duration: AppTheme.durStd,
          curve: AppTheme.easeSpring,
          scale: _hover ? 1.08 : 1.0,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: AppTheme.shadowFab,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
