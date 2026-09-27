import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion/enviro_motion.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/providers/sensor_providers.dart';
import '../../../core/repositories/sensor_repository.dart';
import 'room_view_screen.dart';

/// Connects Room View to the same snapshot used by Overview.
///
/// The current repository is still a demo source. Later, the repository can
/// be replaced with the ESP32 telemetry provider without changing this route.
class RoomViewRoute extends ConsumerWidget {
  const RoomViewRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final snapshotAsync = ref.watch(sensorSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const _RoomStateMessage(
        icon: Icons.blur_circular_rounded,
        title: 'Reading your room',
        detail: 'Preparing the latest environment snapshot…',
        showProgress: true,
      ),
      error: (error, stackTrace) => _RoomStateMessage(
        icon: Icons.sensors_off_rounded,
        title: 'Room view unavailable',
        detail: 'The sensor snapshot could not be loaded.',
        actionLabel: 'Try again',
        onAction: () {
          ref.invalidate(sensorSnapshotProvider);
        },
      ),
      data: (snapshot) {
        final temperature = _numericReading(
          snapshot,
          'temperature',
        );
        final humidity = _numericReading(
          snapshot,
          'humidity',
        );

        if (temperature == null || humidity == null) {
          return _RoomStateMessage(
            icon: Icons.sensors_off_rounded,
            title: 'Waiting for room readings',
            detail:
            'Room View needs valid temperature and humidity readings. Connect a device that provides both sensors.',
            actionLabel: 'Find a sensor',
            onAction: () {
              context.push('/scan');
            },
          );
        }

        final outsideComfortRange = temperature < 18 ||
            temperature > 27 ||
            humidity < 30 ||
            humidity > 65;

        return RoomViewScreen(
          temperatureC: temperature,
          humidityPercent: humidity,
          // This remains a demo value until the comfort-index formula is
          // defined or provided by the ESP32.
          comfortScore: 82,
          isLive: false,
          temperatureUnit: preferences.temperatureUnit,
          reducedMotion: preferences.reducedMotion,
          thresholdAlert:
          preferences.thresholdAlerts && outsideComfortRange,
        );
      },
    );
  }
}

double? _numericReading(
    SensorSnapshot snapshot,
    String type,
    ) {
  final descriptor = _firstEnabledSensorOfType(
    snapshot,
    type,
  );

  if (descriptor == null) {
    return null;
  }

  for (final reading in snapshot.readings) {
    if (reading.sensorId == descriptor.id &&
        reading.quality == SensorQuality.ok) {
      final value = reading.value;

      if (value is num) {
        return value.toDouble();
      }
    }
  }

  return null;
}

SensorDescriptor? _firstEnabledSensorOfType(
    SensorSnapshot snapshot,
    String type,
    ) {
  for (final sensor in snapshot.sensors) {
    if (sensor.enabled &&
        sensor.type.toLowerCase() == type) {
      return sensor;
    }
  }

  return null;
}

class _RoomStateMessage extends StatelessWidget {
  const _RoomStateMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.showProgress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool showProgress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: EnviroPalette.hairline,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.teal,
                    size: 23,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.teal,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: Icon(
                      actionLabel == 'Find a sensor'
                          ? Icons.bluetooth_searching_rounded
                          : Icons.refresh_rounded,
                      size: 17,
                    ),
                    label: Text(actionLabel!),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brass,
                      foregroundColor: AppTheme.background,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
