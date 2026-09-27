import '../models/sensor_data.dart';

class SensorSnapshot {
  const SensorSnapshot({
    required this.sensors,
    required this.readings,
  });

  final List<SensorDescriptor> sensors;
  final List<SensorReading> readings;
}

abstract interface class SensorRepository {
  Future<SensorSnapshot> loadSnapshot();
}

/// Temporary data source for building and testing the UI.
/// It will later be replaced by data from the ESP32.
class DemoSensorRepository implements SensorRepository {
  const DemoSensorRepository();

  @override
  Future<SensorSnapshot> loadSnapshot() async {
    final now = DateTime.now();

    const sensors = [
      SensorDescriptor(
        id: 'environment.temperature.1',
        type: 'temperature',
        label: 'Temperature',
        unit: '°C',
        valueKind: SensorValueKind.number,
        precision: 1,
      ),
      SensorDescriptor(
        id: 'environment.humidity.1',
        type: 'humidity',
        label: 'Humidity',
        unit: '%',
        valueKind: SensorValueKind.number,
        precision: 0,
      ),
      SensorDescriptor(
        id: 'environment.pressure.1',
        type: 'pressure',
        label: 'Pressure',
        unit: 'hPa',
        valueKind: SensorValueKind.number,
        precision: 0,
      ),
      SensorDescriptor(
        id: 'environment.light.1',
        type: 'light',
        label: 'Light',
        unit: 'lx',
        valueKind: SensorValueKind.number,
        precision: 0,
      ),
    ];

    final readings = [
      SensorReading(
        sensorId: 'environment.temperature.1',
        value: 23.8,
        quality: SensorQuality.ok,
        receivedAt: now,
      ),
      SensorReading(
        sensorId: 'environment.humidity.1',
        value: 47,
        quality: SensorQuality.ok,
        receivedAt: now,
      ),
      SensorReading(
        sensorId: 'environment.pressure.1',
        value: 1013,
        quality: SensorQuality.ok,
        receivedAt: now,
      ),
      SensorReading(
        sensorId: 'environment.light.1',
        value: 320,
        quality: SensorQuality.ok,
        receivedAt: now,
      ),
    ];

    return SensorSnapshot(
      sensors: sensors,
      readings: readings,
    );
  }
}
