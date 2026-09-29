import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'gatt_profile.dart';

final bleManagerProvider = Provider<BleManager>((ref) {
  return BleManager(
    FlutterReactiveBle(),
    DeviceInfoPlugin(),
  );
});

final bleSessionProvider =
NotifierProvider<BleSessionController, BleSessionState>(
  BleSessionController.new,
);

enum BleSessionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class TelemetryReading {
  const TelemetryReading({
    required this.temperatureC,
    required this.humidityPercent,
    required this.receivedAt,
  });

  final double temperatureC;
  final double humidityPercent;
  final DateTime receivedAt;
}

class BleSessionState {
  const BleSessionState({
    this.status = BleSessionStatus.disconnected,
    this.deviceId,
    this.statusMessage,
    this.profileVerified = false,
    this.telemetry,
  });

  final BleSessionStatus status;
  final String? deviceId;
  final String? statusMessage;
  final bool profileVerified;
  final TelemetryReading? telemetry;

  bool get isConnected => status == BleSessionStatus.connected;

  bool get isBusy =>
      status == BleSessionStatus.connecting ||
          status == BleSessionStatus.disconnecting;

  BleSessionState copyWith({
    BleSessionStatus? status,
    String? deviceId,
    String? statusMessage,
    bool? profileVerified,
    TelemetryReading? telemetry,
    bool clearDeviceId = false,
    bool clearTelemetry = false,
  }) {
    return BleSessionState(
      status: status ?? this.status,
      deviceId: clearDeviceId ? null : deviceId ?? this.deviceId,
      statusMessage: statusMessage ?? this.statusMessage,
      profileVerified: profileVerified ?? this.profileVerified,
      telemetry: clearTelemetry ? null : telemetry ?? this.telemetry,
    );
  }
}

class BleSessionController extends Notifier<BleSessionState> {
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _telemetrySubscription;

  @override
  BleSessionState build() {
    ref.onDispose(() {
      unawaited(_connectionSubscription?.cancel());
      unawaited(_telemetrySubscription?.cancel());
    });

    return const BleSessionState();
  }

  Future<void> connect({
    required String deviceId,
    required String displayName,
  }) async {
    if (state.isBusy) return;

    if (state.isConnected && state.deviceId == deviceId) return;

    if (state.deviceId != null && state.deviceId != deviceId) {
      await disconnect();
    }

    final manager = ref.read(bleManagerProvider);
    final permission = await manager.requestConnectPermission();

    if (!permission.isGranted) {
      state = const BleSessionState(
        status: BleSessionStatus.error,
        statusMessage: 'Bluetooth connection permission was not granted.',
      );
      return;
    }

    state = BleSessionState(
      status: BleSessionStatus.connecting,
      deviceId: deviceId,
      statusMessage: 'Connecting to $displayName…',
    );

    await _connectionSubscription?.cancel();

    _connectionSubscription = manager.connectToDevice(deviceId).listen(
          (update) {
        _handleConnectionUpdate(
          update,
          manager: manager,
          displayName: displayName,
        );
      },
      onError: (Object error) {
        unawaited(_telemetrySubscription?.cancel());
        _telemetrySubscription = null;
        state = BleSessionState(
          status: BleSessionStatus.error,
          deviceId: deviceId,
          statusMessage:
          'The connection failed. Check Bluetooth and device power.',
        );
      },
    );
  }

  void _handleConnectionUpdate(
      ConnectionStateUpdate update, {
        required BleManager manager,
        required String displayName,
      }) {
    if (update.deviceId != state.deviceId) return;

    switch (update.connectionState) {
      case DeviceConnectionState.connecting:
        state = state.copyWith(
          status: BleSessionStatus.connecting,
          statusMessage: 'Connecting to $displayName…',
        );

      case DeviceConnectionState.connected:
        state = state.copyWith(
          status: BleSessionStatus.connected,
          statusMessage: 'Connected to $displayName.',
        );
        unawaited(_verifyProfile(manager, update.deviceId));
        unawaited(_startTelemetry(manager, update.deviceId));

      case DeviceConnectionState.disconnecting:
        state = state.copyWith(
          status: BleSessionStatus.disconnecting,
          statusMessage: 'Disconnecting from $displayName…',
        );

      case DeviceConnectionState.disconnected:
        unawaited(_telemetrySubscription?.cancel());
        _telemetrySubscription = null;
        state = const BleSessionState(
          status: BleSessionStatus.disconnected,
          statusMessage: 'Device disconnected.',
        );
    }
  }

  Future<void> _verifyProfile(
      BleManager manager,
      String deviceId,
      ) async {
    try {
      final services = await manager.discoverServices(deviceId);
      final verified = manager.hasEnviroSenseProfile(services);

      if (state.deviceId != deviceId) return;

      state = state.copyWith(
        profileVerified: verified,
        statusMessage: verified
            ? 'EnviroSense device connected.'
            : 'Connected, but the EnviroSense BLE profile was not found.',
      );
    } catch (_) {
      if (state.deviceId != deviceId) return;

      state = state.copyWith(
        profileVerified: false,
        statusMessage: 'Connected, but service discovery failed.',
      );
    }
  }

  Future<void> _startTelemetry(
      BleManager manager,
      String deviceId,
      ) async {
    await _telemetrySubscription?.cancel();

    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(EnviroSenseGattProfile.service),
      characteristicId: Uuid.parse(EnviroSenseGattProfile.telemetry),
      deviceId: deviceId,
    );

    _telemetrySubscription = manager
        .subscribeToTelemetry(characteristic)
        .listen(
          (bytes) {
        final reading = _parseTelemetry(bytes);
        if (reading == null || state.deviceId != deviceId) return;

        state = state.copyWith(
          telemetry: reading,
          statusMessage: 'Receiving live DHT22 readings.',
        );
      },
      onError: (Object error) {
        if (state.deviceId != deviceId) return;

        state = state.copyWith(
          statusMessage: 'Connected, but telemetry notifications failed.',
        );
      },
    );
  }

  TelemetryReading? _parseTelemetry(List<int> bytes) {
    try {
      final decoded = jsonDecode(
        utf8.decode(bytes, allowMalformed: true),
      );

      if (decoded is! Map<String, dynamic>) return null;

      final temperature = decoded['temperature'];
      final humidity = decoded['humidity'];

      if (temperature is! num || humidity is! num) return null;

      return TelemetryReading(
        temperatureC: temperature.toDouble(),
        humidityPercent: humidity.toDouble(),
        receivedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> disconnect() async {
    final connection = _connectionSubscription;
    final telemetry = _telemetrySubscription;

    _connectionSubscription = null;
    _telemetrySubscription = null;

    state = state.copyWith(
      status: BleSessionStatus.disconnecting,
      statusMessage: 'Disconnecting…',
    );

    await telemetry?.cancel();
    await connection?.cancel();

    state = const BleSessionState(
      status: BleSessionStatus.disconnected,
      statusMessage: 'Disconnected.',
    );
  }
}

class BleManager {
  BleManager(this._ble, this._deviceInfo);

  final FlutterReactiveBle _ble;
  final DeviceInfoPlugin _deviceInfo;

  Future<PermissionStatus> requestScanPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;

    final androidInfo = await _deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 31) {
      return Permission.bluetoothScan.request();
    }

    return Permission.locationWhenInUse.request();
  }

  Future<PermissionStatus> requestConnectPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;

    final androidInfo = await _deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 31) {
      return Permission.bluetoothConnect.request();
    }

    return PermissionStatus.granted;
  }

  Stream<DiscoveredDevice> scanForNearbyBleDevices() {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    );
  }

  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    return _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    );
  }

  Stream<List<int>> subscribeToTelemetry(
      QualifiedCharacteristic characteristic,
      ) {
    return _ble.subscribeToCharacteristic(characteristic);
  }

  Future<List<Service>> discoverServices(String deviceId) async {
    await _ble.discoverAllServices(deviceId);
    return _ble.getDiscoveredServices(deviceId);
  }

  bool hasEnviroSenseProfile(List<Service> services) {
    final expectedService = Uuid.parse(
      EnviroSenseGattProfile.service,
    );

    final requiredCharacteristics = [
      Uuid.parse(EnviroSenseGattProfile.deviceInfo),
      Uuid.parse(EnviroSenseGattProfile.sensorCatalog),
      Uuid.parse(EnviroSenseGattProfile.telemetry),
      Uuid.parse(EnviroSenseGattProfile.control),
    ];

    for (final service in services) {
      if (service.id != expectedService) continue;

      final characteristicIds = service.characteristics
          .map((characteristic) => characteristic.id);

      return requiredCharacteristics.every(
        characteristicIds.contains,
      );
    }

    return false;
  }
}
