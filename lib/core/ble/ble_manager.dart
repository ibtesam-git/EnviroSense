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

class BleManager {
  BleManager(this._ble, this._deviceInfo);

  final FlutterReactiveBle _ble;
  final DeviceInfoPlugin _deviceInfo;

  Future<PermissionStatus> requestScanPermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }

    final androidInfo = await _deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 31) {
      return Permission.bluetoothScan.request();
    }

    return Permission.locationWhenInUse.request();
  }

  Future<PermissionStatus> requestConnectPermission() async {
    if (!Platform.isAndroid) {
      return PermissionStatus.granted;
    }

    final androidInfo = await _deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 31) {
      return Permission.bluetoothConnect.request();
    }

    return PermissionStatus.granted;
  }

  /// Scans for all nearby Bluetooth Low Energy advertisers.
  Stream<DiscoveredDevice> scanForNearbyBleDevices() {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    );
  }

  /// Starts a connection attempt to the device selected by the user.
  Stream<ConnectionStateUpdate> connectToDevice(String deviceId) {
    return _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    );
  }

  /// Discovers and returns the services exposed by the connected device.
  Future<List<Service>> discoverServices(String deviceId) async {
    await _ble.discoverAllServices(deviceId);
    return _ble.getDiscoveredServices(deviceId);
  }

  /// Checks for EnviroSense's service and required characteristics.
  bool hasEnviroSenseProfile(List<Service> services) {
    final expectedService = Uuid.parse(EnviroSenseGattProfile.service);

    final requiredCharacteristics = [
      Uuid.parse(EnviroSenseGattProfile.deviceInfo),
      Uuid.parse(EnviroSenseGattProfile.sensorCatalog),
      Uuid.parse(EnviroSenseGattProfile.telemetry),
      Uuid.parse(EnviroSenseGattProfile.control),
    ];

    for (final service in services) {
      if (service.id == expectedService) {
        final characteristicIds =
        service.characteristics.map((characteristic) => characteristic.id);

        return requiredCharacteristics.every(characteristicIds.contains);
      }
    }

    return false;
  }
}
