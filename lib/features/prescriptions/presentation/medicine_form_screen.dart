import 'package:flutter/material.dart';

import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/models.dart';
import 'prescription_form_screen.dart' show kPrescriptionFrequencies;

/// Add / edit form for a single structured medicine.
///
/// Returns the [Medicine] via `Navigator.pop` so the parent prescription form
/// keeps authorship of the full prescription. Frequency is picked from the
/// standard list, with "Other" revealing a free-text field.
class MedicineFormScreen extends StatefulWidget {
  final MedicineFormArguments? args;

  const MedicineFormScreen({super.key, this.args});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _dosageController = TextEditingController();
  late final TextEditingController _frequencyController;
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();

  late bool _isEditing;
  late String _selectedFrequency;

  @override
  void initState() {
    super.initState();
    final medicine = widget.args?.medicine;
    _isEditing = medicine != null;
    _selectedFrequency = _defaultFrequency(medicine?.frequency ?? '');
    _nameController = TextEditingController(text: medicine?.medicineName ?? '');
    _dosageController.text = medicine?.dosage ?? '';
    _frequencyController =
        TextEditingController(text: _selectedFrequency == kPrescriptionFrequencies.last ? medicine?.frequency ?? '' : '');
    _durationController.text = medicine?.duration ?? '';
    _instructionsController.text = medicine?.instructions ?? '';
  }

  String _defaultFrequency(String stored) {
    if (kPrescriptionFrequencies.contains(stored)) return stored;
    return kPrescriptionFrequencies.last;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String get _resolvedFrequency {
    if (_selectedFrequency == kPrescriptionFrequencies.last) {
      final freeText = _frequencyController.text.trim();
      return freeText.isNotEmpty ? freeText : _selectedFrequency;
    }
    return _selectedFrequency;
  }

  void _handleDone() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final medicine = Medicine(
      id: widget.args?.medicine?.id ?? _newId(),
      medicineName: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _resolvedFrequency,
      duration: _durationController.text.trim(),
      instructions: _instructionsController.text.trim(),
    );
    Navigator.of(context).pop(medicine);
  }

  String _newId() {
    return '${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editMedicine : AppStrings.addMedicine,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('medicineNameField'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.medicineNameLabel,
                    hintText: AppStrings.medicineNameHint,
                    prefixIcon: Icons.medication_outlined,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppStrings.medicineNameRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  key: const Key('dosageField'),
                  controller: _dosageController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.dosageLabel,
                    hintText: AppStrings.dosageHint,
                    prefixIcon: Icons.speed_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                DropdownButtonFormField<String>(
                  key: const Key('frequencyDropdown'),
                  value: _selectedFrequency,
                  isExpanded: true,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.frequencyLabel,
                    prefixIcon: Icons.schedule_outlined,
                  ),
                  items: kPrescriptionFrequencies
                      .map(
                        (f) => DropdownMenuItem(value: f, child: Text(f)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFrequency = value);
                    }
                  },
                ),
                if (_selectedFrequency == kPrescriptionFrequencies.last) ...[
                  const SizedBox(height: AppSizes.paddingMd),
                  TextFormField(
                    key: const Key('otherFrequencyField'),
                    controller: _frequencyController,
                    textInputAction: TextInputAction.next,
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.frequencyOther,
                      hintText: AppStrings.frequencyOther,
                      prefixIcon: Icons.edit_outlined,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _durationController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.durationLabel,
                    hintText: AppStrings.durationHint,
                    prefixIcon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _instructionsController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.instructionsLabel,
                    hintText: AppStrings.instructionsHint,
                    prefixIcon: Icons.info_outline,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                PrimaryButton(
                  key: const Key('medicineSubmitButton'),
                  label: _isEditing
                      ? AppStrings.updateMedicine
                      : AppStrings.addMedicine,
                  icon: Icons.check,
                  onPressed: _handleDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}