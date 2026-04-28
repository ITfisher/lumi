import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
