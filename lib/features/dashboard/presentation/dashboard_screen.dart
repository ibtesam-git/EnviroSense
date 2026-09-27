import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion/enviro_motion.dart';
import '../../../app/motion/motion_widgets.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/providers/sensor_providers.dart';
import '../../../core/repositories/sensor_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(sensorSnapshotProvider);
    final preferences = ref.watch(appPreferencesProvider);
    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        preferences.reducedMotion;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 72,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EnviroPalette.hairline),
              ),
              child: const Icon(
                Icons.blur_on_rounded,
                color: AppTheme.teal,
                size: 21,
              ),
            ),
          ),
        ),
        titleSpacing: 10,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ENVIROSENSE',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'ENVIRONMENT INTELLIGENCE',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9,
                letterSpacing: 1.05,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Scan for devices',
              onPressed: () => context.push('/scan'),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceRaised,
                foregroundColor: AppTheme.teal,
                fixedSize: const Size(42, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: EnviroPalette.hairline),
                ),
              ),
              icon: const Icon(Icons.bluetooth_searching_rounded, size: 20),
            ),
          ),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const _DashboardLoading(),
        error: (error, stackTrace) => _DashboardError(
          onRetry: () => ref.invalidate(sensorSnapshotProvider),
        ),
        data: (snapshot) => _DashboardContent(
          snapshot: snapshot,
          reduceMotion: reduceMotion,
          temperatureUnit: preferences.temperatureUnit,
          onScan: () => context.push('/scan'),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.snapshot,
    required this.reduceMotion,
    required this.temperatureUnit,
    required this.onScan,
  });

  final SensorSnapshot snapshot;
  final bool reduceMotion;
  final TemperatureUnit temperatureUnit;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final readingsById = <String, SensorReading>{
      for (final reading in snapshot.readings) reading.sensorId: reading,
    };
    final sensors = snapshot.sensors.where((sensor) => sensor.enabled).toList();
    SensorDescriptor? temperatureSensor;
    for (final sensor in sensors) {
      if (sensor.type.toLowerCase() == 'temperature') {
        temperatureSensor = sensor;
        break;
      }
    }

    final temperatureReading = temperatureSensor == null
        ? null
        : readingsById[temperatureSensor.id];
    final reportingCount = sensors
        .where((sensor) => readingsById.containsKey(sensor.id))
        .length;
    final attentionCount = sensors.length - reportingCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 720 ? 28.0 : 20.0;
        final columns = constraints.maxWidth >= 760 ? 4 : 2;

        return ListView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 124),
          children: [
            SpringReveal(
              reduceMotion: reduceMotion,
              child: _SectionIntro(
                sensorCount: sensors.length,
                reduceMotion: reduceMotion,
              ),
            ),
            const SizedBox(height: 18),
            SpringReveal(
              delay: const Duration(milliseconds: 70),
              reduceMotion: reduceMotion,
              child: _AtmosphereHero(
                sensor: temperatureSensor,
                reading: temperatureReading,
                reduceMotion: reduceMotion,
                temperatureUnit: temperatureUnit,
                onScan: onScan,
              ),
            ),
            const SizedBox(height: 18),
            SpringReveal(
              delay: const Duration(milliseconds: 130),
              reduceMotion: reduceMotion,
              child: _NetworkSummary(
                sensorCount: sensors.length,
                reportingCount: reportingCount,
                attentionCount: attentionCount,
              ),
            ),
            const SizedBox(height: 26),
            _SectionLabel(
              title: 'Sensor readings',
              detail: '${sensors.length} ${sensors.length == 1 ? 'channel' : 'channels'}',
            ),
            const SizedBox(height: 12),
            if (sensors.isEmpty)
              _EmptySensors(onScan: onScan)
            else
              GridView.builder(
                itemCount: sensors.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth >= 760 ? 1.18 : 1.08,
                ),
                itemBuilder: (context, index) {
                  final sensor = sensors[index];
                  return SpringReveal(
                    key: ValueKey<String>('reveal-${sensor.id}'),
                    delay: Duration(milliseconds: 170 + index * 45),
                    reduceMotion: reduceMotion,
                    child: _MetricCard(
                      key: ValueKey<String>(sensor.id),
                      sensor: sensor,
                      reading: readingsById[sensor.id],
                      reduceMotion: reduceMotion,
                      temperatureUnit: temperatureUnit,
                    ),
                  );
                },
              ),
            const SizedBox(height: 18),
            _ConnectionCard(onScan: onScan),
            const SizedBox(height: 22),
            const Center(
              child: Text(
                'ENVIRONMENTAL CLARITY, AT A GLANCE',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.sensorCount,
    required this.reduceMotion,
  });

  final int sensorCount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR ENVIRONMENT',
                style: TextStyle(
                  color: AppTheme.brass,
                  fontSize: 10,
                  letterSpacing: 1.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'At a glance',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 29,
                  height: 1,
                  letterSpacing: -0.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'A considered view of the air around you.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: EnviroPalette.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LivePulse(
                color: AppTheme.brass,
                label: 'PREVIEW',
                reduceMotion: reduceMotion,
              ),
              const SizedBox(width: 7),
              Text(
                '$sensorCount',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AtmosphereHero extends StatelessWidget {
  const _AtmosphereHero({
    required this.sensor,
    required this.reading,
    required this.reduceMotion,
    required this.temperatureUnit,
    required this.onScan,
  });

  final SensorDescriptor? sensor;
  final SensorReading? reading;
  final bool reduceMotion;
  final TemperatureUnit temperatureUnit;
  final VoidCallback onScan;

  double? get _temperature {
    final value = reading?.value;
    if (value is num) return value.toDouble();
    return null;
  }

  String get _temperatureStatus {
    if (reading == null) return 'Awaiting a temperature sample';
    if (reading!.quality != SensorQuality.ok) {
      return _qualityLabel(reading!.quality);
    }
    final value = _temperature;
    if (value == null) return 'Temperature data unavailable';
    if (value < 18) return 'Cooler than the comfort range';
    if (value > 27) return 'Warmer than the comfort range';
    return 'Within the comfort range';
  }

  @override
  Widget build(BuildContext context) {
    final rawTemperature = _temperature;
    final temperature = rawTemperature == null
        ? null
        : temperatureUnit.fromCelsius(rawTemperature);
    final accent = rawTemperature == null
        ? AppTheme.teal
        : enviroMoodColor(rawTemperature);
    final hasTemperature = sensor != null;

    return Container(
      height: 224,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202D29), Color(0xFF121B19), Color(0xFF111817)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -72,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 65,
                    spreadRadius: 22,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 29,
            child: _AtmosphereOrb(accent: accent),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 19, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.blur_circular_rounded, size: 13, color: accent),
                    const SizedBox(width: 7),
                    const Text(
                      'ROOM CONDITIONS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                        letterSpacing: 1.55,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  hasTemperature ? sensor!.label.toUpperCase() : 'TEMPERATURE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: reading?.value is num
                          ? SpringNumber(
                        value: temperature!,
                        format: (value) => value.toStringAsFixed(
                          sensor?.precision ?? 1,
                        ),
                        reduceMotion: reduceMotion,
                        textStyle: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 52,
                          height: 1,
                          letterSpacing: -2,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                          : const Text(
                        '—',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 52,
                          height: 1,
                          letterSpacing: -2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        temperatureUnit.symbol,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: reading?.quality == SensorQuality.ok
                            ? AppTheme.teal
                            : AppTheme.brass,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        _temperatureStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _QuietScanAction(onScan: onScan),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphereOrb extends StatelessWidget {
  const _AtmosphereOrb({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.22)),
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.12), Colors.transparent],
              ),
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.08),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 23,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.device_thermostat_rounded,
              color: accent,
              size: 27,
            ),
          ),
          Positioned(
            top: 18,
            right: 24,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 8),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 21,
            left: 20,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietScanAction extends StatelessWidget {
  const _QuietScanAction({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onScan,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.brass,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        backgroundColor: AppTheme.brass.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Icons.bluetooth_searching_rounded, size: 15),
      label: const Text('Find a sensor'),
    );
  }
}

class _NetworkSummary extends StatelessWidget {
  const _NetworkSummary({
    required this.sensorCount,
    required this.reportingCount,
    required this.attentionCount,
  });

  final int sensorCount;
  final int reportingCount;
  final int attentionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: EnviroPalette.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryValue(
              label: 'CHANNELS',
              value: '$sensorCount',
              color: AppTheme.brass,
            ),
          ),
          _SummaryDivider(),
          Expanded(
            child: _SummaryValue(
              label: 'REPORTING',
              value: '$reportingCount',
              color: AppTheme.teal,
            ),
          ),
          _SummaryDivider(),
          Expanded(
            child: _SummaryValue(
              label: 'NO READING',
              value: '$attentionCount',
              color: attentionCount == 0 ? AppTheme.teal : AppTheme.brass,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            letterSpacing: 0.85,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: 0.08),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.25,
            ),
          ),
        ),
        Text(
          detail.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.sensor,
    required this.reading,
    required this.reduceMotion,
    required this.temperatureUnit,
    super.key,
  });

  final SensorDescriptor sensor;
  final SensorReading? reading;
  final bool reduceMotion;
  final TemperatureUnit temperatureUnit;

  String get _displayValue {
    if (reading == null) return '—';

    switch (sensor.valueKind) {
      case SensorValueKind.number:
        final value = reading!.value;
        if (value is num) {
          final displayValue = sensor.type.toLowerCase() == 'temperature'
              ? temperatureUnit.fromCelsius(value.toDouble())
              : value.toDouble();
          return displayValue.toStringAsFixed(sensor.precision);
        }
        return '—';
      case SensorValueKind.boolean:
        return reading!.value == true ? 'On' : 'Off';
      case SensorValueKind.text:
      case SensorValueKind.event:
        return reading!.value?.toString() ?? '—';
    }
  }

  String get _statusLabel => reading == null
      ? 'NO READING'
      : _qualityLabel(reading!.quality).toUpperCase();

  String get _displayUnit => sensor.type.toLowerCase() == 'temperature'
      ? temperatureUnit.symbol
      : sensor.unit;

  Color get _accent {
    switch (sensor.type.toLowerCase()) {
      case 'temperature':
        final value = reading?.value;
        return enviroMoodColor(value is num ? value.toDouble() : 22);
      case 'humidity':
        return AppTheme.teal;
      case 'pressure':
        return AppTheme.brass;
      case 'light':
        return EnviroPalette.amberWarm;
      default:
        return AppTheme.teal;
    }
  }

  IconData get _icon {
    switch (sensor.type.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat_rounded;
      case 'humidity':
        return Icons.water_drop_rounded;
      case 'pressure':
        return Icons.speed_rounded;
      case 'light':
        return Icons.light_mode_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawNumericValue = reading?.value;
    final numericValue = rawNumericValue is num
        ? sensor.type.toLowerCase() == 'temperature'
        ? temperatureUnit.fromCelsius(rawNumericValue.toDouble())
        : rawNumericValue.toDouble()
        : rawNumericValue;
    final canAnimateNumber = sensor.valueKind == SensorValueKind.number &&
        numericValue is num;
    final statusColor = reading == null
        ? AppTheme.textMuted
        : _qualityColor(reading!.quality);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.065)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.035),
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
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, color: _accent, size: 17),
              ),
              const Spacer(),
              Icon(
                reading == null ? Icons.remove_rounded : Icons.circle,
                size: reading == null ? 16 : 6,
                color: statusColor,
              ),
            ],
          ),
          const Spacer(),
          Text(
            sensor.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: canAnimateNumber
                    ? SpringNumber(
                  value: numericValue.toDouble(),
                  format: (value) => value.toStringAsFixed(sensor.precision),
                  reduceMotion: reduceMotion,
                  textStyle: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 25,
                    height: 1.05,
                    letterSpacing: -0.65,
                    fontWeight: FontWeight.w700,
                  ),
                )
                    : Text(
                  _displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 25,
                    height: 1.05,
                    letterSpacing: -0.65,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _displayUnit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: statusColor,
              fontSize: 8,
              letterSpacing: 0.85,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: EnviroPalette.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: AppTheme.teal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bring your sensor online',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Preview readings are shown until a device connects.',
                  maxLines: 2,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Find a sensor',
            onPressed: onScan,
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.brass,
              backgroundColor: AppTheme.brass.withValues(alpha: 0.08),
              fixedSize: const Size(38, 38),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmptySensors extends StatelessWidget {
  const _EmptySensors({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EnviroPalette.hairline),
      ),
      child: Column(
        children: [
          const Icon(Icons.sensors_off_rounded, color: AppTheme.textMuted, size: 27),
          const SizedBox(height: 10),
          const Text(
            'No sensor channels yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Connect an EnviroSense device to see its readings here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 13),
          TextButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.bluetooth_searching_rounded, size: 16),
            label: const Text('Find a sensor'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.brass),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.teal,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Preparing your environment…',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EnviroPalette.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.brass.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sensors_off_rounded,
                  color: AppTheme.brass,
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Dashboard unavailable',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We couldn’t load the latest sensor snapshot. Try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brass,
                  foregroundColor: AppTheme.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _qualityLabel(SensorQuality quality) {
  switch (quality) {
    case SensorQuality.ok:
      return 'Reading received';
    case SensorQuality.warmingUp:
      return 'Warming up';
    case SensorQuality.stale:
      return 'Reading is stale';
    case SensorQuality.invalid:
      return 'Invalid reading';
    case SensorQuality.fault:
      return 'Sensor fault';
  }
}

Color _qualityColor(SensorQuality quality) {
  switch (quality) {
    case SensorQuality.ok:
      return AppTheme.teal;
    case SensorQuality.warmingUp:
      return AppTheme.brass;
    case SensorQuality.stale:
    case SensorQuality.invalid:
    case SensorQuality.fault:
      return EnviroPalette.coral;
  }
}
