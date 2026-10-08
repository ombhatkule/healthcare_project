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

/// A category-filtered list of medical records ("Medical History" or
/// "Doctor Visits"). Tapping a record opens its details; the app bar offers a
/// shortcut to add a record in the relevant category.
class MedicalRecordsListScreen extends StatefulWidget {
  final MedicalRecordsListArguments? args;

  const MedicalRecordsListScreen({super.key, this.args});

  @override
  State<MedicalRecordsListScreen> createState() =>
      _MedicalRecordsListScreenState();
}

class _MedicalRecordsListScreenState extends State<MedicalRecordsListScreen> {
  bool _loaded = false;

  bool get _isVisits => widget.args?.collection == 'visits';

  List<MedicalRecord> _recordsFor(MedicalRecordsController controller) {
    return _isVisits ? controller.visitRecords : controller.historyRecords;
  }

  void _ensureLoaded(BuildContext context, String uid) {
    if (_loaded) return;
    _loaded = true;
    context.read<MedicalRecordsController>().loadAll(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.args?.title ?? AppStrings.medicalRecordsTitle)),
        body: const SafeArea(
          child: EmptyStateWidget(
            icon: Icons.folder_open_outlined,
            title: AppStrings.noMedicalRecords,
            subtitle: AppStrings.signInToAccessRecords,
          ),
        ),
      );
    }

    _ensureLoaded(context, uid);
    final controller = context.watch<MedicalRecordsController>();
    final records = _recordsFor(controller);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.title ?? AppStrings.medicalRecordsTitle),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              AppRoutes.medicalRecordForm,
              arguments: MedicalRecordFormArguments(
                initialCategory: _isVisits
                    ? MedicalRecordCategory.doctorVisit
                    : MedicalRecordCategory.medicalHistory,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(AppStrings.addMedicalRecord),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading && records.isEmpty
            ? const LoadingWidget(message: AppStrings.recordsLoadMessage)
            : controller.hasError && records.isEmpty
                ? ErrorStateWidget(
                    message:
                        controller.errorMessage ?? AppStrings.recordsLoadFailed,
                    onRetry: () => controller.loadAll(uid),
                  )
                : records.isEmpty
                    ? _EmptyRecords(
                        onAdd: () => Navigator.of(context).pushNamed(
                          AppRoutes.medicalRecordForm,
                          arguments: MedicalRecordFormArguments(
                            initialCategory: _isVisits
                                ? MedicalRecordCategory.doctorVisit
                                : MedicalRecordCategory.medicalHistory,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.loadAll(uid),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          itemCount: records.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSizes.paddingSm),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return _RecordTile(
                              record: record,
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.medicalRecordDetails,
                                arguments: MedicalRecordDetailsArguments(
                                  recordId: record.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

/// Tappable medical record tile.
class _RecordTile extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onTap;

  const _RecordTile({required this.record, required this.onTap});

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
                child: Icon(
                  medicalRecordCategoryIcon(record.category),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.doctorName.isNotEmpty
                          ? record.doctorName
                          : record.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: record.doctorName.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: record.doctorName.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.category.label} · ${AppUtils.formatDate(record.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.paddingSm),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state for a filtered record list.
class _EmptyRecords extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRecords({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSizes.paddingMd),
            const Text(
              AppStrings.noRecordsInSection,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            const Text(
              AppStrings.noMedicalRecordsMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: const Text(AppStrings.addMedicalRecord),
            ),
          ],
        ),
      ),
    );
  }
}