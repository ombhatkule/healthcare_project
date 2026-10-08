import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/models.dart';
import 'category_ui.dart';
import 'providers/medical_records_controller.dart';

/// Shows full details for a single medical record with Edit / Delete actions.
///
/// Args: [MedicalRecordDetailsArguments] carrying the record id. The record is
/// loaded from Firestore scoped to the authenticated user. Raw Firebase ids
/// are never shown to the user.
class MedicalRecordDetailsScreen extends StatefulWidget {
  final MedicalRecordDetailsArguments? args;

  const MedicalRecordDetailsScreen({super.key, this.args});

  @override
  State<MedicalRecordDetailsScreen> createState() =>
      _MedicalRecordDetailsScreenState();
}

class _MedicalRecordDetailsScreenState
    extends State<MedicalRecordDetailsScreen> {
  MedicalRecord? _record;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recordId = widget.args?.recordId;
    final uid = context.read<AuthProvider>().currentUid;
    if (recordId == null || uid == null || uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = AppStrings.recordsLoadFailed;
      });
      return;
    }
    final controller = context.read<MedicalRecordsController>();
    final found = await controller.loadRecord(uid, recordId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!found) {
        _error = controller.errorMessage ?? AppStrings.recordsLoadFailed;
      } else {
        _record = controller.selectedRecord;
      }
    });
  }

  Future<void> _openEdit() async {
    final record = _record;
    if (record == null) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.medicalRecordForm,
      arguments: MedicalRecordFormArguments(record: record),
    );
    if (mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<void> _confirmDelete() async {
    final record = _record;
    final uid = context.read<AuthProvider>().currentUid;
    if (record == null || uid == null) return;

    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: AppStrings.deleteRecordTitle,
      content: AppStrings.deleteRecordMessage,
      confirmText: AppStrings.deleteRecordConfirm,
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<MedicalRecordsController>();
    final success = await controller.deleteRecord(uid, record.id);
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(context, AppStrings.recordDeleted);
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recordDetailsTitle)),
      body: SafeArea(
        child: _loading
            ? const LoadingWidget(message: AppStrings.recordLoadMessage)
            : _error != null
                ? ErrorStateWidget(
                    message: _error!,
                    onRetry: () {
                      setState(() => _loading = true);
                      _load();
                    },
                  )
                : _buildDetails(context, _record!),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, MedicalRecord record) {
    final isSaving = context.watch<MedicalRecordsController>().isSaving;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      children: [
        // Title + category
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSizes.paddingXs,
                runSpacing: AppSizes.paddingXs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    medicalRecordCategoryIcon(record.category),
                    color: AppColors.primary,
                    size: 20,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      record.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingSm),
              Text(
                record.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),

        // Details
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: AppStrings.recordDateLabel,
                value: _formatLongDate(record.date),
              ),
              if (record.description.isNotEmpty)
                _DetailRow(
                  icon: Icons.article_outlined,
                  label: AppStrings.descriptionLabel,
                  value: record.description,
                ),
              if (record.doctorName.isNotEmpty)
                _DetailRow(
                  icon: Icons.person_outline,
                  label: AppStrings.doctorLabel,
                  value: record.doctorName,
                ),
              if (record.hospitalName.isNotEmpty)
                _DetailRow(
                  icon: Icons.local_hospital_outlined,
                  label: AppStrings.hospitalLabel,
                  value: record.hospitalName,
                ),
              if (record.notes.isNotEmpty)
                _DetailRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: AppStrings.notesLabel,
                  value: record.notes,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),

        // Timestamps
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              if (record.createdAt != null)
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: AppStrings.addedOnLabel,
                  value: AppUtils.formatDate(record.createdAt!),
                ),
              if (record.updatedAt != null)
                _DetailRow(
                  icon: Icons.update_outlined,
                  label: AppStrings.updatedOnLabel,
                  value: AppUtils.formatDate(record.updatedAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : _openEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(AppStrings.editRecord),
              ),
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : _confirmDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text(AppStrings.deleteRecordConfirm),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSizes.paddingSm),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}