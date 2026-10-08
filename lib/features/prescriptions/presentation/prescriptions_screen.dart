import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/models.dart';
import 'providers/prescriptions_controller.dart';

/// Prescription management home.
///
/// Lists the authenticated user's prescriptions grouped into "Upcoming /
/// Active" and "Previous Prescriptions" sections, with search by doctor or
/// medicine name and an entry point to add a new prescription.
class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  bool _loadTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadTriggered) return;
    final uid = context.read<AuthProvider>().currentUid;
    if (uid != null && uid.isNotEmpty) {
      _loadTriggered = true;
      context.read<PrescriptionsController>().loadAll(uid);
    }
  }

  void _openAdd() {
    Navigator.of(context).pushNamed(
      AppRoutes.prescriptionForm,
      arguments: const PrescriptionFormArguments(),
    );
  }

  void _handleAdd() {
    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.addPrescriptionSignIn,
          isError: true);
      return;
    }
    _openAdd();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.prescriptionsTitle),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: AppSizes.paddingMd),
                    Text(
                      AppStrings.noPrescriptions,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSizes.paddingSm),
                    Text(
                      AppStrings.noPrescriptionsMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingLg),
                PrimaryButton(
                  label: AppStrings.addPrescription,
                  icon: Icons.add,
                  onPressed: _handleAdd,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = context.watch<PrescriptionsController>();
    final prescriptions = controller.filteredPrescriptions;
    final active = controller.filteredActivePrescriptions;
    final previous = controller.filteredPreviousPrescriptions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.prescriptionsTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _handleAdd,
            tooltip: AppStrings.addPrescription,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading && prescriptions.isEmpty
            ? const LoadingWidget(message: AppStrings.prescriptionsLoadMessage)
            : controller.hasError && prescriptions.isEmpty
                ? ErrorStateWidget(
                    message: controller.errorMessage ??
                        AppStrings.prescriptionsLoadFailed,
                    onRetry: () => controller.loadAll(uid),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.paddingMd,
                          AppSizes.paddingMd,
                          AppSizes.paddingMd,
                          AppSizes.paddingSm,
                        ),
                        child: TextField(
                          key: const Key('prescriptionSearchField'),
                          onChanged: controller.setSearchQuery,
                          textInputAction: TextInputAction.search,
                          decoration: AppDecorations.inputDecoration(
                            labelText: AppStrings.searchPrescriptionsHint,
                            prefixIcon: Icons.search,
                          ),
                        ),
                      ),
                      Expanded(
                        child: prescriptions.isEmpty
                            ? _EmptyPrescriptions(onAdd: _openAdd)
                            : RefreshIndicator(
                                onRefresh: () => controller.loadAll(uid),
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSizes.paddingMd,
                                    AppSizes.paddingXs,
                                    AppSizes.paddingMd,
                                    AppSizes.paddingXl,
                                  ),
                                  children: [
                                    if (active.isNotEmpty) ...[
                                      _SectionHeader(
                                        label: AppStrings
                                            .activePrescriptionsLabel,
                                        count: active.length,
                                      ),
                                      ...active.map(
                                        (p) => _PrescriptionTile(
                                          prescription: p,
                                          onTap: () =>
                                              Navigator.of(context).pushNamed(
                                            AppRoutes.prescriptionDetails,
                                            arguments:
                                                PrescriptionDetailsArguments(
                                              prescriptionId: p.id,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (previous.isNotEmpty) ...[
                                      if (active.isNotEmpty)
                                        const SizedBox(
                                            height: AppSizes.paddingLg),
                                      _SectionHeader(
                                        label: AppStrings
                                            .previousPrescriptionsLabel,
                                        count: previous.length,
                                      ),
                                      ...previous.map(
                                        (p) => _PrescriptionTile(
                                          prescription: p,
                                          onTap: () =>
                                              Navigator.of(context).pushNamed(
                                            AppRoutes.prescriptionDetails,
                                            arguments:
                                                PrescriptionDetailsArguments(
                                              prescriptionId: p.id,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Section header with count.
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSizes.paddingXs),
          Text(
            '($count)',
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

/// Tappable prescription tile.
class _PrescriptionTile extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;

  const _PrescriptionTile({
    required this.prescription,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.divider),
            ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prescription.doctorName.isNotEmpty
                                ? prescription.doctorName
                                : AppStrings.selectDoctorLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prescription.doctorSpecialty.isNotEmpty
                                ? prescription.doctorSpecialty
                                : AppUtils.formatDate(
                                    prescription.prescriptionDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: prescription.doctorSpecialty.isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSm),
                    _StatusBadge(status: prescription.status),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSm),
                Text(
                  '${AppUtils.formatDate(prescription.prescriptionDate)} · '
                  '${prescription.medicineCount} '
                  '${AppStrings.medicinesCountWord}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                if (prescription.diagnosisOrCondition.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingSm),
                  Text(
                    prescription.diagnosisOrCondition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small colored pill showing the prescription status.
class _StatusBadge extends StatelessWidget {
  final PrescriptionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == PrescriptionStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.textHint)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Empty state with an add action.
class _EmptyPrescriptions extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPrescriptions({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingXl),
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: AppColors.textHint,
        ),
        const SizedBox(height: AppSizes.paddingMd),
        const Text(
          AppStrings.noPrescriptions,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        const Text(
          AppStrings.noPrescriptionsMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        PrimaryButton(
          label: AppStrings.addPrescription,
          icon: Icons.add,
          onPressed: onAdd,
        ),
      ],
    );
  }
}