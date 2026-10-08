import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

/// A reusable card widget with consistent styling and optional onTap.
class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ??
            const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMd,
              vertical: AppSizes.paddingSm,
            ),
        decoration: AppDecorations.cardDecoration,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSizes.paddingMd),
          child: child,
        ),
      ),
    );
  }
}
