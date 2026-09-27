import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../../app/motion/enviro_motion.dart';

/// A quiet environmental cue: humidity changes leaf posture with a spring,
/// while a separate slow sway keeps the room scene gently alive.
class ReactivePlant extends StatefulWidget {
  const ReactivePlant({
    required this.humidityPercent,
    this.reduceMotion = false,
    super.key,
  });

  final double humidityPercent;
  final bool reduceMotion;

  @override
  State<ReactivePlant> createState() => _ReactivePlantState();
}

class _ReactivePlantState extends State<ReactivePlant>
    with TickerProviderStateMixin {
  late final AnimationController _sway;
  late final AnimationController _pose;
  late final Listenable _repaint;
  double _targetPosture = 0;

  @override
  void initState() {
    super.initState();
    _targetPosture = _postureFor(widget.humidityPercent);
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _pose = AnimationController.unbounded(
      vsync: this,
      value: _targetPosture,
    );
    _repaint = Listenable.merge([_sway, _pose]);
    if (!widget.reduceMotion) _sway.repeat();
  }

  double _postureFor(double humidity) {
    if (humidity < 40) {
      return -((40 - humidity) / 25).clamp(0.0, 1.0).toDouble();
    }
    if (humidity > 60) {
      return ((humidity - 60) / 30).clamp(0.0, 1.0).toDouble();
    }
    return 0;
  }

  void _animatePosture() {
    final next = _postureFor(widget.humidityPercent);
    if ((next - _targetPosture).abs() < 0.001) return;
    _targetPosture = next;
    if (widget.reduceMotion) {
      _pose.value = next;
    } else {
      _pose.animateWith(
        SpringSimulation(EnviroMotion.plantSpring, _pose.value, next, 0),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ReactivePlant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.humidityPercent != widget.humidityPercent) {
      _animatePosture();
    }
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _sway.stop();
      _sway.value = 0;
      _pose.stop();
      _pose.value = _targetPosture;
    } else if (!widget.reduceMotion && oldWidget.reduceMotion) {
      _sway.repeat();
    }
  }

  @override
  void dispose() {
    _sway.dispose();
    _pose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posture = widget.humidityPercent < 40
        ? 'dry, leaves gently drooping'
        : widget.humidityPercent > 60
        ? 'humid, leaves lifted'
        : 'comfortable, leaves resting';
    return Semantics(
      image: true,
      label: 'Animated room plant, humidity ${widget.humidityPercent.round()} percent, $posture',
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PlantPainter(
            humidity: widget.humidityPercent,
            pose: _pose,
            sway: _sway,
            repaint: _repaint,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter({
    required this.humidity,
    required this.pose,
    required this.sway,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final double humidity;
  final Animation<double> pose;
  final Animation<double> sway;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final posture = pose.value.clamp(-1.0, 1.0).toDouble();
    final swayAngle = math.sin(sway.value * math.pi * 2) * 0.018;
    final healthy = humidity >= 35 && humidity <= 65;
    final leafBase = healthy
        ? const Color(0xFF4E9C79)
        : Color.lerp(const Color(0xFF527C69), EnviroPalette.textMuted,
        ((humidity - 50).abs() / 60).clamp(0.0, 0.20).toDouble())!;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.84);
    canvas.rotate(swayAngle);
    canvas.translate(-w * 0.5, -h * 0.84);

    final stem = Paint()
      ..color = const Color(0xFF477E64).withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, w * 0.014).toDouble()
      ..strokeCap = StrokeCap.round;
    final stemPath = Path()
      ..moveTo(w * 0.50, h * 0.82)
      ..cubicTo(w * 0.48, h * 0.62, w * 0.52, h * 0.38, w * 0.50, h * 0.18);
    canvas.drawPath(stemPath, stem);

    final branches =
    <({Offset origin, double angle, double length, double phase})>[
      (origin: Offset(w * 0.49, h * 0.67), angle: -2.45, length: w * 0.22, phase: 0.1),
      (origin: Offset(w * 0.51, h * 0.61), angle: -0.70, length: w * 0.24, phase: 0.7),
      (origin: Offset(w * 0.49, h * 0.53), angle: -2.50, length: w * 0.26, phase: 1.3),
      (origin: Offset(w * 0.51, h * 0.45), angle: -0.58, length: w * 0.24, phase: 2.1),
      (origin: Offset(w * 0.49, h * 0.37), angle: -2.30, length: w * 0.21, phase: 2.7),
      (origin: Offset(w * 0.51, h * 0.30), angle: -0.82, length: w * 0.19, phase: 3.3),
    ];

    for (var i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final leftSide = i.isEven && i < 6;
      final droop = posture < 0 ? posture.abs() * (leftSide ? -0.35 : 0.35) : 0.0;
      final lift = posture > 0 ? posture * (leftSide ? 0.26 : -0.26) : 0.0;
      final idle = math.sin(sway.value * math.pi * 2 + branch.phase) * 0.025;
      final angle = branch.angle + droop + lift + idle;
      _drawLeaf(canvas, branch.origin, angle, branch.length, leafBase, i);
    }

    _drawPot(canvas, w, h);
    canvas.restore();
  }

  void _drawLeaf(
      Canvas canvas, Offset origin, double angle, double length, Color color, int index) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final veinColor = const Color(0xFFB8D8BE).withValues(alpha: 0.30);
    final leafPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color.withValues(alpha: 0.76), Color.lerp(color, EnviroPalette.teal, 0.25)!],
      ).createShader(Rect.fromLTWH(0, -length * 0.27, length, length * 0.54));
    final leaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(length * 0.22, -length * 0.33, length * 0.78, -length * 0.34, length, 0)
      ..cubicTo(length * 0.76, length * 0.30, length * 0.27, length * 0.24, 0, 0)
      ..close();
    canvas.drawPath(leaf, leafPaint);

    final vein = Paint()
      ..color = veinColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final veinPath = Path()
      ..moveTo(2, 0)
      ..quadraticBezierTo(length * 0.45, -length * 0.015, length * 0.92, 0);
    canvas.drawPath(veinPath, vein);
    canvas.restore();
  }

  void _drawPot(Canvas canvas, double w, double h) {
    final pot = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.32, h * 0.82, w * 0.68, h * 0.97),
      Radius.circular(w * 0.045),
    );
    final potPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8C6B4B), Color(0xFF5B4736)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(pot.outerRect);
    canvas.drawRRect(pot, potPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.29, h * 0.80, w * 0.71, h * 0.845),
        Radius.circular(w * 0.022),
      ),
      Paint()..color = const Color(0xFFAA8660),
    );
    canvas.drawLine(
      Offset(w * 0.37, h * 0.88),
      Offset(w * 0.63, h * 0.88),
      Paint()
        ..color = EnviroPalette.brass.withValues(alpha: 0.36)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.humidity != humidity ||
          oldDelegate.pose != pose ||
          oldDelegate.sway != sway;
}
