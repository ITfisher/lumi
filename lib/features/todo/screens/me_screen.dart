import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../data/models/todo_model.dart';
import '../providers/todo_provider.dart';

class MeScreen extends ConsumerStatefulWidget {
  const MeScreen({super.key});

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
  late final TextEditingController _labelCtrl;
  AppUpdateCheckResult? _updateResult;
  String? _updateError;
  bool _isCheckingForUpdates = false;
  bool _isOpeningDownload = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directoryPath = ref.watch(appDirectoryPathProvider);
    final labelConfig = ref.watch(taskLabelConfigProvider);
    final currentVersion = ref.watch(appVersionProvider);
    final allowPrereleaseUpdates = ref.watch(allowPrereleaseUpdatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Page header (title only, no verbose subtitle) ──────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Text(
            'Profile',
            style: AppTheme.display(
              size: 24,
              weight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            children: [
              // ── Storage ──────────────────────────────────────────
              GlassContainer(
                borderRadius: AppTheme.radiusLg,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: directoryPath.when(
                  loading: () => _StorageRow(
                    path: 'Loading…',
                    enabled: false,
                    onOpen: null,
                  ),
                  error: (_, __) => _StorageRow(
                    path: 'Unable to resolve directory',
                    enabled: false,
                    onOpen: null,
                  ),
                  data: (path) => _StorageRow(
                    path: path,
                    enabled: true,
                    onOpen: () async {
                      final opened = await ref
                          .read(appDirectoryServiceProvider)
                          .openAppDirectory();
                      if (!context.mounted || opened) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open the directory'),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Updates ──────────────────────────────────────────
              GlassContainer(
                borderRadius: AppTheme.radiusLg,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'Updates',
                          style: AppTheme.body(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        _UpdateRefreshButton(
                          busy: _isCheckingForUpdates,
                          onPressed: _isCheckingForUpdates
                              ? null
                              : () => _checkForUpdates(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Version + Prerelease toggle in one compact row
                    Row(
                      children: [
                        currentVersion.when(
                          loading: () => Text(
                            '—',
                            style: AppTheme.mono(
                                size: 12, color: AppTheme.fgTertiary),
                          ),
                          error: (_, __) => Text(
                            '—',
                            style: AppTheme.mono(
                                size: 12, color: AppTheme.fgTertiary),
                          ),
                          data: (v) => Text(
                            'v$v',
                            style: AppTheme.mono(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.fgSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Prerelease',
                          style: AppTheme.body(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppTheme.fgSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        allowPrereleaseUpdates.when(
                          loading: () => Switch.adaptive(
                            value: false,
                            onChanged: null,
                          ),
                          error: (_, __) => Switch.adaptive(
                            value: false,
                            onChanged: null,
                          ),
                          data: (enabled) => Switch.adaptive(
                            value: enabled,
                            onChanged: (v) =>
                                _setAllowPrereleaseUpdates(context, v),
                            activeThumbColor: AppTheme.accentBlue,
                            activeTrackColor:
                                AppTheme.accentBlue.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Status chip + download button
                    Row(
                      children: [
                        _UpdateStatusChip(
                          text: _buildUpdateStatusText(),
                          isError: _updateError != null,
                          isChecking: _isCheckingForUpdates,
                          hasUpdate: _updateResult?.hasUpdate == true,
                          isChecked: _updateResult != null,
                        ),
                        if (_updateResult != null &&
                            _updateResult!.hasUpdate) ...[
                          const Spacer(),
                          _DownloadButton(
                            label: _updateResult!.latestRelease.hasDmgAsset
                                ? 'Download DMG'
                                : 'Open release',
                            busy: _isOpeningDownload,
                            onTap: () => _openReleaseAsset(context),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Labels ───────────────────────────────────────────
              GlassContainer(
                borderRadius: AppTheme.radiusLg,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Labels',
                      style: AppTheme.body(
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Input row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0x66FFFFFF),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: AppTheme.glassBorderMedium,
                              ),
                            ),
                            child: TextField(
                              controller: _labelCtrl,
                              onSubmitted: (_) => _addLabel(context),
                              cursorColor: AppTheme.accentBlue,
                              style: AppTheme.body(size: 13),
                              decoration: InputDecoration(
                                hintText: 'New label…',
                                hintStyle: AppTheme.body(
                                  size: 13,
                                  color: AppTheme.fgTertiary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _AddButton(onTap: () => _addLabel(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    labelConfig.when(
                      loading: () => Text(
                        'Loading…',
                        style: AppTheme.body(
                          size: 12,
                          color: AppTheme.fgTertiary,
                        ),
                      ),
                      error: (_, __) => Text(
                        'Unable to load labels.',
                        style: AppTheme.body(
                          size: 12,
                          color: AppTheme.statusOverdue,
                        ),
                      ),
                      data: (labels) {
                        if (labels.isEmpty) {
                          return Text(
                            'No labels yet.',
                            style: AppTheme.body(
                              size: 12,
                              color: AppTheme.fgTertiary,
                            ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in labels)
                              _EditableLabelChip(
                                label: label,
                                onRemove: () => _removeLabel(label, labels),
                              ),
                          ],
                        );
                      },
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

  // ── Helpers ──────────────────────────────────────────────────────

  Future<void> _addLabel(BuildContext context) async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;

    final current = ref.read(taskLabelConfigProvider).maybeWhen(
          data: (labels) => labels,
          orElse: () => const <String>[],
        );
    final next = TodoModel.normalizeLabels([...current, label]);
    if (next.length == current.length) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label already exists')),
      );
      return;
    }

    await ref.read(taskLabelConfigProvider.notifier).saveLabels(next);
    _labelCtrl.clear();
  }

  Future<void> _removeLabel(String label, List<String> current) async {
    final next = current.where((item) => item != label).toList();
    await ref.read(taskLabelConfigProvider.notifier).saveLabels(next);
  }

  String _buildUpdateStatusText() {
    if (_updateError != null) return 'Check failed';
    if (_isCheckingForUpdates) return 'Checking…';
    if (_updateResult == null) return 'Not checked';
    if (_updateResult!.hasUpdate) {
      return 'v${_updateResult!.latestRelease.version} available';
    }
    return 'Up to date';
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final allowPrerelease = ref.read(allowPrereleaseUpdatesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );

    setState(() {
      _isCheckingForUpdates = true;
      _updateError = null;
    });

    try {
      final result = await ref.read(appUpdateServiceProvider).checkForUpdates(
            includePrerelease: allowPrerelease,
          );
      if (!mounted) return;

      setState(() => _updateResult = result);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.hasUpdate
                ? 'v${result.latestRelease.version} is available'
                : 'Already on the latest version',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updateError = 'Unable to check updates right now.');
      messenger.showSnackBar(
        const SnackBar(content: Text('Check for updates failed')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingForUpdates = false);
    }
  }

  Future<void> _openReleaseAsset(BuildContext context) async {
    final latestRelease = _updateResult?.latestRelease;
    if (latestRelease == null) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isOpeningDownload = true);

    final opened = await ref
        .read(appUpdateServiceProvider)
        .openUrl(latestRelease.downloadUrl);
    if (!mounted) return;

    setState(() => _isOpeningDownload = false);

    if (opened) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Unable to open the download page')),
    );
  }

  Future<void> _setAllowPrereleaseUpdates(
    BuildContext context,
    bool value,
  ) async {
    await ref
        .read(allowPrereleaseUpdatesProvider.notifier)
        .saveAllowPrereleaseUpdates(value);
    if (!mounted) return;

    setState(() {
      _updateResult = null;
      _updateError = null;
    });
  }
}

// ──────────────────────────────────────────────────────────────────
// Storage row — compact icon + truncated path + Open button
// ──────────────────────────────────────────────────────────────────
class _StorageRow extends StatelessWidget {
  final String path;
  final bool enabled;
  final VoidCallback? onOpen;

  const _StorageRow({
    required this.path,
    required this.enabled,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.storage_rounded,
          size: 15,
          color: AppTheme.fgTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.mono(
              size: 11,
              color: enabled ? AppTheme.fgSecondary : AppTheme.fgTertiary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: enabled ? onOpen : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: AppTheme.accentBlue.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              'Open',
              style: AppTheme.body(
                size: 12,
                weight: FontWeight.w600,
                color: enabled ? AppTheme.accentBlueDeep : AppTheme.fgTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Update status chip
// ──────────────────────────────────────────────────────────────────
class _UpdateStatusChip extends StatelessWidget {
  final String text;
  final bool isError;
  final bool isChecking;
  final bool hasUpdate;
  final bool isChecked;

  const _UpdateStatusChip({
    required this.text,
    required this.isError,
    required this.isChecking,
    required this.hasUpdate,
    required this.isChecked,
  });

  Color get _color {
    if (isError) return AppTheme.statusOverdue;
    if (hasUpdate) return AppTheme.accentBlueDeep;
    if (isChecked) return AppTheme.statusDoneDeep;
    return AppTheme.fgTertiary;
  }

  IconData get _icon {
    if (isError) return Icons.error_outline_rounded;
    if (hasUpdate) return Icons.new_releases_outlined;
    if (isChecked) return Icons.check_circle_outline_rounded;
    return Icons.radio_button_unchecked_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isChecking)
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(_icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTheme.body(
              size: 12,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Download button — gradient pill
// ──────────────────────────────────────────────────────────────────
class _DownloadButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              busy
                  ? Icons.hourglass_top_rounded
                  : Icons.download_for_offline_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              busy ? 'Opening…' : label,
              style: AppTheme.body(
                size: 12,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Add label button — gradient circle
// ──────────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accentBlue, AppTheme.accentPurpleDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentBlue.withValues(alpha: 0.32),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Editable label chip
// ──────────────────────────────────────────────────────────────────
class _EditableLabelChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _EditableLabelChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: AppTheme.accentBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTheme.body(
              size: 12,
              weight: FontWeight.w600,
              color: AppTheme.accentBlueDeep,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: AppTheme.accentBlueDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Refresh button
// ──────────────────────────────────────────────────────────────────
class _UpdateRefreshButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;

  const _UpdateRefreshButton({
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        tooltip: 'Check for updates',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.10),
          foregroundColor: AppTheme.accentBlueDeep,
          side: BorderSide(
            color: AppTheme.accentBlue.withValues(alpha: 0.20),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              )
            : const Icon(Icons.refresh_rounded, size: 16),
      ),
    );
  }
}
