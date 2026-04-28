import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../providers/todo_provider.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final directoryPath = ref.watch(appDirectoryPathProvider);

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
            ],
          ),
        ),
      ],
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
