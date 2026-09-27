enum SensorValueKind {
  number,
  boolean,
  text,
  event,
}

enum SensorQuality {
  ok,
  warmingUp,
  stale,
  invalid,
  fault,
}

class SensorDescriptor {
  const SensorDescriptor({
    required this.id,
    required this.type,
    required this.label,
    required this.unit,
    required this.valueKind,
    this.precision = 1,
    this.enabled = true,
  });

  /// Stable ID from the ESP32; it does not change if the user renames the sensor.
  final String id;

  /// General category, such as "temperature" or "pressure".
  final String type;

  /// User-friendly name displayed in the app.
  final String label;

  /// Canonical unit, such as "Cel", "%", "hPa", or "lx".
  final String unit;

  final SensorValueKind valueKind;
  final int precision;
  final bool enabled;
}

class SensorReading {
  const SensorReading({
    required this.sensorId,
    required this.value,
    required this.quality,
    required this.receivedAt,
    this.uptimeMs,
  });

  /// Must match a SensorDescriptor.id.
  final String sensorId;

  /// Numeric sensors use num; other sensor kinds can use bool or String.
  final Object? value;

  final SensorQuality quality;

  /// Time this phone received the sample. It is not necessarily the exact
  /// time the ESP32 measured it.
  final DateTime receivedAt;

  /// Optional ESP32 uptime for ordering readings during a device boot.
  final int? uptimeMs;
}
