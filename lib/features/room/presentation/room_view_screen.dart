import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../app/motion/enviro_motion.dart';
import '../../../app/motion/motion_widgets.dart';
import '../../../core/preferences/app_preferences.dart';
import 'widgets/reactive_plant.dart';
import 'widgets/room_scene.dart';

/// A scroll-led environment page. Readings are supplied by the caller so this
/// presentation stays independent of BLE and storage.
class RoomViewScreen extends StatefulWidget {
  const RoomViewScreen({
    required this.temperatureC,
    required this.humidityPercent,
    required this.comfortScore,
    this.roomName = 'Bedroom',
    this.deviceName = 'EnviroSense sensor',
    this.isLive = false,
    this.thresholdAlert = false,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.reducedMotion = false,
    super.key,
  });

  final double temperatureC;
  final double humidityPercent;
  final double comfortScore;
  final String roomName;
  final String deviceName;
  final bool isLive;
  final bool thresholdAlert;
  final TemperatureUnit temperatureUnit;
  final bool reducedMotion;

  @override
  State<RoomViewScreen> createState() => _RoomViewScreenState();
}

class _RoomViewScreenState extends State<RoomViewScreen> {
  static const double _storyDistance = 620;
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateProgress);
  }

  void _updateProgress() {
    if (!_scroll.hasClients) return;
    final value = (_scroll.offset / _storyDistance).clamp(0.0, 1.0).toDouble();
    if ((value - _progress.value).abs() > 0.001) _progress.value = value;
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_updateProgress)
      ..dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        widget.reducedMotion;
    final height = MediaQuery.sizeOf(context).height;
    final maxHero = math.min(math.max(height * 0.60, 350.0), 470.0).toDouble();
    final minHero = math.min(188.0, maxHero * 0.54).toDouble();

    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 19, 20, 15),
                child: _RoomHeading(
                  name: widget.roomName,
                  live: widget.isLive,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _RoomHeroDelegate(
                minExtent: minHero,
                maxExtent: maxHero,
                roomName: widget.roomName,
                deviceName: widget.deviceName,
                temperature: widget.temperatureC,
                humidity: widget.humidityPercent,
                comfort: widget.comfortScore,
                live: widget.isLive,
                alert: widget.thresholdAlert,
                reduceMotion: reduceMotion,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 118),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ScrollReveal(
                    progress: _progress,
                    start: 0.10,
                    end: 0.36,
                    reduceMotion: reduceMotion,
                    child: const _SectionHeading(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ScrollReveal(
                          progress: _progress,
                          start: 0.14,
                          end: 0.46,
                          enterOffset: const Offset(-18, 24),
                          beginScale: 0.95,
                          reduceMotion: reduceMotion,
                          child: _MetricCard(
                            label: 'TEMPERATURE',
                            value: widget.temperatureUnit.fromCelsius(
                              widget.temperatureC,
                            ),
                            unit: widget.temperatureUnit.symbol,
                            icon: Icons.thermostat_rounded,
                            accent: widget.temperatureC > 27
                                ? EnviroPalette.amberWarm
                                : widget.temperatureC < 18
                                ? EnviroPalette.violetCold
                                : EnviroPalette.teal,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ScrollReveal(
                          progress: _progress,
                          start: 0.22,
                          end: 0.54,
                          enterOffset: const Offset(18, 24),
                          beginScale: 0.95,
                          reduceMotion: reduceMotion,
                          child: _MetricCard(
                            label: 'HUMIDITY',
                            value: widget.humidityPercent,
                            unit: '%',
                            icon: Icons.water_drop_rounded,
                            accent: EnviroPalette.teal,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ScrollParallax(
                    progress: _progress,
                    distance: 18,
                    start: 0.12,
                    end: 0.80,
                    reduceMotion: reduceMotion,
                    child: ScrollReveal(
                      progress: _progress,
                      start: 0.34,
                      end: 0.68,
                      reduceMotion: reduceMotion,
                      child: _ClimateCard(
                        temperature: widget.temperatureC,
                        humidity: widget.humidityPercent,
                        comfort: widget.comfortScore,
                        alert: widget.thresholdAlert,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ScrollReveal(
                    progress: _progress,
                    start: 0.55,
                    end: 0.88,
                    reduceMotion: reduceMotion,
                    child: _ConnectionCard(
                      name: widget.deviceName,
                      live: widget.isLive,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomHeading extends StatelessWidget {
  const _RoomHeading({
    required this.name,
    required this.live,
    required this.reduceMotion,
  });

  final String name;
  final bool live;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR SPACE',
              style: TextStyle(
                color: EnviroPalette.brass,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EnviroPalette.textPrimary,
                fontSize: 25,
                height: 1.05,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      live ? LivePulse(reduceMotion: reduceMotion) : const _DemoStatus(),
    ],
  );
}

class _RoomHeroDelegate extends SliverPersistentHeaderDelegate {
  const _RoomHeroDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.roomName,
    required this.deviceName,
    required this.temperature,
    required this.humidity,
    required this.comfort,
    required this.live,
    required this.alert,
    required this.reduceMotion,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;
  final String roomName;
  final String deviceName;
  final double temperature;
  final double humidity;
  final double comfort;
  final bool live;
  final bool alert;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapse = (shrinkOffset / (maxExtent - minExtent))
        .clamp(0.0, 1.0)
        .toDouble();
    final accent = alert ? EnviroPalette.coral : enviroMoodColor(temperature);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RoomScene(
              temperatureC: temperature,
              humidityPercent: humidity,
              thresholdAlert: alert,
              reduceMotion: reduceMotion,
              scrollProgress: collapse,
            ),
            Positioned(
              left: 13,
              bottom: 0,
              width: math.min(190.0, (maxExtent - shrinkOffset) * 0.43).toDouble(),
              height: math.min(270.0, (maxExtent - shrinkOffset) * 0.66).toDouble(),
              child: Transform.translate(
                offset: Offset(0, collapse * 16),
                child: Transform.scale(
                  scale: 1 - collapse * 0.12,
                  alignment: Alignment.bottomCenter,
                  child: ReactivePlant(
                    humidityPercent: humidity,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 15,
              top: 14 - collapse * 6,
              child: _GlassTag(icon: Icons.home_rounded, label: roomName.toUpperCase()),
            ),
            Positioned(
              right: 12,
              top: 12 - collapse * 5,
              child: Transform.scale(
                scale: 1 - collapse * 0.1,
                alignment: Alignment.topRight,
                child: _ComfortGauge(
                  score: comfort,
                  color: accent,
                  reduceMotion: reduceMotion,
                ),
              ),
            ),
            Positioned(
              right: 13,
              bottom: 13,
              child: Opacity(
                opacity: 1 - collapse * 0.25,
                child: _GlassTag(
                  icon: live ? Icons.sensors_rounded : Icons.science_outlined,
                  label: live ? deviceName : 'DEMO SENSOR',
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RoomHeroDelegate old) =>
      old.minExtent != minExtent ||
          old.maxExtent != maxExtent ||
          old.roomName != roomName ||
          old.deviceName != deviceName ||
          old.temperature != temperature ||
          old.humidity != humidity ||
          old.comfort != comfort ||
          old.live != live ||
          old.alert != alert ||
          old.reduceMotion != reduceMotion;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROOM SIGNAL / 01',
              style: TextStyle(
                color: EnviroPalette.brass,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Right now',
              style: TextStyle(
                color: EnviroPalette.textPrimary,
                fontSize: 23,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.45,
              ),
            ),
          ],
        ),
      ),
      Icon(Icons.waves_rounded, color: EnviroPalette.teal, size: 19),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.reduceMotion,
  });

  final String label;
  final double value;
  final String unit;
  final IconData icon;
  final Color accent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, ${value.toStringAsFixed(1)} $unit',
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 15),
      decoration: BoxDecoration(
        color: EnviroPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EnviroPalette.hairline),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.045),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 15),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EnviroPalette.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: SpringNumber(
                  value: value,
                  reduceMotion: reduceMotion,
                  format: (number) => number.toStringAsFixed(1),
                  textStyle: const TextStyle(
                    color: EnviroPalette.textPrimary,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ClimateCard extends StatelessWidget {
  const _ClimateCard({
    required this.temperature,
    required this.humidity,
    required this.comfort,
    required this.alert,
  });

  final double temperature;
  final double humidity;
  final double comfort;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final accent = alert ? EnviroPalette.coral : enviroMoodColor(temperature);
    final title = alert
        ? 'Attention needed'
        : temperature > 27
        ? 'A little warm'
        : temperature < 18
        ? 'Cool conditions'
        : humidity < 30
        ? 'The air feels dry'
        : humidity > 65
        ? 'Humidity is elevated'
        : 'A balanced room';
    final detail = alert
        ? 'A room comfort threshold has been crossed.'
        : temperature > 27
        ? 'Temperature is above the comfort range. Consider improving airflow.'
        : temperature < 18
        ? 'Temperature is below the comfort range. Check the heating.'
        : humidity < 30
        ? 'Humidity is low. A little more moisture may improve comfort.'
        : humidity > 65
        ? 'Humidity is high. Ventilation may help the room feel fresher.'
        : 'Temperature and humidity are sitting in a comfortable range.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EnviroPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alert ? Icons.priority_high_rounded : Icons.air_rounded,
              color: accent, size: 22),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: EnviroPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 5),
                Text(detail, style: const TextStyle(
                  color: EnviroPalette.textMuted,
                  fontSize: 11,
                  height: 1.45,
                )),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('COMFORT', style: TextStyle(
                      color: EnviroPalette.textFaint,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    )),
                    const Spacer(),
                    Text('${comfort.clamp(0, 100).round()} / 100', style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (comfort / 100).clamp(0.0, 1.0).toDouble()),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.name,
    required this.live,
    required this.reduceMotion,
  });

  final String name;
  final bool live;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final accent = live ? EnviroPalette.teal : EnviroPalette.brass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: EnviroPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EnviroPalette.hairline),
      ),
      child: Row(
        children: [
          Icon(live ? Icons.bluetooth_connected_rounded : Icons.science_outlined,
              color: accent, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(live ? name : 'Sample readings', maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EnviroPalette.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Text(live ? 'Receiving sensor updates' : 'Not connected to a sensor',
                    style: const TextStyle(
                      color: EnviroPalette.textMuted,
                      fontSize: 9,
                    )),
              ],
            ),
          ),
          LivePulse(color: accent, label: live ? 'LIVE' : 'DEMO',
              reduceMotion: reduceMotion),
        ],
      ),
    );
  }
}

class _ComfortGauge extends StatelessWidget {
  const _ComfortGauge({
    required this.score,
    required this.color,
    required this.reduceMotion,
  });

  final double score;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: color),
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 700),
    builder: (context, animatedColor, _) => TweenAnimationBuilder<double>(
      tween: Tween(end: (score / 100).clamp(0.0, 1.0).toDouble()),
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.13),
                valueColor: AlwaysStoppedAnimation<Color>(animatedColor ?? color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${score.round()}', style: const TextStyle(
                  color: EnviroPalette.textPrimary,
                  fontSize: 19,
                  height: 1,
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 3),
                const Text('COMFORT', style: TextStyle(
                  color: EnviroPalette.textMuted,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                )),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.icon, required this.label, this.compact = false});

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EnviroPalette.surfaceGlass,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: EnviroPalette.hairline),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 7 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: EnviroPalette.brass, size: compact ? 13 : 15),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: EnviroPalette.textPrimary,
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DemoStatus extends StatelessWidget {
  const _DemoStatus();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Demo readings, not connected',
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.science_outlined, color: EnviroPalette.brass, size: 15),
        SizedBox(width: 6),
        Text('DEMO', style: TextStyle(
          color: EnviroPalette.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        )),
      ],
    ),
  );
}
