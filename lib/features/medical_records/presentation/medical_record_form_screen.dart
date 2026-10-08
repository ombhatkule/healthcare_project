import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/models.dart';
import 'providers/medical_records_controller.dart';

/// Add / edit form for a medical record.
///
/// Used for both creating a new record and updating an existing one (the form
/// updates the same document — it never creates a duplicate on edit).
class MedicalRecordFormScreen extends StatefulWidget {
  final MedicalRecordFormArguments? args;

  const MedicalRecordFormScreen({super.key, this.args});

  @override
  State<MedicalRecordFormScreen> createState() =>
      _MedicalRecordFormScreenState();
}

class _MedicalRecordFormScreenState extends State<MedicalRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final _descriptionController = TextEditingController();
  final _doctorController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _notesController = TextEditingController();

  late MedicalRecordCategory _category;
  DateTime? _date;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    final record = widget.args?.record;
    _isEditing = record != null;
    _category = record?.category ??
        widget.args?.initialCategory ??
        MedicalRecordCategory.general;
    _date = record?.date;
    _titleController = TextEditingController(text: record?.title ?? '');
    _descriptionController.text = record?.description ?? '';
    _doctorController.text = record?.doctorName ?? '';
    _hospitalController.text = record?.hospitalName ?? '';
    _notesController.text = record?.notes ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _doctorController.dispose();
    _hospitalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: AppStrings.recordDateLabel,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.addMedicalRecordSignIn,
          isError: true);
      return;
    }

    final controller = context.read<MedicalRecordsController>();
    final record = MedicalRecord(
      id: widget.args?.record?.id ?? '',
      userId: uid,
      title: _titleController.text.trim(),
      category: _category,
      description: _descriptionController.text.trim(),
      date: _date!,
      doctorName: _doctorController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: widget.args?.record?.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = _isEditing
        ? await controller.updateRecord(record)
        : await controller.createRecord(record);
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(
        context,
        _isEditing ? AppStrings.recordUpdated : AppStrings.recordSaved,
      );
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(
        context,
        controller.errorMessage ?? AppStrings.recordsLoadFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MedicalRecordsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editRecord : AppStrings.addMedicalRecord,
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
                DropdownButtonFormField<MedicalRecordCategory>(
                  value: _category,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.recordTypeLabel,
                    prefixIcon: Icons.category_outlined,
                  ),
                  items: MedicalRecordCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.recordTitleLabel,
                    hintText: AppStrings.recordTitleHint,
                    prefixIcon: Icons.title_outlined,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppStrings.titleRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: InputDecorator(
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.recordDateLabel,
                      prefixIcon: Icons.calendar_today_outlined,
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _date != null
                          ? AppUtils.formatDate(_date!)
                          : AppStrings.noDateSelectedLabel,
                      style: TextStyle(
                        fontSize: 16,
                        color: _date != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                if (_date == null) ...[
                  const SizedBox(height: AppSizes.paddingSm),
                  Text(
                    AppStrings.dateRequired,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _descriptionController,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.descriptionLabel,
                    hintText: AppStrings.descriptionHint,
                    prefixIcon: Icons.article_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _doctorController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.doctorLabel,
                    hintText: AppStrings.doctorHint,
                    prefixIcon: Icons.person_outline,
                  ),
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
                    prefixIcon: Icons.sticky_note_2_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLg),
                PrimaryButton(
                  label: AppStrings.saveRecord,
                  icon: Icons.save_outlined,
                  isLoading: controller.isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}