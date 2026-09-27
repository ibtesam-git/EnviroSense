import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/sensor_repository.dart';
import 'local_demo_history_provider.dart';

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return const DemoSensorRepository();
});

final sensorSnapshotProvider = FutureProvider<SensorSnapshot>((ref) async {
  final snapshot = await ref
      .watch(sensorRepositoryProvider)
      .loadSnapshot();

  await ref
      .read(localDemoHistoryProvider.notifier)
      .recordSnapshot(snapshot);

  return snapshot;
});
