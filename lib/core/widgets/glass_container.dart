import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The four glass surface variants used across GlassTask.
///
/// Each maps to one of the design-system layers documented in
/// `colors_and_type.css` (`--glass-card-*`, `--glass-shell-*`,
/// `--glass-modal-*`, `--glass-menu-*`).
enum GlassSurface { card, shell, modal, menu }

extension GlassSurfaceProps on GlassSurface {
  Color get fill {
    switch (this) {
      case GlassSurface.card:
        return AppTheme.glassCardFill;
      case GlassSurface.shell:
        return AppTheme.glassShellFill;
      case GlassSurface.modal:
        return AppTheme.glassModalFill;
      case GlassSurface.menu:
        return AppTheme.glassMenuFill;
    }
  }

  double get blurSigma {
    switch (this) {
      case GlassSurface.card:
        return AppTheme.glassCardBlur;
      case GlassSurface.shell:
        return AppTheme.glassShellBlur;
      case GlassSurface.modal:
        return AppTheme.glassModalBlur;
      case GlassSurface.menu:
        return AppTheme.glassMenuBlur;
    }
  }

  double get saturation {
    switch (this) {
      case GlassSurface.card:
        return 1.80;
      case GlassSurface.shell:
        return 1.60;
      case GlassSurface.modal:
        return 2.00;
      case GlassSurface.menu:
        return 1.80;
    }
  }
}

/// A frosted-glass surface with optional border, shadow and tap target.
///
/// The hairline border is rendered via `foregroundDecoration` so that
/// it does NOT consume any inner layout width.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final GlassSurface surface;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final List<BoxShadow>? shadow;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.surface = GlassSurface.card,
    this.borderRadius = AppTheme.radiusMd,
    this.padding,
    this.margin,
    this.tint,
    this.shadow,
    this.border,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    final shadows = shadow ?? AppTheme.shadowCard;
    final hairline = border ??
        const Border.fromBorderSide(
          BorderSide(color: AppTheme.glassBorderLight, width: 1),
        );

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    Widget surfaceWidget = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.compose(
                  inner: ImageFilter.blur(
                    sigmaX: surface.blurSigma,
                    sigmaY: surface.blurSigma,
                  ),
                  outer: ColorFilter.matrix(
                    _saturationMatrix(surface.saturation),
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint ?? surface.fill,
                    borderRadius: r,
                  ),
                ),
              ),
            ),
            content,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    border: hairline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      surfaceWidget = Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          splashColor: AppTheme.accentBlue.withValues(alpha: 0.06),
          highlightColor: AppTheme.accentBlue.withValues(alpha: 0.04),
          child: surfaceWidget,
        ),
      );
    }

    Widget result = DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadows),
      child: surfaceWidget,
    );

    if (margin != null) result = Padding(padding: margin!, child: result);
    return result;
  }

  static List<double> _saturationMatrix(double s) {
    final lr = 0.2126 * (1 - s);
    final lg = 0.7152 * (1 - s);
    final lb = 0.0722 * (1 - s);
    return <double>[
      lr + s,
      lg,
      lb,
      0,
      0,
      lr,
      lg + s,
      lb,
      0,
      0,
      lr,
      lg,
      lb + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
