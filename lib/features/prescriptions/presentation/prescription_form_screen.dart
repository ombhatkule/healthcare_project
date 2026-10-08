import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../doctor_recommendation/models/models.dart';
import '../../doctor_recommendation/services/services.dart';
import '../models/models.dart';
import 'providers/prescriptions_controller.dart';

/// Standard prescription frequency options (as entered by the user).
const List<String> kPrescriptionFrequencies = [
  AppStrings.frequencyOnceDaily,
  AppStrings.frequencyTwiceDaily,
  AppStrings.frequencyThreeTimesDaily,
  AppStrings.frequencyEvery6Hours,
  AppStrings.frequencyEvery8Hours,
  AppStrings.frequencyAsNeeded,
  AppStrings.frequencyOther,
];

/// Add / edit form for a prescription.
///
/// Used for both creating a new prescription and updating an existing one (the
/// form always updates the same document id — it never creates a duplicate on
/// edit). Drugs are entered as structured medicines via [MedicineFormScreen].
class PrescriptionFormScreen extends StatefulWidget {
  final PrescriptionFormArguments? args;

  const PrescriptionFormScreen({super.key, this.args});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _doctorController;
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  late bool _isEditing;
  DateTime _date = DateTime.now();
  PrescriptionStatus _status = PrescriptionStatus.active;
  List<Medicine> _medicines = [];

  String get _doctorId => widget.args?.doctorId ?? '';

  @override
  void initState() {
    super.initState();
    final prescription = widget.args?.prescription;
    _isEditing = prescription != null;
    if (prescription != null) {
      _doctorController =
          TextEditingController(text: prescription.doctorName);
      _specialtyController.text = prescription.doctorSpecialty;
      _hospitalController.text = prescription.hospitalName;
      _diagnosisController.text = prescription.diagnosisOrCondition;
      _notesController.text = prescription.notes;
      _date = prescription.prescriptionDate;
      _status = prescription.status;
      _medicines = List.of(prescription.medicines);
    } else {
      _doctorController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? _date : now,
      firstDate: DateTime(now.year - 80),
      lastDate: now,
      helpText: AppStrings.prescriptionDateLabel,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickDoctor() async {
    final service = context.read<DoctorRecommendationService>();
    final selected = await showModalBottomSheet<Doctor>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DoctorPickerSheet(service: service),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _doctorController.text = selected.name;
      _specialtyController.text = selected.specialty;
      _hospitalController.text = selected.hospital;
    });
  }

  Future<void> _addMedicine() async {
    final added = await Navigator.of(context).pushNamed(
      AppRoutes.medicineForm,
      arguments: const MedicineFormArguments(),
    );
    if (added != null && mounted) {
      setState(() => _medicines = [..._medicines, added as Medicine]);
    }
  }

  Future<void> _editMedicine(Medicine medicine) async {
    final updated = await Navigator.of(context).pushNamed(
      AppRoutes.medicineForm,
      arguments: MedicineFormArguments(medicine: medicine),
    );
    if (updated != null && mounted) {
      setState(() {
        _medicines = [
          for (final m in _medicines)
            if (m.id == medicine.id) updated as Medicine else m,
        ];
      });
    }
  }

  void _removeMedicine(String medicineId) {
    setState(() {
      _medicines = _medicines.where((m) => m.id != medicineId).toList();
    });
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.addPrescriptionSignIn,
          isError: true);
      return;
    }

    final controller = context.read<PrescriptionsController>();
    final prescription = Prescription(
      id: widget.args?.prescription?.id ?? '',
      userId: uid,
      doctorId: _doctorId,
      doctorName: _doctorController.text.trim(),
      doctorSpecialty: _specialtyController.text.trim(),
      hospitalName: _hospitalController.text.trim(),
      appointmentId: widget.args?.appointmentId ?? '',
      prescriptionDate: _date,
      diagnosisOrCondition: _diagnosisController.text.trim(),
      medicines: _medicines,
      notes: _notesController.text.trim(),
      status: _status,
      createdAt: widget.args?.prescription?.createdAt,
      updatedAt: DateTime.now(),
    );

    final success = _isEditing
        ? await controller.updatePrescription(prescription)
        : await controller.createPrescription(prescription);
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(
        context,
        _isEditing ? AppStrings.prescriptionUpdated : AppStrings.prescriptionSaved,
      );
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(
        context,
        controller.errorMessage ?? AppStrings.prescriptionSaveFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PrescriptionsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editPrescription : AppStrings.addPrescription,
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
                  key: const Key('doctorNameField'),
                  controller: _doctorController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.doctorLabel,
                    hintText: AppStrings.selectDoctorLabel,
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppStrings.doctorNameRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingSm),
                OutlinedButton.icon(
                  onPressed: _pickDoctor,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text(AppStrings.pickDoctorLabel),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _diagnosisController,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.diagnosisOrConditionLabel,
                    prefixIcon: Icons.health_and_safety_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: InputDecorator(
                    decoration: AppDecorations.inputDecoration(
                      labelText: AppStrings.prescriptionDateLabel,
                      prefixIcon: Icons.calendar_today_outlined,
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      AppUtils.formatDate(_date),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                DropdownButtonFormField<PrescriptionStatus>(
                  value: _status,
                  isExpanded: true,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.statusLabel,
                    prefixIcon: Icons.track_changes_outlined,
                  ),
                  items: PrescriptionStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.paddingLg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${AppStrings.medicinesLabel} (${_medicines.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addMedicine,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(AppStrings.addMedicine),
                    ),
                  ],
                ),
                if (_medicines.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingMd),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Text(
                      AppStrings.noMedicineSelected,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ..._medicines.map(
                    (m) => _EditableMedicineTile(
                      medicine: m,
                      onEdit: () => _editMedicine(m),
                      onDelete: () => _removeMedicine(m.id),
                    ),
                  ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _hospitalController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.hospitalLabel,
                    prefixIcon: Icons.local_hospital_outlined,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  controller: _specialtyController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.specialtyLabel,
                    prefixIcon: Icons.medical_information_outlined,
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
                  key: const Key('prescriptionSubmitButton'),
                  label: _isEditing
                      ? AppStrings.savePrescription
                      : AppStrings.addPrescription,
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

/// Editable medicine tile shown in the form before saving.
class _EditableMedicineTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EditableMedicineTile({
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

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
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine.medicineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: AppStrings.editMedicine,
                icon: const Icon(Icons.edit_outlined, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: AppStrings.deletePrescriptionConfirm,
                icon: const Icon(Icons.delete_outline, size: 18,
                    color: AppColors.error),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (medicine.dosage.isNotEmpty || medicine.frequency.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              [
                if (medicine.dosage.isNotEmpty) medicine.dosage,
                if (medicine.frequency.isNotEmpty) medicine.frequency,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet that searches the doctor catalog and returns a selection.
class _DoctorPickerSheet extends StatefulWidget {
  final DoctorRecommendationService service;

  const _DoctorPickerSheet({required this.service});

  @override
  State<_DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends State<_DoctorPickerSheet> {
  List<Doctor> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await widget.service.searchDoctors(query: query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.paddingMd,
        right: AppSizes.paddingMd,
        top: AppSizes.paddingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.pickDoctorLabel,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          TextField(
            onChanged: _search,
            textInputAction: TextInputAction.search,
            decoration: AppDecorations.inputDecoration(
              labelText: AppStrings.searchDoctorHint,
              prefixIcon: Icons.search,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          Flexible(
            child: _loading && _results.isEmpty
                ? const SizedBox(
                    height: 120,
                    child: LoadingWidget(),
                  )
                : _results.isEmpty
                    ? const SizedBox(
                        height: 120,
                        child: Center(
                            child: Text(AppStrings.noDoctorsMatchFound)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSizes.paddingSm),
                        itemBuilder: (context, index) {
                          final doctor = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                            title: Text(doctor.name),
                            subtitle: Text(
                              '${doctor.specialty} · ${doctor.hospital}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => Navigator.of(context).pop(doctor),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}