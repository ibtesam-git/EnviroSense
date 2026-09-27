import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/app_theme.dart';
import '../../../core/ble/ble_manager.dart';
import '../../../core/ble/gatt_profile.dart';

class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  Timer? _scanTimer;

  final Map<String, DiscoveredDevice> _devices = {};

  bool _isScanning = false;
  bool _scanFinished = false;
  bool _isConnecting = false;
  bool _verificationInProgress = false;

  String? _activeDeviceId;
  String? _verifiedDeviceId;
  String? _message;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      lowerBound: 0.96,
      upperBound: 1.04,
    );
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    unawaited(_scanSubscription?.cancel() ?? Future<void>.value());
    unawaited(_connectionSubscription?.cancel() ?? Future<void>.value());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning || _activeDeviceId != null) return;

    setState(() {
      _devices.clear();
      _message = null;
      _scanFinished = false;
    });

    final manager = ref.read(bleManagerProvider);
    final permission = await manager.requestScanPermission();

    if (!mounted) return;

    if (!permission.isGranted) {
      setState(() {
        _message = permission.isPermanentlyDenied
            ? 'Bluetooth permission is disabled. Allow Nearby devices in Android Settings.'
            : 'Allow Nearby devices permission to scan for Bluetooth devices.';
      });

      if (permission.isPermanentlyDenied) {
        await openAppSettings();
      }
      return;
    }

    setState(() => _isScanning = true);
    _pulseController.repeat(reverse: true);

    _scanSubscription = manager.scanForNearbyBleDevices().listen(
          (device) {
        if (!mounted) return;
        setState(() {
          // Keep the newest signal/name data for each discovered device.
          _devices[device.id] = device;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        unawaited(_stopScan());
        setState(() {
          _message = 'Bluetooth scan failed. Check that Bluetooth is on.';
        });
      },
    );

    _scanTimer = Timer(const Duration(seconds: 15), () {
      unawaited(_finishScan());
    });
  }

  Future<void> _finishScan() async {
    await _stopScan();
    if (!mounted) return;
    setState(() => _scanFinished = true);
  }

  Future<void> _stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _pulseController.stop();
    _pulseController.value = 1;

    if (mounted && _isScanning) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    if (_activeDeviceId != null) return;

    await _stopScan();

    if (!mounted) return;

    final manager = ref.read(bleManagerProvider);
    final permission = await manager.requestConnectPermission();

    if (!mounted) return;

    if (!permission.isGranted) {
      setState(() {
        _message = permission.isPermanentlyDenied
            ? 'Bluetooth connection permission is disabled. Allow Nearby devices in Android Settings.'
            : 'Allow Nearby devices permission to connect.';
      });

      if (permission.isPermanentlyDenied) {
        await openAppSettings();
      }
      return;
    }

    setState(() {
      _activeDeviceId = device.id;
      _verifiedDeviceId = null;
      _isConnecting = true;
      _message = 'Asking ${_displayName(device)} to accept the connection…';
    });

    _connectionSubscription = manager.connectToDevice(device.id).listen(
          (update) {
        if (!mounted || update.deviceId != device.id) return;

        switch (update.connectionState) {
          case DeviceConnectionState.connecting:
            setState(() {
              _isConnecting = true;
              _message = 'Connecting to ${_displayName(device)}…';
            });

          case DeviceConnectionState.connected:
            setState(() {
              _isConnecting = false;
              _message = 'Connected. Checking the device’s services…';
            });
            unawaited(_verifyDeviceProfile(manager, device));

          case DeviceConnectionState.disconnecting:
            setState(() {
              _message = 'Disconnecting from ${_displayName(device)}…';
            });

          case DeviceConnectionState.disconnected:
            setState(() {
              _activeDeviceId = null;
              _verifiedDeviceId = null;
              _isConnecting = false;
              _verificationInProgress = false;
              _connectionSubscription = null;
              _message ??= 'Device disconnected.';
            });
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _activeDeviceId = null;
          _verifiedDeviceId = null;
          _isConnecting = false;
          _connectionSubscription = null;
          _message = 'The device did not accept or complete the connection.';
        });
      },
    );
  }

  Future<void> _verifyDeviceProfile(
      BleManager manager,
      DiscoveredDevice device,
      ) async {
    if (_verificationInProgress) return;
    _verificationInProgress = true;

    try {
      final services = await manager.discoverServices(device.id);
      final isCompatible = manager.hasEnviroSenseProfile(services);

      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        if (isCompatible) {
          _verifiedDeviceId = device.id;
          _message =
          'EnviroSense service verified on ${_displayName(device)}. '
              'Sensor data streaming is the next connection step.';
        } else {
          _verifiedDeviceId = null;
          _message =
          'The BLE connection succeeded, but this device does not expose '
              'the complete EnviroSense service. It cannot provide readings to this app yet.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _verifiedDeviceId = null;
        _message =
        'Connected, but the device did not allow service discovery. '
            'It may require pairing or use a different BLE profile.';
      });
    } finally {
      _verificationInProgress = false;
    }
  }

  Future<void> _disconnect() async {
    final subscription = _connectionSubscription;
    _connectionSubscription = null;

    await subscription?.cancel();

    if (!mounted) return;

    setState(() {
      _activeDeviceId = null;
      _verifiedDeviceId = null;
      _isConnecting = false;
      _message = 'Disconnected.';
    });
  }

  bool _advertisesEnviroSense(DiscoveredDevice device) {
    return device.serviceUuids.contains(
      Uuid.parse(EnviroSenseGattProfile.service),
    );
  }

  String _displayName(DiscoveredDevice device) {
    final name = device.name.trim();
    return name.isEmpty ? 'Unnamed BLE device' : name;
  }

  String _shortId(String id) {
    if (id.length <= 12) return id;
    return '…${id.substring(id.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final devices = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby devices'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isScanning ? _pulseController.value : 1,
                  child: child,
                );
              },
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface,
                  border: Border.all(
                    color: _isScanning ? AppTheme.teal : AppTheme.brass,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isScanning ? AppTheme.teal : AppTheme.brass)
                          .withValues(alpha: 0.13),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _isScanning
                      ? Icons.bluetooth_searching_rounded
                      : Icons.bluetooth_rounded,
                  color: _isScanning ? AppTheme.teal : AppTheme.brass,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _isScanning ? 'Scanning nearby' : 'Choose a device',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The app lists nearby Bluetooth Low Energy (BLE) advertisers. '
                'Select a device to try connecting; it may reject the request.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          if (_isScanning) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(
              color: AppTheme.teal,
              backgroundColor: AppTheme.surfaceRaised,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scanning for 15 seconds',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 18),
            _Notice(message: _message!),
          ],
          if (_scanFinished && devices.isEmpty && _message == null) ...[
            const SizedBox(height: 18),
            const _Notice(
              message:
              'No BLE advertisers found. Make sure the device is powered on, nearby, and advertising BLE. Classic-Bluetooth accessories may not appear in this scan.',
            ),
          ],
          if (devices.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(
              'NEARBY BLE DEVICES  ·  ${devices.length}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final device in devices)
              _DeviceCard(
                device: device,
                displayName: _displayName(device),
                shortId: _shortId(device.id),
                advertisesEnviroSense: _advertisesEnviroSense(device),
                isActive: _activeDeviceId == device.id,
                isVerified: _verifiedDeviceId == device.id,
                isConnecting:
                _activeDeviceId == device.id && _isConnecting,
                anotherDeviceActive:
                _activeDeviceId != null && _activeDeviceId != device.id,
                onConnect: () => _connectToDevice(device),
                onDisconnect: _disconnect,
              ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _activeDeviceId != null
                ? null
                : _isScanning
                ? _stopScan
                : _startScan,
            icon: Icon(
              _isScanning
                  ? Icons.stop_rounded
                  : Icons.bluetooth_searching_rounded,
            ),
            label: Text(_isScanning ? 'Stop scan' : 'Scan for nearby devices'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brass,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Any selected device must accept the BLE connection. '
                'Sensor readings require the EnviroSense service and data protocol.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.displayName,
    required this.shortId,
    required this.advertisesEnviroSense,
    required this.isActive,
    required this.isVerified,
    required this.isConnecting,
    required this.anotherDeviceActive,
    required this.onConnect,
    required this.onDisconnect,
  });

  final DiscoveredDevice device;
  final String displayName;
  final String shortId;
  final bool advertisesEnviroSense;
  final bool isActive;
  final bool isVerified;
  final bool isConnecting;
  final bool anotherDeviceActive;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final label = isVerified
        ? 'EnviroSense service verified'
        : advertisesEnviroSense
        ? 'Advertises EnviroSense'
        : 'BLE device · compatibility unknown';

    final buttonLabel = isConnecting
        ? 'Connecting…'
        : isActive
        ? 'Disconnect'
        : 'Connect';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVerified
              ? AppTheme.teal.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isVerified
                    ? Icons.sensors_rounded
                    : Icons.bluetooth_rounded,
                color: isVerified ? AppTheme.teal : AppTheme.brass,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$label  ·  ${device.rssi} dBm',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ID $shortId',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: isConnecting
                    ? null
                    : anotherDeviceActive
                    ? null
                    : isActive
                    ? onDisconnect
                    : onConnect,
                child: Text(buttonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textMuted,
          height: 1.4,
        ),
      ),
    );
  }
}
