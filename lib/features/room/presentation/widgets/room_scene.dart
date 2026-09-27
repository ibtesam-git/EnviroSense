import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/motion/enviro_motion.dart';

/// Decorative room layers only; it consumes readings passed by the UI and does
/// not read BLE, app state, or repositories itself.
class RoomScene extends StatefulWidget {
  const RoomScene({
    required this.temperatureC,
    required this.humidityPercent,
    this.thresholdAlert = false,
    this.reduceMotion = false,
    this.scrollProgress = 0,
    super.key,
  });

  final double temperatureC;
  final double humidityPercent;
  final bool thresholdAlert;
  final bool reduceMotion;
  final double scrollProgress;

  @override
  State<RoomScene> createState() => _RoomSceneState();
}

class _RoomSceneState extends State<RoomScene>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _alertPulse;
  late final AnimationController _ringTransition;
  late final Listenable _repaint;
  late Color _fromRingColor;
  late Color _toRingColor;

  Color _comfortColor() => widget.thresholdAlert
      ? EnviroPalette.coral
      : enviroMoodColor(widget.temperatureC);

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: EnviroMotion.ambientDriftDuration,
    );
    _alertPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _ringTransition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1,
    );
    _fromRingColor = _comfortColor();
    _toRingColor = _fromRingColor;
    _repaint = Listenable.merge([_ambient, _alertPulse, _ringTransition]);
    _syncAnimations();
  }

  void _syncAnimations() {
    if (widget.reduceMotion) {
      _ambient.stop();
      _ambient.value = 0;
      _alertPulse.stop();
      _alertPulse.value = 0;
      _ringTransition.stop();
      _ringTransition.value = 1;
      _fromRingColor = _toRingColor;
      return;
    }
    if (!_ambient.isAnimating) _ambient.repeat();
    if (widget.thresholdAlert) {
      if (!_alertPulse.isAnimating) _alertPulse.repeat(reverse: true);
    } else {
      _alertPulse.stop();
      _alertPulse.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant RoomScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextColor = _comfortColor();
    if (nextColor != _toRingColor) {
      _fromRingColor = Color.lerp(
        _fromRingColor,
        _toRingColor,
        _ringTransition.value,
      )!;
      _toRingColor = nextColor;
      if (widget.reduceMotion) {
        _ringTransition.value = 1;
        _fromRingColor = nextColor;
      } else {
        _ringTransition.forward(from: 0);
      }
    }
    _syncAnimations();
  }

  @override
  void dispose() {
    _ambient.dispose();
    _alertPulse.dispose();
    _ringTransition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _RoomPainter(
          phase: _ambient,
          alertPulse: _alertPulse,
          temperature: widget.temperatureC,
          humidity: widget.humidityPercent,
          thresholdAlert: widget.thresholdAlert,
          reduceMotion: widget.reduceMotion,
          scrollProgress: widget.scrollProgress,
          ringColor: Color.lerp(
            _fromRingColor,
            _toRingColor,
            _ringTransition.value,
          )!,
          repaint: _repaint,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({
    required this.phase,
    required this.alertPulse,
    required this.temperature,
    required this.humidity,
    required this.thresholdAlert,
    required this.reduceMotion,
    required this.scrollProgress,
    required this.ringColor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final Animation<double> phase;
  final Animation<double> alertPulse;
  final double temperature;
  final double humidity;
  final bool thresholdAlert;
  final bool reduceMotion;
  final double scrollProgress;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final t = reduceMotion ? 0.0 : phase.value;
    final scroll = reduceMotion
        ? 0.0
        : scrollProgress.clamp(0.0, 1.0).toDouble();
    final wall = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(wall, Paint()..color = EnviroPalette.surface);

    // Far wall and near floor travel at different rates as the hero collapses.
    canvas.save();
    canvas.translate(-scroll * w * 0.015, -scroll * h * 0.035);
    _drawWindow(canvas, w, h);
    _drawWallArt(canvas, w, h);
    _drawLamp(canvas, w, h, t);
    canvas.restore();
    _drawWindowLight(canvas, w, h, scroll);
    canvas.save();
    canvas.translate(0, scroll * h * 0.045);
    _drawFloor(canvas, w, h);
    canvas.restore();
    if (!reduceMotion) {
      _drawDust(canvas, w, h, t);
      if (temperature > 27) _drawHeatHaze(canvas, w, h, t);
      if (humidity > 62) _drawMist(canvas, w, h, t);
    }
    _drawComfortRing(canvas, w, h);
  }

  void _drawWindowLight(Canvas canvas, double w, double h, double scroll) {
    final hour = DateTime.now().hour;
    final daylight = hour >= 7 && hour < 17;
    final dawnOrDusk = (hour >= 5 && hour < 7) || (hour >= 17 && hour < 19);
    final strength = daylight ? 0.045 : dawnOrDusk ? 0.035 : 0.008;
    final top = h * (0.49 - scroll * 0.02);
    final floor = h * (0.78 + scroll * 0.025);
    final beam = Path()
      ..moveTo(w * 0.17, top)
      ..lineTo(w * 0.70, floor)
      ..lineTo(w * 0.12, floor)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EnviroPalette.amberWarm.withValues(alpha: strength),
            EnviroPalette.amberWarm.withValues(alpha: strength * 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, top, w * 0.72, floor - top)),
    );
  }

  void _drawWindow(Canvas canvas, double w, double h) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.075, h * 0.105, w * 0.54, h * 0.405),
      const Radius.circular(15),
    );
    final inner = frame.outerRect.deflate(7);
    canvas.save();
    canvas.clipRRect(frame);

    final now = DateTime.now();
    final sky = _skyColors(now);
    canvas.drawRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(inner),
    );

    if (now.hour >= 19 || now.hour < 5) {
      final stars = <Offset>[
        Offset(inner.left + inner.width * 0.18, inner.top + inner.height * 0.18),
        Offset(inner.left + inner.width * 0.44, inner.top + inner.height * 0.31),
        Offset(inner.left + inner.width * 0.75, inner.top + inner.height * 0.16),
        Offset(inner.left + inner.width * 0.84, inner.top + inner.height * 0.42),
      ];
      for (var i = 0; i < stars.length; i++) {
        final period = 3.0 + (i % 4);
        final twinkle = 0.32 +
            0.28 *
                math
                    .sin(i + phase.value * (16 / period) * math.pi * 2)
                    .abs();
        canvas.drawCircle(
          stars[i],
          i.isEven ? 1.6 : 1.1,
          Paint()..color = const Color(0xFFF3F1EA).withValues(alpha: twinkle),
        );
      }
    }

    final skyline = Path()
      ..moveTo(inner.left, inner.bottom)
      ..lineTo(inner.left, inner.top + inner.height * 0.72)
      ..lineTo(inner.left + inner.width * 0.15, inner.top + inner.height * 0.62)
      ..lineTo(inner.left + inner.width * 0.29, inner.top + inner.height * 0.70)
      ..lineTo(inner.left + inner.width * 0.44, inner.top + inner.height * 0.52)
      ..lineTo(inner.left + inner.width * 0.61, inner.top + inner.height * 0.68)
      ..lineTo(inner.left + inner.width * 0.78, inner.top + inner.height * 0.58)
      ..lineTo(inner.right, inner.top + inner.height * 0.70)
      ..lineTo(inner.right, inner.bottom)
      ..close();
    canvas.drawPath(skyline, Paint()..color = const Color(0xFF18252A).withValues(alpha: 0.62));

    final mullion = Paint()
      ..color = const Color(0xFF654F3B).withValues(alpha: 0.88)
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(inner.center.dx, inner.top),
      Offset(inner.center.dx, inner.bottom),
      mullion,
    );
    canvas.drawLine(
      Offset(inner.left, inner.top + inner.height * 0.66),
      Offset(inner.right, inner.top + inner.height * 0.66),
      mullion,
    );
    canvas.restore();

    canvas.drawRRect(
      frame,
      Paint()
        ..color = EnviroPalette.brass.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        frame.outerRect.inflate(2),
        const Radius.circular(17),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.035)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  List<Color> _skyColors(DateTime now) {
    final seconds = now.hour * 3600 +
        now.minute * 60 +
        now.second +
        now.millisecond / 1000;
    for (final boundary in const [5, 7, 17, 19]) {
      var offset = seconds - boundary * 3600;
      if (offset > 43200) offset -= 86400;
      if (offset < -43200) offset += 86400;
      if (offset.abs() <= 45) {
        final before = _paletteForHour((boundary + 23) % 24);
        final after = _paletteForHour(boundary);
        final blend = ((offset + 45) / 90).clamp(0.0, 1.0).toDouble();
        return List<Color>.generate(
          3,
              (index) => Color.lerp(before[index], after[index], blend)!,
        );
      }
    }
    return _paletteForHour(now.hour);
  }

  List<Color> _paletteForHour(int hour) {
    if (hour >= 5 && hour < 7) {
      return const [Color(0xFF2B2440), Color(0xFFE8927C), Color(0xFFF5C77E)];
    }
    if (hour >= 7 && hour < 17) {
      return const [Color(0xFF6FA8D8), Color(0xFF9EC6E2), Color(0xFFBFE0EE)];
    }
    if (hour >= 17 && hour < 19) {
      return const [Color(0xFF3A2A5C), Color(0xFFD9714E), Color(0xFFF2A65A)];
    }
    return const [Color(0xFF080B14), Color(0xFF0F1320), Color(0xFF161C2E)];
  }

  void _drawWallArt(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(w * 0.72, h * 0.20, w * 0.16, h * 0.19);
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF372E25));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(2)),
      Paint()
        ..color = EnviroPalette.brass.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final art = Path()
      ..moveTo(rect.left + 8, rect.bottom - 8)
      ..lineTo(rect.left + rect.width * 0.42, rect.top + 8)
      ..lineTo(rect.right - 8, rect.bottom - 8)
      ..close();
    canvas.drawPath(art, Paint()..color = EnviroPalette.teal.withValues(alpha: 0.25));
  }

  void _drawLamp(Canvas canvas, double w, double h, double t) {
    final center = Offset(w * 0.84, h * 0.60);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [EnviroPalette.amberWarm.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.22));
    canvas.drawCircle(center, w * 0.22, glow);

    final metal = Paint()
      ..color = EnviroPalette.brass.withValues(alpha: 0.62)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx, h * 0.39), Offset(center.dx, h * 0.72), metal);
    final shade = Path()
      ..moveTo(center.dx - w * 0.07, h * 0.40)
      ..lineTo(center.dx + w * 0.07, h * 0.40)
      ..lineTo(center.dx + w * 0.11, h * 0.48)
      ..lineTo(center.dx - w * 0.11, h * 0.48)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFF766047));
    canvas.drawLine(
      Offset(center.dx - w * 0.10, h * 0.73),
      Offset(center.dx + w * 0.10, h * 0.73),
      metal..strokeWidth = 3,
    );
    if (t > 0 && DateTime.now().hour >= 19) {
      canvas.drawCircle(
        Offset(center.dx, h * 0.47),
        3,
        Paint()..color = EnviroPalette.amberWarm.withValues(alpha: 0.75),
      );
    }
  }

  void _drawFloor(Canvas canvas, double w, double h) {
    final floor = Path()
      ..moveTo(0, h * 0.77)
      ..quadraticBezierTo(w * 0.5, h * 0.72, w, h * 0.77)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF18211F), Color(0xFF101614)],
        ).createShader(Rect.fromLTWH(0, h * 0.74, w, h * 0.26)),
    );
    final seam = Paint()
      ..color = EnviroPalette.brass.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w * 0.06, h * 0.86), Offset(w * 0.93, h * 0.86), seam);
    canvas.drawLine(Offset(w * 0.12, h * 0.94), Offset(w * 0.88, h * 0.94), seam);
  }

  void _drawDust(Canvas canvas, double w, double h, double t) {
    for (var i = 0; i < 15; i++) {
      final seed = i * 2.399963229728653;
      final period = 8 + (i * 37 % 7);
      final localPhase = t * (16 / period) * math.pi * 2 + seed;
      final baseX = w * (0.12 + (i % 6) * 0.095);
      final baseY = h * (0.16 + (i % 4) * 0.075);
      final driftX = (w * 0.07).clamp(20.0, 40.0).toDouble();
      final driftY = (h * 0.05).clamp(20.0, 40.0).toDouble();
      final x = baseX + math.sin(localPhase) * driftX;
      final y = baseY + math.cos(localPhase * 0.73) * driftY;
      final radius = 0.8 + (i % 3) * 0.35;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = EnviroPalette.textPrimary.withValues(alpha: 0.08 + (i % 4) * 0.015),
      );
    }
  }

  void _drawHeatHaze(Canvas canvas, double w, double h, double t) {
    final intensity = ((temperature - 27) / 12).clamp(0.0, 1.0).toDouble();
    final heatPhase = t *
        (EnviroMotion.ambientDriftDuration.inMilliseconds / 1800) *
        math.pi *
        2;
    final paint = Paint()
      ..color = EnviroPalette.amberWarm.withValues(alpha: 0.045 + intensity * 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var row = 0; row < 3; row++) {
      final y = h * (0.76 + row * 0.035);
      final path = Path()..moveTo(0, y);
      for (var step = 1; step <= 20; step++) {
        final x = w * step / 20;
        final waveY = y + math.sin(step * 0.70 + heatPhase + row) * 2.2;
        path.lineTo(x, waveY);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawMist(Canvas canvas, double w, double h, double t) {
    final density = ((humidity - 62) / 30).clamp(0.0, 1.0).toDouble();
    final count = 15 + (density * 10).round();
    for (var i = 0; i < count; i++) {
      final seed = i * 2.11;
      final x = w * (0.10 + (0.80 * ((math.sin(seed) + 1) / 2)));
      final travel = (t + (i / count)) % 1;
      final y = h * (0.88 - travel * 0.44);
      final radius = 10 + (i % 4) * 3;
      canvas.drawCircle(
        Offset(x + math.sin(t * 6.28 + seed) * 8, y),
        radius.toDouble(),
        Paint()
          ..color = EnviroPalette.teal.withValues(alpha: 0.04 + density * 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  void _drawComfortRing(Canvas canvas, double w, double h) {
    final color = ringColor;
    final alertBreath = thresholdAlert ? 0.15 + 0.15 * alertPulse.value : 0.18;
    final ring = RRect.fromRectAndRadius(
      Rect.fromLTWH(7, 7, w - 14, h - 14),
      const Radius.circular(24),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..color = color.withValues(alpha: alertBreath)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      ring,
      Paint()
        ..color = color.withValues(alpha: thresholdAlert ? 0.22 : 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) =>
      oldDelegate.temperature != temperature ||
          oldDelegate.humidity != humidity ||
          oldDelegate.thresholdAlert != thresholdAlert ||
          oldDelegate.reduceMotion != reduceMotion ||
          oldDelegate.scrollProgress != scrollProgress ||
          oldDelegate.phase != phase ||
          oldDelegate.alertPulse != alertPulse ||
          oldDelegate.ringColor != ringColor;
}
