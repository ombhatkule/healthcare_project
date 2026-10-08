import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/models.dart';
import 'providers/medical_records_controller.dart';

/// Editor for the user's structured medical information.
///
/// Blood group, allergies, existing conditions, family history and past
/// surgeries. All fields are optional. Uses a chip interface for allergies /
/// conditions and a dedicated form for past surgeries.
class MedicalInformationScreen extends StatefulWidget {
  const MedicalInformationScreen({super.key});

  @override
  State<MedicalInformationScreen> createState() =>
      _MedicalInformationScreenState();
}

class _MedicalInformationScreenState extends State<MedicalInformationScreen> {
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    AppStrings.bloodGroupUnknown,
  ];

  final _familyHistoryController = TextEditingController();
  final _allergyInputController = TextEditingController();
  final _conditionInputController = TextEditingController();

  String? _bloodGroup;
  List<String> _allergies = [];
  List<String> _conditions = [];
  List<PastSurgery> _surgeries = [];
  bool _initialized = false;

  @override
  void dispose() {
    _familyHistoryController.dispose();
    _allergyInputController.dispose();
    _conditionInputController.dispose();
    super.dispose();
  }

  void _initFromController(MedicalRecordsController controller) {
    if (_initialized) return;
    _initialized = true;
    final profile = controller.medicalProfile;
    _bloodGroup = profile?.bloodGroup;
    _allergies = List.of(profile?.allergies ?? const []);
    _conditions = List.of(profile?.conditions ?? const []);
    _surgeries = List.of(profile?.pastSurgeries ?? const []);
    _familyHistoryController.text = profile?.familyHistory ?? '';
  }

  Future<void> _addAllergy() async {
    final value = _allergyInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_allergies.contains(value)) {
        _allergies = [..._allergies, value];
      }
      _allergyInputController.clear();
    });
  }

  Future<void> _addCondition() async {
    final value = _conditionInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_conditions.contains(value)) {
        _conditions = [..._conditions, value];
      }
      _conditionInputController.clear();
    });
  }

  Future<void> _openSurgeryForm({PastSurgery? existing, int? index}) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.surgeryForm,
      arguments: SurgeryFormArguments(surgery: existing),
    );
    if (result is PastSurgery && mounted) {
      setState(() {
        if (index == null) {
          _surgeries = [..._surgeries, result];
        } else {
          _surgeries = List.of(_surgeries)..[index] = result;
        }
      });
    }
  }

  Future<void> _confirmDeleteSurgery(int index) async {
    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: AppStrings.deleteRecordTitle,
      content: 'Delete "${_surgeries[index].name}" from past surgeries?',
      confirmText: AppStrings.deleteRecordConfirm,
    );
    if (confirmed && mounted) {
      setState(() {
        _surgeries = List.of(_surgeries)..removeAt(index);
      });
    }
  }

  Future<void> _handleSave() async {
    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.addMedicalRecordSignIn,
          isError: true);
      return;
    }

    final controller = context.read<MedicalRecordsController>();
    final profile = MedicalProfile(
      userId: uid,
      bloodGroup: _bloodGroup == AppStrings.bloodGroupUnknown
          ? AppStrings.bloodGroupUnknown
          : _bloodGroup,
      allergies: _allergies,
      conditions: _conditions,
      familyHistory: _familyHistoryController.text.trim().isEmpty
          ? null
          : _familyHistoryController.text.trim(),
      pastSurgeries: _surgeries,
    );

    final success = await controller.saveMedicalProfile(profile);
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(context, AppStrings.medicalInformationSaved);
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(
        context,
        controller.errorMessage ?? AppStrings.profileSaveFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MedicalRecordsController>();
    _initFromController(controller);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.medicalInformation)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(AppStrings.bloodGroupLabel),
              const SizedBox(height: AppSizes.paddingSm),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                decoration: AppDecorations.inputDecoration(
                  labelText: AppStrings.bloodGroupLabel,
                  prefixIcon: Icons.bloodtype_outlined,
                ),
                items: _bloodGroups
                    .map((bg) =>
                        DropdownMenuItem(value: bg, child: Text(bg)))
                    .toList(),
                onChanged: (value) => setState(() => _bloodGroup = value),
              ),
              const SizedBox(height: AppSizes.paddingLg),

              _sectionTitle(AppStrings.allergiesLabel),
              const SizedBox(height: AppSizes.paddingSm),
              _ChipEditor(
                hint: AppStrings.addItemHint,
                addButtonLabel: AppStrings.addAllergy,
                chips: _allergies,
                inputController: _allergyInputController,
                onAdd: _addAllergy,
                onDelete: (index) => setState(
                  () => _allergies = List.of(_allergies)..removeAt(index),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),

              _sectionTitle(AppStrings.medicalConditionsLabel),
              const SizedBox(height: AppSizes.paddingSm),
              _ChipEditor(
                hint: AppStrings.addItemHint,
                addButtonLabel: AppStrings.addCondition,
                chips: _conditions,
                inputController: _conditionInputController,
                onAdd: _addCondition,
                onDelete: (index) => setState(
                  () => _conditions = List.of(_conditions)..removeAt(index),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),

              _sectionTitle(AppStrings.pastSurgeriesLabel),
              const SizedBox(height: AppSizes.paddingSm),
              if (_surgeries.isEmpty)
                const Text(
                  AppStrings.noneLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ..._surgeries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final surgery = entry.value;
                  return _SurgeryTile(
                    surgery: surgery,
                    onEdit: () => _openSurgeryForm(
                      existing: surgery,
                      index: index,
                    ),
                    onDelete: () => _confirmDeleteSurgery(index),
                  );
                }),
              const SizedBox(height: AppSizes.paddingSm),
              OutlinedButton.icon(
                onPressed: () => _openSurgeryForm(),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addSurgery),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    AppSizes.buttonHeightSm,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),

              _sectionTitle(AppStrings.familyHistoryLabel),
              const SizedBox(height: AppSizes.paddingSm),
              TextFormField(
                controller: _familyHistoryController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: AppDecorations.inputDecoration(
                  labelText: AppStrings.familyHistoryLabel,
                  hintText: AppStrings.familyHistoryHint,
                  prefixIcon: Icons.family_restroom_outlined,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLg),

              PrimaryButton(
                label: AppStrings.save,
                icon: Icons.save_outlined,
                isLoading: controller.isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: AppSizes.paddingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// Chip editor used for the allergies and conditions lists.
class _ChipEditor extends StatelessWidget {
  final String hint;
  final String addButtonLabel;
  final List<String> chips;
  final TextEditingController inputController;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  const _ChipEditor({
    required this.hint,
    required this.addButtonLabel,
    required this.chips,
    required this.inputController,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingSm),
            child: Wrap(
              spacing: AppSizes.paddingXs,
              runSpacing: AppSizes.paddingXs,
              children: chips.asMap().entries.map((entry) {
                return InputChip(
                  label: Text(entry.value),
                  onDeleted: () => onDelete(entry.key),
                  deleteIconColor: AppColors.textSecondary,
                  backgroundColor: AppColors.surfaceVariant,
                );
              }).toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: inputController,
                textInputAction: TextInputAction.done,
                decoration: AppDecorations.inputDecoration(
                  labelText: hint,
                  prefixIcon: Icons.edit_outlined,
                ),
                onFieldSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: AppSizes.paddingSm),
            IconButton.filledTonal(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: addButtonLabel,
            ),
          ],
        ),
      ],
    );
  }
}

/// A single past-surgery entry with edit/delete actions.
class _SurgeryTile extends StatelessWidget {
  final PastSurgery surgery;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SurgeryTile({
    required this.surgery,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingSm),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.medical_services_outlined,
                color: AppColors.primary, size: 20),
            const SizedBox(width: AppSizes.paddingSm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surgery.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      surgery.year != null
                          ? '${surgery.year}'
                          : (surgery.hospital.isNotEmpty
                              ? surgery.hospital
                              : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.primary),
              tooltip: AppStrings.editRecord,
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.error),
              tooltip: AppStrings.delete,
            ),
          ],
        ),
      ),
    );
  }
}