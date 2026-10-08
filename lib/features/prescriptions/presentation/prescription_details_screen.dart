import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/models.dart';
import 'providers/prescriptions_controller.dart';

/// Shows full details for a single prescription with Edit / Delete actions.
///
/// Only the fields that exist are shown. Raw Firebase ids are never displayed.
class PrescriptionDetailsScreen extends StatefulWidget {
  final PrescriptionDetailsArguments? args;

  const PrescriptionDetailsScreen({super.key, this.args});

  @override
  State<PrescriptionDetailsScreen> createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState
    extends State<PrescriptionDetailsScreen> {
  Prescription? _prescription;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prescriptionId = widget.args?.prescriptionId;
    final uid = context.read<AuthProvider>().currentUid;
    if (prescriptionId == null || uid == null || uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = AppStrings.prescriptionsLoadFailed;
      });
      return;
    }
    final controller = context.read<PrescriptionsController>();
    final found = await controller.loadPrescription(uid, prescriptionId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!found) {
        _error = controller.errorMessage ?? AppStrings.prescriptionLoadFailed;
      } else {
        _prescription = controller.selectedPrescription;
      }
    });
  }

  Future<void> _openEdit() async {
    final prescription = _prescription;
    if (prescription == null) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.prescriptionForm,
      arguments: PrescriptionFormArguments(prescription: prescription),
    );
    if (mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  Future<void> _confirmDelete() async {
    final prescription = _prescription;
    final uid = context.read<AuthProvider>().currentUid;
    if (prescription == null || uid == null) return;

    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: AppStrings.deletePrescriptionTitle,
      content: AppStrings.deletePrescriptionMessage,
      confirmText: AppStrings.deletePrescriptionConfirm,
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<PrescriptionsController>();
    final success = await controller.deletePrescription(uid, prescription.id);
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(context, AppStrings.prescriptionDeleted);
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(
        context,
        controller.errorMessage ?? AppStrings.prescriptionDeleteFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.prescriptionDetailsTitle)),
      body: SafeArea(
        child: _loading
            ? const LoadingWidget(message: AppStrings.prescriptionLoadMessage)
            : _error != null
                ? ErrorStateWidget(
                    message: _error!,
                    onRetry: () {
                      setState(() => _loading = true);
                      _load();
                    },
                  )
                : _buildDetails(context, _prescription!),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Prescription prescription) {
    final isSaving = context.watch<PrescriptionsController>().isSaving;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      children: [
        // Doctor card
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMd),
                  Expanded(
                    child: Text(
                      prescription.doctorName.isNotEmpty
                          ? prescription.doctorName
                          : AppStrings.selectDoctorLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (prescription.status == PrescriptionStatus.active
                              ? AppColors.success
                              : AppColors.textHint)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      prescription.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            prescription.status == PrescriptionStatus.active
                                ? AppColors.success
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),

        // Prescription details
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: AppStrings.prescriptionDateLabel,
                value: _formatLongDate(prescription.prescriptionDate),
              ),
              if (prescription.doctorSpecialty.isNotEmpty)
                _DetailRow(
                  icon: Icons.medical_information_outlined,
                  label: AppStrings.specialtyLabel,
                  value: prescription.doctorSpecialty,
                ),
              if (prescription.hospitalName.isNotEmpty)
                _DetailRow(
                  icon: Icons.local_hospital_outlined,
                  label: AppStrings.hospitalLabel,
                  value: prescription.hospitalName,
                ),
              if (prescription.diagnosisOrCondition.isNotEmpty)
                _DetailRow(
                  icon: Icons.health_and_safety_outlined,
                  label: AppStrings.diagnosisOrConditionLabel,
                  value: prescription.diagnosisOrCondition,
                ),
              if (prescription.notes.isNotEmpty)
                _DetailRow(
                  icon: Icons.sticky_note_2_outlined,
                  label: AppStrings.notesLabel,
                  value: prescription.notes,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),

        // Medicines
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.medicinesLabel} '
                '(${prescription.medicineCount})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              if (prescription.medicines.isEmpty)
                const Text(
                  AppStrings.noMedicineSelected,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...prescription.medicines.map(
                  (medicine) => _MedicineTile(medicine: medicine),
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
                label: const Text(AppStrings.editPrescription),
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
                label: const Text(AppStrings.deletePrescriptionConfirm),
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
            width: 110,
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

class _MedicineTile extends StatelessWidget {
  final Medicine medicine;

  const _MedicineTile({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: AppSizes.paddingSm,
      ),
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicine.medicineName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          if (medicine.dosage.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${AppStrings.dosageLabel}: ${medicine.dosage}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
          if (medicine.frequency.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${AppStrings.frequencyLabel}: ${medicine.frequency}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
          if (medicine.duration.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${AppStrings.durationLabel}: ${medicine.duration}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
          if (medicine.instructions.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${AppStrings.instructionsLabel}: ${medicine.instructions}',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }
}