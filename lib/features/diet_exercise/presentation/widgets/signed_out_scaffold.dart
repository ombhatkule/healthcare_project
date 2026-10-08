import 'package:flutter/material.dart';

import '../../../../config/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import 'wellness_disclaimer.dart';

/// Shown when no user is signed in, instead of an empty or broken screen.
class SignedOutScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const SignedOutScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: AppColors.textHint),
              const SizedBox(height: AppSizes.paddingMd),
              Text(
                AppStrings.signInToTrack,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingMd),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),
              PrimaryButton(
                label: AppStrings.continueButton,
                icon: Icons.login,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.login),
              ),
              const SizedBox(height: AppSizes.paddingMd),
              const WellnessDisclaimer(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}