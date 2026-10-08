import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../models/symptom.dart';
import 'symptom_chip.dart';

/// The section showing the user's currently selected symptoms with the option
/// to remove each individually. Shows a friendly hint when nothing is selected.
class SelectedSymptomsSection extends StatelessWidget {
  final List<Symptom> symptoms;
  final void Function(Symptom) onRemove;

  const SelectedSymptomsSection({
    super.key,
    required this.symptoms,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.selectedSymptoms} (${symptoms.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        if (symptoms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
            child: Text(
              'No symptoms selected yet.',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
            ),
          )
        else
          Wrap(
            spacing: AppSizes.paddingSm,
            runSpacing: AppSizes.paddingXs,
            children: symptoms
                .map(
                  (s) => SymptomChip(
                    label: s.name,
                    selected: true,
                    showRemoveIcon: true,
                    onTap: () => onRemove(s),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
