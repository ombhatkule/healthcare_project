import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// The primary "Predict Disease" button with a loading state.
class PredictionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const PredictionButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.analytics_outlined, size: 20),
      label: Text(isLoading ? AppStrings.analyzeSymptoms : AppStrings.predict),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
      ),
    );
  }
}
