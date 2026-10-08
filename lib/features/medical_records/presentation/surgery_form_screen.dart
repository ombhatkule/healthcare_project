import 'package:flutter/material.dart';

import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/models.dart';

/// Add / edit form for a past surgery entry.
///
/// Returns the resulting [PastSurgery] via `Navigator.pop` so the parent
/// screen can add or replace the entry in the profile list.
class SurgeryFormScreen extends StatefulWidget {
  final SurgeryFormArguments? args;

  const SurgeryFormScreen({super.key, this.args});

  @override
  State<SurgeryFormScreen> createState() => _SurgeryFormScreenState();
}

class _SurgeryFormScreenState extends State<SurgeryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  late final TextEditingController _hospitalController;
  late final TextEditingController _notesController;

  bool get _isEditing => widget.args?.surgery != null;

  @override
  void initState() {
    super.initState();
    final surgery = widget.args?.surgery;
    _nameController = TextEditingController(text: surgery?.name ?? '');
    _yearController = TextEditingController(
      text: surgery?.year?.toString() ?? '',
    );
    _hospitalController = TextEditingController(text: surgery?.hospital ?? '');
    _notesController = TextEditingController(text: surgery?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _hospitalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = PastSurgery(
      name: _nameController.text.trim(),
      year: int.tryParse(_yearController.text.trim()),
      hospital: _hospitalController.text.trim(),
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? AppStrings.editRecord
            : AppStrings.addSurgery),
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
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.surgeryNameLabel,
                    prefixIcon: Icons.medical_services_outlined,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppStrings.surgeryNameRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.surgeryYearLabel,
                    hintText: 'e.g. 2022',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final year = int.tryParse(value.trim());
                    if (year == null ||
                        year < 1900 ||
                        year > DateTime.now().year + 1) {
                      return AppStrings.invalidSurgeryYear;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _hospitalController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.hospitalLabel,
                    hintText: AppStrings.hospitalHint,
                    prefixIcon: Icons.local_hospital_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.notesLabel,
                    hintText: AppStrings.notesHint,
                    prefixIcon: Icons.article_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                PrimaryButton(
                  label: AppStrings.save,
                  icon: Icons.save_outlined,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      AppSizes.buttonHeight,
                    ),
                    side: const BorderSide(color: AppColors.textHint),
                  ),
                  child: const Text(AppStrings.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}