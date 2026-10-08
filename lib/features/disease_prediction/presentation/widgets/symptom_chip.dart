import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A selectable chip for a symptom. Used in both the available list and the
/// selected symptoms section.
class SymptomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showRemoveIcon;

  const SymptomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showRemoveIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      deleteIcon: showRemoveIcon
          ? const Icon(Icons.close, size: 16)
          : null,
      onDeleted: showRemoveIcon ? onTap : null,
      deleteButtonTooltipMessage: 'Remove $label',
      selectedColor: AppColors.primary.withAlpha(40),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryDark : AppColors.textPrimary,
        fontSize: 13,
      ),
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
