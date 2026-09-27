import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/providers/sensor_providers.dart';
import '../../../core/repositories/sensor_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(sensorSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.blur_on_rounded, color: AppTheme.teal),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENVIROSENSE',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Environment dashboard',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Scan for devices',
            onPressed: () => context.push('/scan'),
            icon: const Icon(Icons.bluetooth_searching_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: snapshotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.brass,
                  size: 36,
                ),
                const SizedBox(height: 12),
                const Text('Could not load sensor data'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(sensorSnapshotProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (snapshot) => _DashboardContent(snapshot: snapshot),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.snapshot});

  final SensorSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final readingsById = {
      for (final reading in snapshot.readings) reading.sensorId: reading,
    };
    final sensors = snapshot.sensors.where((sensor) => sensor.enabled).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Overview',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'PREVIEW',
                style: TextStyle(
                  color: AppTheme.brass,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Row(
            children: [
              Icon(Icons.sensors_rounded, color: AppTheme.teal),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No device connected',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sample values below are for layout preview',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'SENSORS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (sensors.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No enabled sensors',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.22,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final sensor in sensors)
                _MetricCard(
                  sensor: sensor,
                  reading: readingsById[sensor.id],
                ),
            ],
          ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => context.push('/scan'),
          icon: const Icon(Icons.bluetooth_searching_rounded),
          label: const Text('Scan for devices'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.brass,
            side: const BorderSide(color: AppTheme.brass),
            padding: const EdgeInsets.symmetric(vertical: 16),
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
  });

  final SensorDescriptor sensor;
  final SensorReading? reading;

  String get _displayValue {
    if (reading == null) return '—';

    switch (sensor.valueKind) {
      case SensorValueKind.number:
        final value = reading!.value;
        if (value is num) {
          return value.toStringAsFixed(sensor.precision);
        }
        return '—';

      case SensorValueKind.boolean:
        return reading!.value == true ? 'On' : 'Off';

      case SensorValueKind.text:
      case SensorValueKind.event:
        return reading!.value?.toString() ?? '—';
    }
  }

  String get _statusLabel {
    if (reading == null) return 'NO READING';

    switch (reading!.quality) {
      case SensorQuality.ok:
        return 'SAMPLE DATA';
      case SensorQuality.warmingUp:
        return 'WARMING UP';
      case SensorQuality.stale:
        return 'STALE';
      case SensorQuality.invalid:
        return 'INVALID';
      case SensorQuality.fault:
        return 'SENSOR FAULT';
    }
  }

  IconData get _icon {
    switch (sensor.type) {
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: AppTheme.teal, size: 20),
          const Spacer(),
          Text(
            sensor.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  _displayValue,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                sensor.unit,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _statusLabel,
            style: const TextStyle(
              color: AppTheme.brass,
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
