import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// A search field for filtering available symptoms, with a clear button.
class SymptomSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SymptomSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: AppDecorations.inputDecoration(
        labelText: AppStrings.searchSymptoms,
        hintText: AppStrings.symptomSearchHint,
        prefixIcon: Icons.search,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: AppStrings.clear,
                onPressed: onClear,
              ),
      ),
      onChanged: onChanged,
    );
  }
}
