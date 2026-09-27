import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/sensor_repository.dart';

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return const DemoSensorRepository();
});

final sensorSnapshotProvider = FutureProvider<SensorSnapshot>((ref) {
  return ref.watch(sensorRepositoryProvider).loadSnapshot();
});
