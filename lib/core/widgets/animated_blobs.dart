import 'dart:ui';

import 'package:flutter/material.dart';

/// Three large translucent colour blobs that drift around in the
/// background — gives the glass surfaces something interesting to
/// refract. Mirrors the `.blob1/.blob2/.blob3` keyframe animation
/// in `ui_kits/todo_app/index.html`.
class AnimatedBlobs extends StatefulWidget {
  const AnimatedBlobs({super.key});

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The blob colours match the design HTML's oklch values.
    final blobs = <_BlobSpec>[
      _BlobSpec(
        color: const Color(0xFF8BAEFF),
        size: 500,
        opacity: 0.30,
        top: -100,
        left: -100,
        phase: 0.0,
      ),
      _BlobSpec(
        color: const Color(0xFFC4B0FF),
        size: 400,
        opacity: 0.28,
        bottom: -80,
        right: -80,
        phase: 0.33,
      ),
      _BlobSpec(
        color: const Color(0xFF8FE1DC),
        size: 300,
        opacity: 0.24,
        topFraction: 0.4,
        leftFraction: 0.4,
        phase: 0.66,
      ),
    ];

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (final b in blobs)
                    _buildBlob(b, _ctrl.value, constraints),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBlob(_BlobSpec b, double t, BoxConstraints constraints) {
    // Triangle wave per-blob, offset by phase, mapping 0..1.
    final phased = ((t + b.phase) % 1.0);
    // Smooth triangle 0→1→0
    final eased = phased < 0.5 ? phased * 2 : (1 - phased) * 2;
    final dx = 30 * eased;
    final dy = 20 * eased;
    final scale = 1.0 + 0.08 * eased;

    final top = b.top ??
        (b.topFraction != null ? constraints.maxHeight * b.topFraction! : null);
    final left = b.left ??
        (b.leftFraction != null
            ? constraints.maxWidth * b.leftFraction!
            : null);

    return Positioned(
      top: top,
      bottom: b.bottom,
      left: left,
      right: b.right,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Opacity(
              opacity: b.opacity,
              child: Container(
                width: b.size,
                height: b.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: b.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlobSpec {
  final Color color;
  final double size;
  final double opacity;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double? topFraction;
  final double? leftFraction;
  final double phase;

  _BlobSpec({
    required this.color,
    required this.size,
    required this.opacity,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.topFraction,
    this.leftFraction,
    required this.phase,
  });
}
