import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TemperatureUnit {
  celsius,
  fahrenheit;

  String get symbol => this == TemperatureUnit.celsius ? '°C' : '°F';

  double fromCelsius(double value) {
    return this == TemperatureUnit.celsius
        ? value
        : (value * 9 / 5) + 32;
  }
}

class AppPreferences {
  const AppPreferences({
    this.temperatureUnit = TemperatureUnit.celsius,
    this.thresholdAlerts = true,
    this.hapticFeedback = true,
    this.soundFeedback = false,
    this.reducedMotion = false,
  });

  static const storageKeys = <String>{
    'enviro.temperature_unit',
    'enviro.threshold_alerts',
    'enviro.haptic_feedback',
    'enviro.sound_feedback',
    'enviro.reduced_motion',
    'enviro.demo_history.v1',
  };

  static const defaults = AppPreferences();

  final TemperatureUnit temperatureUnit;
  final bool thresholdAlerts;
  final bool hapticFeedback;
  final bool soundFeedback;
  final bool reducedMotion;

  factory AppPreferences.fromStore(
      SharedPreferencesWithCache store,
      ) {
    return AppPreferences(
      temperatureUnit:
      store.getString('enviro.temperature_unit') == 'fahrenheit'
          ? TemperatureUnit.fahrenheit
          : TemperatureUnit.celsius,
      thresholdAlerts:
      store.getBool('enviro.threshold_alerts') ?? true,
      hapticFeedback:
      store.getBool('enviro.haptic_feedback') ?? true,
      soundFeedback:
      store.getBool('enviro.sound_feedback') ?? false,
      reducedMotion:
      store.getBool('enviro.reduced_motion') ?? false,
    );
  }

  AppPreferences copyWith({
    TemperatureUnit? temperatureUnit,
    bool? thresholdAlerts,
    bool? hapticFeedback,
    bool? soundFeedback,
    bool? reducedMotion,
  }) {
    return AppPreferences(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      thresholdAlerts: thresholdAlerts ?? this.thresholdAlerts,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundFeedback: soundFeedback ?? this.soundFeedback,
      reducedMotion: reducedMotion ?? this.reducedMotion,
    );
  }
}

/// This provider is overridden in main.dart after local storage is initialized.
final sharedPreferencesStoreProvider =
Provider<SharedPreferencesWithCache>(
      (ref) => throw StateError(
    'SharedPreferencesWithCache must be initialized in main() and overridden.',
  ),
);

final appPreferencesProvider =
NotifierProvider<AppPreferencesController, AppPreferences>(
  AppPreferencesController.new,
);

class AppPreferencesController
    extends Notifier<AppPreferences> {
  late SharedPreferencesWithCache _store;

  @override
  AppPreferences build() {
    _store = ref.watch(sharedPreferencesStoreProvider);
    return AppPreferences.fromStore(_store);
  }

  Future<void> setTemperatureUnit(
      TemperatureUnit value,
      ) async {
    state = state.copyWith(temperatureUnit: value);

    await _store.setString(
      'enviro.temperature_unit',
      value.name,
    );
  }

  Future<void> setThresholdAlerts(bool value) async {
    state = state.copyWith(thresholdAlerts: value);

    await _store.setBool(
      'enviro.threshold_alerts',
      value,
    );
  }

  Future<void> setHapticFeedback(bool value) async {
    state = state.copyWith(hapticFeedback: value);

    await _store.setBool(
      'enviro.haptic_feedback',
      value,
    );
  }

  Future<void> setSoundFeedback(bool value) async {
    state = state.copyWith(soundFeedback: value);

    await _store.setBool(
      'enviro.sound_feedback',
      value,
    );
  }

  Future<void> setReducedMotion(bool value) async {
    state = state.copyWith(reducedMotion: value);

    await _store.setBool(
      'enviro.reduced_motion',
      value,
    );
  }

  Future<void> reset() async {
    state = AppPreferences.defaults;

    await _store.setString(
      'enviro.temperature_unit',
      'celsius',
    );

    await _store.setBool(
      'enviro.threshold_alerts',
      true,
    );

    await _store.setBool(
      'enviro.haptic_feedback',
      true,
    );

    await _store.setBool(
      'enviro.sound_feedback',
      false,
    );

    await _store.setBool(
      'enviro.reduced_motion',
      false,
    );
  }
}
