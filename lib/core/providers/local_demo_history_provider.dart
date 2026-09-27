import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/app_preferences.dart';
import '../repositories/local_demo_history_repository.dart';
import '../repositories/sensor_repository.dart';


final localDemoHistoryRepositoryProvider =
Provider<LocalDemoHistoryRepository>((ref) {
  return LocalDemoHistoryRepository(
    ref.watch(sharedPreferencesStoreProvider),
  );
});

final localDemoHistoryProvider = NotifierProvider<
    LocalDemoHistoryController,
    List<DemoHistoryPoint>>(
  LocalDemoHistoryController.new,
);

class LocalDemoHistoryController
    extends Notifier<List<DemoHistoryPoint>> {
  late LocalDemoHistoryRepository _repository;

  @override
  List<DemoHistoryPoint> build() {
    _repository = ref.watch(
      localDemoHistoryRepositoryProvider,
    );

    return _repository.read();
  }

  Future<void> recordSnapshot(
      SensorSnapshot snapshot,
      ) async {
    final updated = _repository.appendSnapshot(
      state,
      snapshot,
    );

    if (identical(updated, state)) {
      return;
    }

    state = updated;
    await _repository.save(updated);
  }
}
