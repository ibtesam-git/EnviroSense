import 'package:flutter/material.dart';

import '../motion/enviro_motion.dart';

/// Temporary shell destination for the first build slice. Replace these with
/// real Trends, Devices, and Settings screens in the next implementation pass.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 112),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: EnviroPalette.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: EnviroPalette.hairline),
                ),
                child: Icon(icon, color: EnviroPalette.brass, size: 30),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EnviroPalette.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EnviroPalette.textMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: EnviroPalette.surfaceRaised,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'NEXT BUILD',
                    style: TextStyle(
                      color: EnviroPalette.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
