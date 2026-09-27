import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'enviro_motion.dart';

/// Small entrance reveal. The child is built once and only its transform and
/// opacity animate; use RepaintBoundary around expensive animated artwork.
class SpringReveal extends StatefulWidget {
  const SpringReveal({
    required this.child,
    this.delay = Duration.zero,
    this.reduceMotion = false,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final bool reduceMotion;

  @override
  State<SpringReveal> createState() => _SpringRevealState();
}

class _SpringRevealState extends State<SpringReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 0);
    _start();
  }

  void _start() {
    _delayTimer?.cancel();
    if (widget.reduceMotion) {
      _controller.stop();
      _controller.value = 1;
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (!mounted) return;
      _controller.animateWith(
        SpringSimulation(EnviroMotion.elementSpring, 0, 1, 0),
      );
    });
  }

  @override
  void didUpdateWidget(covariant SpringReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion ||
        oldWidget.delay != widget.delay) {
      _start();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = _controller.value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 18),
            child: Transform.scale(
              scale: 0.985 + progress * 0.015,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Scrubs a reveal directly from a shared scroll progress value.
///
/// `start` and `end` are normalized progress values (normally 0–1), allowing
/// several elements to enter in sequence without independent timers.
class ScrollReveal extends StatelessWidget {
  const ScrollReveal({
    required this.progress,
    required this.child,
    this.start = 0,
    this.end = 1,
    this.enterOffset = const Offset(0, 28),
    this.beginScale = 0.97,
    this.reduceMotion = false,
    super.key,
  }) : assert(end > start),
        assert(beginScale > 0 && beginScale <= 1);

  final ValueListenable<double> progress;
  final Widget child;
  final double start;
  final double end;
  final Offset enterOffset;
  final double beginScale;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      child: child,
      builder: (context, value, child) {
        final raw = ((value - start) / (end - start))
            .clamp(0.0, 1.0)
            .toDouble();
        final eased = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(
              enterOffset.dx * (1 - eased),
              enterOffset.dy * (1 - eased),
            ),
            child: Transform.scale(
              scale: beginScale + (1 - beginScale) * eased,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Moves a visual layer at a fraction of the scroll distance to create depth.
class ScrollParallax extends StatelessWidget {
  const ScrollParallax({
    required this.progress,
    required this.child,
    this.distance = 48,
    this.start = 0,
    this.end = 1,
    this.axis = Axis.vertical,
    this.reduceMotion = false,
    super.key,
  }) : assert(end > start);

  final ValueListenable<double> progress;
  final Widget child;
  final double distance;
  final double start;
  final double end;
  final Axis axis;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion || distance == 0) return child;
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      child: child,
      builder: (context, value, child) {
        final fraction = ((value - start) / (end - start))
            .clamp(0.0, 1.0)
            .toDouble();
        final offset = distance * fraction;
        return Transform.translate(
          offset: axis == Axis.vertical ? Offset(0, -offset) : Offset(-offset, 0),
          child: child,
        );
      },
    );
  }
}

/// Tactile scale response for buttons. Swiping between pages should remain
/// silent; use this only on explicit tap targets.
class SpringPressable extends StatefulWidget {
  const SpringPressable({
    required this.onPressed,
    required this.child,
    this.reduceMotion = false,
    this.semanticsLabel,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;
  final bool reduceMotion;
  final String? semanticsLabel;

  @override
  State<SpringPressable> createState() => _SpringPressableState();
}

class _SpringPressableState extends State<SpringPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  void _press() {
    if (widget.reduceMotion) return;
    _scale.animateTo(
      0.96,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
  }

  void _release() {
    if (widget.reduceMotion) {
      _scale.stop();
      _scale.value = 1;
    } else {
      _scale.animateWith(
        SpringSimulation(EnviroMotion.elementSpring, _scale.value, 1, 0),
      );
    }
  }

  @override
  void didUpdateWidget(covariant SpringPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) _release();
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(),
      onTapCancel: _release,
      onTapUp: (_) {
        _release();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _scale,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: widget.reduceMotion ? 1 : _scale.value,
          child: child,
        ),
      ),
    );
    if (widget.semanticsLabel == null) return child;
    return Semantics(button: true, label: widget.semanticsLabel, child: child);
  }
}

/// Calm connected-state pulse; the dot remains meaningful with animations off.
class LivePulse extends StatefulWidget {
  const LivePulse({
    this.color = EnviroPalette.teal,
    this.label = 'LIVE',
    this.reduceMotion = false,
    super.key,
  });

  final Color color;
  final String label;
  final bool reduceMotion;

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: EnviroMotion.livePulseDuration,
    );
    if (!widget.reduceMotion) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LivePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!widget.reduceMotion && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final breathe = widget.reduceMotion ? 0.0 : _pulse.value;
        return Semantics(
          label: widget.label,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.18 + breathe * 0.38),
                      blurRadius: 5 + breathe * 7,
                      spreadRadius: breathe * 1.2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: EnviroPalette.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Spring-settles a number when a new sample arrives without rebuilding its
/// containing card. Format the interpolated value in the caller.
class SpringNumber extends StatefulWidget {
  const SpringNumber({
    required this.value,
    required this.format,
    this.reduceMotion = false,
    this.textStyle,
    super.key,
  });

  final double value;
  final String Function(double value) format;
  final bool reduceMotion;
  final TextStyle? textStyle;

  @override
  State<SpringNumber> createState() => _SpringNumberState();
}

class _SpringNumberState extends State<SpringNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _value;

  @override
  void initState() {
    super.initState();
    _value = AnimationController.unbounded(vsync: this, value: widget.value);
  }

  @override
  void didUpdateWidget(covariant SpringNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion) {
      _value.stop();
      _value.value = widget.value;
      return;
    }
    if (oldWidget.value != widget.value) {
      _value.animateWith(
        SpringSimulation(
          EnviroMotion.valueSpring,
          _value.value,
          widget.value,
          0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _value,
      builder: (context, _) => Text(
        widget.format(_value.value),
        style: widget.textStyle,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
      ),
    );
  }
}
