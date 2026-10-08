import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

/// A generic placeholder screen shown for modules that have not yet been
/// implemented. Each feature's placeholder reuses this shared widget so the
/// UI is consistent. Real implementations replace this in later phases.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  final Color? color;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 44, color: accent),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                Chip(
                  avatar: const Icon(
                    Icons.construction_outlined,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  label: const Text(
                    'Coming in a later phase',
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.warning.withAlpha(16),
                  side: BorderSide(color: AppColors.warning.withAlpha(60)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
