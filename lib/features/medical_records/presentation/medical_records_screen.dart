import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/models.dart';
import 'providers/medical_records_controller.dart';

/// The EHR overview ("Records" tab and dashboard "Medical Records" entry).
///
/// Summarizes the authenticated user's medical information, medical history,
/// doctor visits and documents, and provides entry points to manage them.
class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _loadTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadTriggered) return;
    final uid = context.read<AuthProvider>().currentUid;
    if (uid != null && uid.isNotEmpty) {
      _loadTriggered = true;
      context.read<MedicalRecordsController>().loadAll(uid);
    }
  }

  void _openAddRecord() {
    Navigator.of(context).pushNamed(
      AppRoutes.medicalRecordForm,
      arguments: const MedicalRecordFormArguments(
        initialCategory: MedicalRecordCategory.general,
      ),
    );
  }

  void _handleAddRecord(BuildContext context) {
    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.addMedicalRecordSignIn,
          isError: true);
      return;
    }
    _openAddRecord();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.medicalRecordsTitle),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSizes.paddingXl,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingXl,
                    ),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSizes.paddingXxl * 2),
                      const Icon(
                        Icons.medical_information_outlined,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      const Text(
                        AppStrings.noMedicalRecords,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingSm),
                      const Text(
                        AppStrings.noMedicalRecordsMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingLg),
                      PrimaryButton(
                        label: AppStrings.addMedicalRecord,
                        icon: Icons.note_add_outlined,
                        onPressed: () => _handleAddRecord(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    final controller = context.watch<MedicalRecordsController>();
    final showEmpty =
        controller.records.isEmpty &&
        (controller.medicalProfile == null ||
            controller.medicalProfile!.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.medicalRecordsTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: controller.isLoading &&
                controller.records.isEmpty &&
                controller.medicalProfile == null
            ? const LoadingWidget(message: AppStrings.recordsLoadMessage)
            : controller.hasError &&
                    controller.records.isEmpty &&
                    controller.medicalProfile == null
                ? ErrorStateWidget(
                    message:
                        controller.errorMessage ?? AppStrings.recordsLoadFailed,
                    onRetry: () => controller.loadAll(uid),
                  )
                : RefreshIndicator(
                    onRefresh: () => controller.loadAll(uid),
                    child: showEmpty
                        ? _buildEmptyBody(context)
                        : _buildSummaryBody(context, controller),
                  ),
      ),
    );
  }

  Widget _buildEmptyBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingXl),
      children: [
        const Icon(
          Icons.medical_information_outlined,
          size: 64,
          color: AppColors.textHint,
        ),
        const SizedBox(height: AppSizes.paddingMd),
        const Text(
          AppStrings.noMedicalRecords,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        const Text(
          AppStrings.noMedicalRecordsMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        PrimaryButton(
          label: AppStrings.addMedicalRecord,
          icon: Icons.note_add_outlined,
          onPressed: _openAddRecord,
        ),
      ],
    );
  }

  Widget _buildSummaryBody(
    BuildContext context,
    MedicalRecordsController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.only(
        left: AppSizes.paddingMd,
        right: AppSizes.paddingMd,
        top: AppSizes.paddingMd,
        bottom: AppSizes.paddingXl,
      ),
      children: [
        _MedicalInformationCard(profile: controller.medicalProfile),
        const SizedBox(height: AppSizes.paddingSm),
        _SummaryCard(
          icon: Icons.history_edu_outlined,
          title: AppStrings.medicalHistoryLabel,
          value: controller.historyCount,
          unit: AppStrings.recordsCountWord,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.medicalRecordsList,
            arguments: MedicalRecordsListArguments(
              title: AppStrings.medicalHistoryLabel,
              collection: 'history',
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        _SummaryCard(
          icon: Icons.event_note_outlined,
          title: AppStrings.doctorVisitsLabel,
          value: controller.visitCount,
          unit: AppStrings.visitsCountWord,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.medicalRecordsList,
            arguments: MedicalRecordsListArguments(
              title: AppStrings.doctorVisitsLabel,
              collection: 'visits',
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        _SummaryCard(
          icon: Icons.attachment_outlined,
          title: AppStrings.medicalDocumentsLabel,
          value: controller.documentCount,
          unit: AppStrings.documentsCountWord,
          onTap: () => AppUtils.showSnackBar(
            context,
            AppStrings.documentsComingSoon,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        _PrescriptionsCard(
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.prescriptions,
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        PrimaryButton(
          label: AppStrings.addMedicalRecord,
          icon: Icons.note_add_outlined,
          onPressed: _openAddRecord,
        ),
      ],
    );
  }
}

/// Summary card with an icon, count and tappable body.
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final String unit;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSm),
              Text(
                '$value $unit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingXs),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card opening the prescription management screen from the EHR overview.
class _PrescriptionsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PrescriptionsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Row(
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
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              const Expanded(
                child: Text(
                  AppStrings.prescriptionsTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingXs),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card showing the structured medical information with an edit shortcut.
class _MedicalInformationCard extends StatelessWidget {
  final MedicalProfile? profile;

  const _MedicalInformationCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.medicalInformation),
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
                      Icons.health_and_safety_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMd),
                  const Expanded(
                    child: Text(
                      AppStrings.medicalInformation,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.medicalInformation),
                    child: const Text(AppStrings.editMedicalInformation),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMd),
              _InfoRow(
                icon: Icons.bloodtype_outlined,
                label: AppStrings.bloodGroupLabel,
                value: p?.bloodGroup ?? AppStrings.noneLabel,
              ),
              const SizedBox(height: AppSizes.paddingSm),
              _InfoChipsRow(
                label: AppStrings.allergiesLabel,
                values: p?.allergies ?? const [],
              ),
              const SizedBox(height: AppSizes.paddingSm),
              _InfoChipsRow(
                label: AppStrings.medicalConditionsLabel,
                values: p?.conditions ?? const [],
              ),
              const SizedBox(height: AppSizes.paddingSm),
              _InfoRow(
                icon: Icons.medical_services_outlined,
                label: AppStrings.pastSurgeriesLabel,
                value: p == null || p.pastSurgeries.isEmpty
                    ? AppStrings.noneLabel
                    : '${p.pastSurgeries.length}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSizes.paddingSm),
        SizedBox(
          width: 120,
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
    );
  }
}

class _InfoChipsRow extends StatelessWidget {
  final String label;
  final List<String> values;

  const _InfoChipsRow({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.warning_amber_outlined,
            size: 18, color: AppColors.primary),
        const SizedBox(width: AppSizes.paddingSm),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: values.isEmpty
              ? const Text(
                  AppStrings.noneLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                )
              : Wrap(
                  spacing: AppSizes.paddingXs,
                  runSpacing: AppSizes.paddingXs,
                  children: values
                      .map(
                        (v) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingSm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            v,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}