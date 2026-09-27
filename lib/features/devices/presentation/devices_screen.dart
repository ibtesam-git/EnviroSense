import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion/enviro_motion.dart';
import '../../../app/motion/motion_widgets.dart';
import '../../../core/preferences/app_preferences.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        ref.watch(appPreferencesProvider).reducedMotion;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
          children: [
            SpringReveal(reduceMotion: reduceMotion, child: _header()),
            const SizedBox(height: 22),
            SpringReveal(
              delay: const Duration(milliseconds: 70),
              reduceMotion: reduceMotion,
              child: _connectionCard(context),
            ),
            const SizedBox(height: 25),
            _sectionLabel('WHAT WILL APPEAR HERE'),
            const SizedBox(height: 10),
            const _CapabilityCard(),
            const SizedBox(height: 18),
            _sectionLabel('SUPPORTED SENSOR TYPES'),
            const SizedBox(height: 10),
            const _SensorTypeGrid(),
            const SizedBox(height: 20),
            const _HardwareNote(),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'DEVICE CENTER · UI PREVIEW',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'ENVIRONMENT / HARDWARE',
        style: TextStyle(
          color: AppTheme.brass,
          fontSize: 10,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 7),
      Text(
        'Devices',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 29,
          height: 1,
          letterSpacing: -0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 7),
      Text(
        'Your sensor connections, all in one place.',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
    ],
  );

  Widget _connectionCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF202D29), Color(0xFF131B19)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.18)),
              ),
              child: const Icon(
                Icons.sensors_rounded,
                color: AppTheme.teal,
                size: 21,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.brass.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.brass.withValues(alpha: 0.20)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science_outlined, color: AppTheme.brass, size: 13),
                  SizedBox(width: 6),
                  Text(
                    'PREVIEW',
                    style: TextStyle(
                      color: AppTheme.brass,
                      fontSize: 8,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 21),
        const Text(
          'No device paired',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Your first EnviroSense sensor will appear here after the hardware pairing flow is added.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 17),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showHardwareNote(context),
            icon: const Icon(Icons.bluetooth_searching_rounded, size: 16),
            label: const Text('Pairing setup comes later'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.brass,
              side: BorderSide(color: AppTheme.brass.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: AppTheme.textMuted,
      fontSize: 9,
      letterSpacing: 1.35,
      fontWeight: FontWeight.w700,
    ),
  );

  void _showHardwareNote(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceRaised,
        icon: const Icon(Icons.build_circle_outlined, color: AppTheme.brass),
        title: const Text('Hardware pairing is postponed'),
        content: const Text(
          'This screen is a design preview for now. BLE pairing and ESP32 data handling will be connected in the later hardware phase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: EnviroPalette.hairline),
    ),
    child: const Column(
      children: [
        _CapabilityRow(
          icon: Icons.bluetooth_searching_rounded,
          title: 'Connection status',
          detail: 'Pairing state and nearby-device signal',
        ),
        Divider(height: 1, color: EnviroPalette.hairline),
        _CapabilityRow(
          icon: Icons.sensors_rounded,
          title: 'Sensor channels',
          detail: 'See which readings each device provides',
        ),
        Divider(height: 1, color: EnviroPalette.hairline),
        _CapabilityRow(
          icon: Icons.schedule_rounded,
          title: 'Last update',
          detail: 'Know when a sensor last reported data',
        ),
      ],
    ),
  );
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.teal, size: 16),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 17),
      ],
    ),
  );
}

class _SensorTypeGrid extends StatelessWidget {
  const _SensorTypeGrid();

  static const _items = <(IconData, String, String)>[
    (Icons.thermostat_rounded, 'Temperature', '°C'),
    (Icons.water_drop_rounded, 'Humidity', '%'),
    (Icons.speed_rounded, 'Pressure', 'hPa'),
    (Icons.light_mode_rounded, 'Light', 'lx'),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 2.35,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (final item in _items)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EnviroPalette.hairline),
          ),
          child: Row(
            children: [
              Icon(item.$1, color: AppTheme.teal, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                item.$3,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
            ],
          ),
        ),
    ],
  );
}

class _HardwareNote extends StatelessWidget {
  const _HardwareNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surfaceRaised.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: EnviroPalette.hairline),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: AppTheme.brass, size: 17),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Hardware connection and live ESP32 data are intentionally not part of this UI step.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
