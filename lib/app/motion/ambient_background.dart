import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'enviro_motion.dart';

/// Low-contrast ambient light. Its painter is isolated so sensor updates do not
/// rebuild foreground screens. Page progress moves the glow at 40% of swipe.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    required this.pageProgress,
    required this.accents,
    this.reduceMotion = false,
    super.key,
  });

  final ValueListenable<double> pageProgress;
  final List<Color> accents;
  final bool reduceMotion;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: EnviroMotion.ambientDriftDuration,
    );
    if (!widget.reduceMotion) _drift.repeat();
  }

  @override
  void didUpdateWidget(covariant AmbientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _drift.isAnimating) {
      _drift.stop();
      _drift.value = 0;
    } else if (!widget.reduceMotion && !_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repaint = Listenable.merge([_drift, widget.pageProgress]);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AmbientPainter(
          drift: _drift,
          pageProgress: widget.pageProgress,
          accents: widget.accents,
          repaint: repaint,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.drift,
    required this.pageProgress,
    required this.accents,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Animation<double> drift;
  final ValueListenable<double> pageProgress;
  final List<Color> accents;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(EnviroPalette.bg, BlendMode.src);
    if (accents.isEmpty || size.isEmpty) return;

    final page = pageProgress.value.clamp(0.0, accents.length - 1.0).toDouble();
    final lower = page.floor();
    final upper = (lower + 1).clamp(0, accents.length - 1).toInt();
    final accent = Color.lerp(accents[lower], accents[upper], page - lower)!;
    final phase = drift.value * math.pi * 2;

    _glow(
      canvas,
      Offset(size.width * (0.18 + 0.055 * math.sin(phase)),
          size.height * (0.20 + 0.025 * math.cos(phase))),
      size.shortestSide * 0.68,
      accent,
      0.095,
    );
    _glow(
      canvas,
      Offset(size.width * (0.85 - 0.04 * math.sin(phase + 1.8)),
          size.height * (0.69 + 0.035 * math.cos(phase + 1.8))),
      size.shortestSide * 0.72,
      EnviroPalette.teal,
      0.035,
    );
    _glow(
      canvas,
      Offset(size.width * 0.54, size.height * 0.48),
      size.shortestSide * 0.9,
      const Color(0xFF182321),
      0.12,
    );
    _drawSignalOrbit(canvas, size, accent, phase, page);
    _drawMotes(canvas, size, accent, phase, page);
  }

  void _drawSignalOrbit(
      Canvas canvas,
      Size size,
      Color accent,
      double phase,
      double page,
      ) {
    final pageCenter = (0.167 + page * 0.133).clamp(0.0, 1.0).toDouble();
    final center = Offset(size.width * pageCenter, size.height * 0.69);
    final radius = size.shortestSide * 0.22;
    for (var ring = 0; ring < 3; ring++) {
      final breathe = 1 + 0.025 * math.sin(phase + ring * 0.8);
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2 * (0.78 + ring * 0.20) * breathe,
        height: radius * 0.52 * (0.78 + ring * 0.20) * breathe,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = accent.withValues(alpha: 0.025 + ring * 0.008)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    for (var i = 0; i < 5; i++) {
      final angle = phase * (0.16 + i * 0.012) + i * math.pi * 0.4;
      final point = Offset(
        center.dx + math.cos(angle) * radius * 0.85,
        center.dy + math.sin(angle) * radius * 0.22,
      );
      canvas.drawCircle(
        point,
        1.3 + (i % 2) * 0.5,
        Paint()..color = accent.withValues(alpha: 0.12 + 0.04 * math.sin(angle).abs()),
      );
    }
  }

  void _drawMotes(
      Canvas canvas,
      Size size,
      Color accent,
      double phase,
      double page,
      ) {
    final pageCenter = (0.167 + page * 0.133).clamp(0.0, 1.0).toDouble();
    final centerX = size.width * pageCenter;
    for (var i = 0; i < 18; i++) {
      final seed = i * 2.399963229728653;
      final orbit = size.shortestSide * (0.10 + (i % 5) * 0.045);
      final angle = seed + phase * (0.08 + (i % 4) * 0.018);
      final x = centerX + math.cos(angle) * orbit;
      final y = size.height * (0.15 + (i % 7) * 0.105) +
          math.sin(angle * 0.73) * 9;
      final alpha = 0.035 + 0.025 * (0.5 + 0.5 * math.sin(angle)).abs();
      canvas.drawCircle(
        Offset(x, y),
        0.8 + (i % 3) * 0.45,
        Paint()..color = accent.withValues(alpha: alpha),
      );
    }
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color, double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      oldDelegate.accents != accents ||
          oldDelegate.pageProgress != pageProgress ||
          oldDelegate.drift != drift;
}
