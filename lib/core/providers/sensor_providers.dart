import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_manager.dart';
import '../models/sensor_data.dart';
import '../repositories/sensor_repository.dart';
import 'local_demo_history_provider.dart';

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return const DemoSensorRepository();
});

final sensorSnapshotProvider =
FutureProvider<SensorSnapshot>((ref) async {
  final bleSession = ref.watch(bleSessionProvider);

  final snapshot = bleSession.telemetry == null
      ? await ref
      .watch(sensorRepositoryProvider)
      .loadSnapshot()
      : _snapshotFromBleTelemetry(
    bleSession.telemetry!,
  );

  await ref
      .read(localDemoHistoryProvider.notifier)
      .recordSnapshot(snapshot);

  return snapshot;
});

SensorSnapshot _snapshotFromBleTelemetry(
    TelemetryReading telemetry,
    ) {
  final receivedAt = telemetry.receivedAt;

  const sensors = [
    SensorDescriptor(
      id: 'environment.temperature.1',
      type: 'temperature',
      label: 'DHT22 Temperature',
      unit: '°C',
      valueKind: SensorValueKind.number,
      precision: 1,
    ),
    SensorDescriptor(
      id: 'environment.humidity.1',
      type: 'humidity',
      label: 'DHT22 Humidity',
      unit: '%',
      valueKind: SensorValueKind.number,
      precision: 1,
    ),
  ];

  return SensorSnapshot(
    sensors: sensors,
    readings: [
      SensorReading(
        sensorId: 'environment.temperature.1',
        value: telemetry.temperatureC,
        quality: SensorQuality.ok,
        receivedAt: receivedAt,
      ),
      SensorReading(
        sensorId: 'environment.humidity.1',
        value: telemetry.humidityPercent,
        quality: SensorQuality.ok,
        receivedAt: receivedAt,
      ),
    ],
  );
}
