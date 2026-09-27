import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion/enviro_motion.dart';
import '../../../app/motion/motion_widgets.dart';
import '../../../core/preferences/app_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final controller = ref.read(appPreferencesProvider.notifier);

    final reduceMotion = MediaQuery.of(context).disableAnimations ||
        preferences.reducedMotion;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 124),
          children: [
            SpringReveal(
              reduceMotion: reduceMotion,
              child: _header(),
            ),
            const SizedBox(height: 18),
            _savedNotice(),
            const SizedBox(height: 24),
            _sectionLabel('DISPLAY'),
            const SizedBox(height: 10),
            _temperatureUnitCard(preferences, controller),
            const SizedBox(height: 20),
            _sectionLabel('ALERTS & FEEDBACK'),
            const SizedBox(height: 10),
            _preferencesCard([
              _PreferenceRow(
                icon: Icons.notifications_active_outlined,
                title: 'Threshold alerts',
                detail:
                'Highlight readings outside the room comfort range',
                value: preferences.thresholdAlerts,
                onChanged: controller.setThresholdAlerts,
              ),
              _PreferenceRow(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                detail:
                'A subtle response to navigation and device actions',
                value: preferences.hapticFeedback,
                onChanged: controller.setHapticFeedback,
              ),
              _PreferenceRow(
                icon: Icons.volume_up_outlined,
                title: 'Sound feedback',
                detail:
                'Play a system sound for navigation actions',
                value: preferences.soundFeedback,
                onChanged: controller.setSoundFeedback,
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('ACCESSIBILITY'),
            const SizedBox(height: 10),
            _preferencesCard([
              _PreferenceRow(
                icon: Icons.motion_photos_off_rounded,
                title: 'Reduced motion',
                detail:
                'Reduce app animations while respecting system settings',
                value: preferences.reducedMotion,
                onChanged: controller.setReducedMotion,
              ),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('ABOUT'),
            const SizedBox(height: 10),
            _aboutCard(),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                await controller.reset();

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults.'),
                  ),
                );
              },
              icon: const Icon(
                Icons.restart_alt_rounded,
                size: 17,
              ),
              label: const Text('Reset settings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textMuted,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'PREFERENCES · SAVED ON THIS DEVICE',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  letterSpacing: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENVIRONMENT / PREFERENCES',
          style: TextStyle(
            color: AppTheme.brass,
            fontSize: 10,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Settings',
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
          'Tune the experience to feel like yours.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _savedNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppTheme.teal.withValues(alpha: 0.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done_outlined,
            color: AppTheme.teal,
            size: 17,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Preferences are saved locally and applied across Overview, Room View, Trends, and navigation.',
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

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 9,
        letterSpacing: 1.35,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _temperatureUnitCard(
      AppPreferences preferences,
      AppPreferencesController controller,
      ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EnviroPalette.hairline,
        ),
      ),
      child: Row(
        children: [
          _iconBox(Icons.thermostat_rounded),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature unit',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Choose how temperature is displayed',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _unitButton(
                  '°C',
                  preferences.temperatureUnit ==
                      TemperatureUnit.celsius,
                      () => controller.setTemperatureUnit(
                    TemperatureUnit.celsius,
                  ),
                ),
                _unitButton(
                  '°F',
                  preferences.temperatureUnit ==
                      TemperatureUnit.fahrenheit,
                      () => controller.setTemperatureUnit(
                    TemperatureUnit.fahrenheit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitButton(
      String unit,
      bool selected,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.surfaceRaised
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: selected
              ? Border.all(color: EnviroPalette.hairline)
              : null,
        ),
        child: Text(
          unit,
          style: TextStyle(
            color: selected
                ? AppTheme.brass
                : AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _preferencesCard(List<_PreferenceRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EnviroPalette.hairline,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 58),
                child: Divider(
                  height: 1,
                  color: EnviroPalette.hairline,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EnviroPalette.hairline,
        ),
      ),
      child: Column(
        children: [
          _aboutRow('Product', 'EnviroSense'),
          const SizedBox(height: 12),
          _aboutRow('Build', 'App preview'),
          const SizedBox(height: 12),
          _aboutRow('Data mode', 'Sample values'),
        ],
      ),
    );
  }

  Widget _aboutRow(String title, String value) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: AppTheme.teal,
        size: 17,
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.teal,
              size: 17,
            ),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.teal.withValues(alpha: 0.72),
            activeThumbColor: AppTheme.textPrimary,
          ),
        ],
      ),
    );
  }
}
