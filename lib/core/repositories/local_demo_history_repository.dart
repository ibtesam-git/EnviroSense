import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sensor_data.dart';
import 'sensor_repository.dart';

class DemoHistoryPoint {
  const DemoHistoryPoint({
    required this.timestamp,
    required this.temperatureC,
    required this.humidityPercent,
  });

  final DateTime timestamp;
  final double temperatureC;
  final double humidityPercent;

  Map<String, Object> toJson() {
    return {
      'time': timestamp.toIso8601String(),
      'temperatureC': temperatureC,
      'humidityPercent': humidityPercent,
    };
  }
}

/// Stores a small amount of demo history locally on the device.
///
/// This is temporary demo storage. Later, real ESP32 history can replace
/// this repository without changing the Trends screen structure.
class LocalDemoHistoryRepository {
  LocalDemoHistoryRepository(this._store);

  static const storageKey = 'enviro.demo_history.v1';
  static const _maximumPoints = 1000;

  final SharedPreferencesWithCache _store;

  Future<void> ensureSeeded() async {
    final existing = _decode(_store.getString(storageKey));

    if (existing == null || existing.isEmpty) {
      await save(_seed(DateTime.now()));
    }
  }

  List<DemoHistoryPoint> read() {
    return _decode(_store.getString(storageKey)) ??
        _seed(DateTime.now());
  }

  List<DemoHistoryPoint> appendSnapshot(
      List<DemoHistoryPoint> current,
      SensorSnapshot snapshot,
      ) {
    final temperature = _readingFor(snapshot, 'temperature');
    final humidity = _readingFor(snapshot, 'humidity');

    if (temperature == null || humidity == null) {
      return current;
    }

    final timestamp = _latestReceivedAt(snapshot) ?? DateTime.now();
    final points = List<DemoHistoryPoint>.of(current);

    if (points.isNotEmpty) {
      final last = points.last;

      final gap = timestamp.isAfter(last.timestamp)
          ? timestamp.difference(last.timestamp)
          : last.timestamp.difference(timestamp);

      if (gap < const Duration(seconds: 1)) {
        points.removeLast();
      }
    }

    points.add(
      DemoHistoryPoint(
        timestamp: timestamp,
        temperatureC: temperature,
        humidityPercent: humidity,
      ),
    );

    points.sort(
          (a, b) => a.timestamp.compareTo(b.timestamp),
    );

    final cutoff = timestamp.subtract(
      const Duration(days: 30),
    );

    final retained = points
        .where(
          (point) => !point.timestamp.isBefore(cutoff),
    )
        .toList(growable: true);

    if (retained.length > _maximumPoints) {
      retained.removeRange(
        0,
        retained.length - _maximumPoints,
      );
    }

    return retained;
  }

  Future<void> save(List<DemoHistoryPoint> points) async {
    await _store.setString(
      storageKey,
      jsonEncode(
        points.map((point) => point.toJson()).toList(),
      ),
    );
  }

  List<DemoHistoryPoint>? _decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);

      if (decoded is! List) {
        return null;
      }

      final points = <DemoHistoryPoint>[];

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final timestampText = item['time'];
        final temperature = item['temperatureC'];
        final humidity = item['humidityPercent'];

        if (timestampText is! String ||
            temperature is! num ||
            humidity is! num) {
          continue;
        }

        final timestamp = DateTime.tryParse(timestampText);

        if (timestamp == null) {
          continue;
        }

        points.add(
          DemoHistoryPoint(
            timestamp: timestamp,
            temperatureC: temperature.toDouble(),
            humidityPercent: humidity.toDouble(),
          ),
        );
      }

      points.sort(
            (a, b) => a.timestamp.compareTo(b.timestamp),
      );

      return points.isEmpty ? null : points;
    } on FormatException {
      return null;
    }
  }

  double? _readingFor(
      SensorSnapshot snapshot,
      String type,
      ) {
    for (final sensor in snapshot.sensors) {
      if (!sensor.enabled ||
          sensor.type.toLowerCase() != type) {
        continue;
      }

      for (final reading in snapshot.readings) {
        final value = reading.value;

        if (reading.sensorId == sensor.id &&
            reading.quality == SensorQuality.ok &&
            value is num) {
          return value.toDouble();
        }
      }
    }

    return null;
  }

  DateTime? _latestReceivedAt(
      SensorSnapshot snapshot,
      ) {
    DateTime? latest;

    for (final reading in snapshot.readings) {
      if (latest == null ||
          reading.receivedAt.isAfter(latest)) {
        latest = reading.receivedAt;
      }
    }

    return latest;
  }

  List<DemoHistoryPoint> _seed(DateTime now) {
    final points = <DemoHistoryPoint>[];

    for (var i = 0; i < _temperatureDay.length; i++) {
      final hoursAgo = _temperatureDay.length - 1 - i;

      points.add(
        DemoHistoryPoint(
          timestamp: now.subtract(
            Duration(hours: hoursAgo),
          ),
          temperatureC: _temperatureDay[i],
          humidityPercent: _humidityDay[i],
        ),
      );
    }

    for (var i = 0; i < _temperatureWeek.length; i++) {
      points.add(
        DemoHistoryPoint(
          timestamp: now.subtract(
            Duration(hours: 30 + i * 12),
          ),
          temperatureC: _temperatureWeek[i],
          humidityPercent: _humidityWeek[i],
        ),
      );
    }

    for (var i = 0; i < 23; i++) {
      final monthIndex = i + 7;

      points.add(
        DemoHistoryPoint(
          timestamp: now.subtract(
            Duration(days: 8 + i),
          ),
          temperatureC: _temperatureMonth[monthIndex],
          humidityPercent: _humidityMonth[monthIndex],
        ),
      );
    }

    points.sort(
          (a, b) => a.timestamp.compareTo(b.timestamp),
    );

    return points;
  }
}

const _temperatureDay = <double>[
  21.8,
  21.6,
  21.4,
  21.3,
  21.5,
  22.0,
  22.8,
  23.4,
  24.1,
  24.6,
  24.9,
  25.1,
  24.8,
  24.5,
  24.2,
  24.0,
  23.9,
  23.7,
  23.5,
  23.3,
  23.2,
  23.4,
  23.6,
  23.8,
];

const _temperatureWeek = <double>[
  22.4,
  22.8,
  23.1,
  22.7,
  23.5,
  24.0,
  23.7,
  24.2,
  24.6,
  24.1,
  23.9,
  24.4,
  23.6,
  23.8,
];

const _temperatureMonth = <double>[
  21.9,
  22.2,
  22.8,
  22.5,
  23.1,
  23.4,
  22.9,
  23.6,
  23.2,
  23.8,
  24.0,
  23.6,
  24.2,
  24.6,
  24.1,
  23.8,
  23.4,
  23.9,
  24.3,
  24.7,
  24.1,
  23.7,
  23.5,
  23.9,
  24.2,
  23.8,
  23.6,
  23.4,
  23.7,
  23.8,
];

const _humidityDay = <double>[
  51,
  52,
  52,
  53,
  52,
  51,
  50,
  49,
  48,
  47,
  46,
  45,
  44,
  45,
  46,
  47,
  48,
  49,
  48,
  47,
  46,
  46,
  47,
  47,
];

const _humidityWeek = <double>[
  48,
  49,
  47,
  46,
  48,
  50,
  49,
  47,
  46,
  45,
  47,
  48,
  46,
  47,
];

const _humidityMonth = <double>[
  50,
  49,
  48,
  51,
  52,
  49,
  47,
  48,
  46,
  45,
  47,
  49,
  51,
  50,
  48,
  47,
  46,
  48,
  49,
  47,
  45,
  46,
  48,
  50,
  49,
  47,
  46,
  45,
  46,
  47,
];
