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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: AppTheme.display(
                  size: 24,
                  weight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Manage local settings and storage.',
                style: AppTheme.mono(size: 13, color: AppTheme.fgTertiary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            children: [
              GlassContainer(
                borderRadius: AppTheme.radiusLg,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: AppTheme.body(
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    directoryPath.when(
                      loading: () => const _PathSettingRow(
                        label: 'Directory path',
                        value: 'Loading...',
                        buttonLabel: 'Open',
                        enabled: false,
                      ),
                      error: (error, _) => const _PathSettingRow(
                        label: 'Directory path',
                        value: 'Unable to resolve local directory',
                        buttonLabel: 'Open',
                        enabled: false,
                      ),
                      data: (path) => _PathSettingRow(
                        label: 'Directory path',
                        value: path,
                        buttonLabel: 'Open',
                        onPressed: () async {
                          final opened = await ref
                              .read(appDirectoryServiceProvider)
                              .openAppDirectory();
                          if (!context.mounted || opened) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Unable to open the directory right now'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                borderRadius: AppTheme.radiusLg,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Updates',
                            style: AppTheme.body(
                              size: 15,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _UpdateRefreshButton(
                          busy: _isCheckingForUpdates,
                          onPressed: _isCheckingForUpdates
                              ? null
                              : () => _checkForUpdates(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    currentVersion.when(
                      loading: () => const _UpdateMetaRow(
                        label: 'Version',
                        value: 'Loading...',
                      ),
                      error: (error, _) => const _UpdateMetaRow(
                        label: 'Version',
                        value: 'Unavailable',
                        isError: true,
                      ),
                      data: (version) => _UpdateMetaRow(
                        label: 'Version',
                        value: 'v$version',
                      ),
                    ),
                    const SizedBox(height: 8),
                    allowPrereleaseUpdates.when(
                      loading: () => const _UpdateToggleRow(
                        value: false,
                        enabled: false,
                      ),
                      error: (error, _) => const _UpdateToggleRow(
                        value: false,
                        enabled: false,
                      ),
                      data: (enabled) => _UpdateToggleRow(
                        value: enabled,
                        enabled: true,
                        onChanged: (value) =>
                            _setAllowPrereleaseUpdates(context, value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _UpdateMetaRow(
                      label: 'Status',
                      value: _buildUpdateStatusText(),
                      isError: _updateError != null,
                    ),
                    if (_updateResult != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isOpeningDownload
                              ? null
                              : () => _openReleaseAsset(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.accentBlueDeep,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _isOpeningDownload
                                ? 'Opening...'
                                : _updateResult!.latestRelease.hasDmgAsset
                                    ? 'Download DMG'
                                    : 'Open release page',
                            style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppTheme.accentBlueDeep,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                borderRadius: AppTheme.radiusLg,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task labels',
                      style: AppTheme.body(
                        size: 15,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preconfigure labels here. New tasks can select multiple labels from this list.',
                      style: AppTheme.body(
                        size: 13,
                        color: AppTheme.fgSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _labelCtrl,
                            onSubmitted: (_) => _addLabel(context),
                            decoration: InputDecoration(
                              hintText: 'Add a label',
                              hintStyle: AppTheme.body(
                                size: 14,
                                color: AppTheme.fgTertiary,
                              ),
                              filled: true,
                              fillColor: const Color(0x66FFFFFF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.glassBorderMedium,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                borderSide: BorderSide(
                                  color: AppTheme.glassBorderMedium,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => _addLabel(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                          ),
                          child: Text(
                            'Add',
                            style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    labelConfig.when(
                      loading: () => Text(
                        'Loading labels...',
                        style: AppTheme.body(
                          size: 13,
                          color: AppTheme.fgTertiary,
                        ),
                      ),
                      error: (error, _) => Text(
                        'Unable to load labels right now.',
                        style: AppTheme.body(
                          size: 13,
                          color: AppTheme.statusOverdue,
                        ),
                      ),
                      data: (labels) {
                        if (labels.isEmpty) {
                          return Text(
                            'No labels configured yet.',
                            style: AppTheme.body(
                              size: 13,
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

  Future<void> _addLabel(BuildContext context) async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;

    final current = ref.read(taskLabelConfigProvider).maybeWhen(
          data: (labels) => labels,
          orElse: () => const <String>[],
        );
    final next = TodoModel.normalizeLabels([...current, label]);
    if (next.length == current.length) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This label already exists')),
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
    if (_updateError != null) return _updateError!;
    if (_isCheckingForUpdates) return 'Checking GitHub Releases...';
    if (_updateResult == null) return 'Not checked yet.';
    if (_updateResult!.hasUpdate) {
      final kind =
          _updateResult!.latestRelease.isPrerelease ? 'Prerelease' : 'Update';
      return '$kind available: v${_updateResult!.latestRelease.version}';
    }
    return 'You are on the latest version.';
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

      setState(() {
        _updateResult = result;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.hasUpdate
                ? 'New version v${result.latestRelease.version} is available'
                : 'You already have the latest version',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _updateError = 'Unable to check updates right now.';
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Update check failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingForUpdates = false;
        });
      }
    }
  }

  Future<void> _openReleaseAsset(BuildContext context) async {
    final latestRelease = _updateResult?.latestRelease;
    if (latestRelease == null) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isOpeningDownload = true;
    });

    final opened = await ref
        .read(appUpdateServiceProvider)
        .openUrl(latestRelease.downloadUrl);
    if (!mounted) return;

    setState(() {
      _isOpeningDownload = false;
    });

    if (opened) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Unable to open the download page')),
    );
  }

  Future<void> _setAllowPrereleaseUpdates(
    BuildContext context,
    bool value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    await ref
        .read(allowPrereleaseUpdatesProvider.notifier)
        .saveAllowPrereleaseUpdates(value);
    if (!mounted) return;

    setState(() {
      _updateResult = null;
      _updateError = null;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Prerelease updates enabled'
              : 'Only stable releases will be checked',
        ),
      ),
    );
  }
}

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

class _PathSettingRow extends StatelessWidget {
  final String label;
  final String value;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool enabled;

  const _PathSettingRow({
    required this.label,
    required this.value,
    required this.buttonLabel,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.glassBorderMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.label(size: 11)),
                const SizedBox(height: 8),
                SelectableText(
                  value,
                  style: AppTheme.mono(
                    size: 12,
                    color: enabled ? AppTheme.fgSecondary : AppTheme.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
            ),
            child: Text(
              buttonLabel,
              style: AppTheme.body(
                size: 13,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateMetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _UpdateMetaRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: AppTheme.label(size: 11)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: AppTheme.mono(
              size: 12,
              color: isError ? AppTheme.statusOverdue : AppTheme.fgSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateToggleRow extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _UpdateToggleRow({
    required this.value,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Allow prerelease updates',
                style: AppTheme.body(
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Turn on to include GitHub prerelease DMG builds.',
                style: AppTheme.body(
                  size: 12,
                  color: AppTheme.fgSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeThumbColor: AppTheme.accentBlue,
          activeTrackColor: AppTheme.accentBlue.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

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
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: 'Refresh updates',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.12),
          foregroundColor: AppTheme.accentBlueDeep,
          side: BorderSide(
            color: AppTheme.accentBlue.withValues(alpha: 0.22),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh_rounded, size: 18),
      ),
    );
  }
}
