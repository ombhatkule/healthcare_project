import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'profile_validator.dart';
import 'providers/profile_provider.dart';

/// Edit Profile screen allowing the user to update personal and health
/// information. Persists changes to Firestore via [ProfileProvider].
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _allergiesController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;
  String? _bloodGroup;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _emergencyContactController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _initFromProvider(ProfileProvider provider, AuthProvider authProvider) {
    if (_initialized) return;
    _initialized = true;

    final profile = provider.profile;
    final authName = authProvider.displayName;
    final authEmail = authProvider.userEmail;

    _nameController.text = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : (authName ?? '');
    _phoneController.text = profile?.phoneNumber ?? '';
    _dateOfBirth = profile?.dateOfBirth;
    _gender = profile?.gender;
    _heightController.text = profile?.height != null
        ? _formatNumber(profile!.height!)
        : '';
    _weightController.text = profile?.weight != null
        ? _formatNumber(profile!.weight!)
        : '';
    _bloodGroup = profile?.bloodGroup;
    _emergencyContactController.text = profile?.emergencyContact ?? '';
    _allergiesController.text = profile?.allergies ?? '';
    _emailForSave = authEmail;
  }

  String? _emailForSave;

  String _formatNumber(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: AppStrings.dateOfBirth,
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid ?? authProvider.currentUid;

    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.error, isError: true);
      return;
    }

    final email = _emailForSave ?? profileProvider.profile?.email ?? '';

    final updated = UserProfile(
      uid: uid,
      fullName: _nameController.text.trim(),
      email: email,
      phoneNumber: _trimOrNull(_phoneController.text),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      height: _parseNum(_heightController.text),
      weight: _parseNum(_weightController.text),
      bloodGroup: _bloodGroup,
      emergencyContact: _trimOrNull(_emergencyContactController.text),
      allergies: _trimOrNull(_allergiesController.text),
      profileImageUrl: profileProvider.profile?.profileImageUrl,
      createdAt: profileProvider.profile?.createdAt,
      updatedAt: DateTime.now(),
    );

    final exists = profileProvider.profile != null;
    final success = exists
        ? await profileProvider.updateProfile(updated)
        : await profileProvider.createProfile(updated);

    if (!mounted) return;

    if (success) {
      AppUtils.showSnackBar(
        context,
        exists ? AppStrings.profileUpdated : AppStrings.profileSaved,
      );
      Navigator.of(context).pop();
    } else {
      AppUtils.showSnackBar(
        context,
        profileProvider.errorMessage ?? AppStrings.error,
        isError: true,
      );
    }
  }

  double? _parseNum(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    _initFromProvider(profileProvider, authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: SafeArea(
        child: profileProvider.isLoading
            ? const LoadingWidget(message: AppStrings.loading)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle(AppStrings.personalInformation),
                      const SizedBox(height: AppSizes.paddingSm),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: AppDecorations.inputDecoration(
                          labelText: AppStrings.fullName,
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: ProfileValidator.validateName,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: AppDecorations.inputDecoration(
                          labelText: AppStrings.phoneNumber,
                          prefixIcon: Icons.phone_outlined,
                        ),
                        validator: ProfileValidator.validatePhone,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                        child: InputDecorator(
                          decoration: AppDecorations.inputDecoration(
                            labelText: AppStrings.dateOfBirth,
                            prefixIcon: Icons.cake_outlined,
                            suffixIcon: const Icon(Icons.calendar_today, size: 18),
                          ),
                          child: Text(
                            _dateOfBirth != null
                                ? AppUtils.formatDate(_dateOfBirth!)
                                : '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: AppDecorations.inputDecoration(
                          labelText: AppStrings.gender,
                          prefixIcon: Icons.wc_outlined,
                        ),
                        items: _genders
                            .map((g) => DropdownMenuItem(
                                value: g, child: Text(g)))
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value),
                        validator: (value) => null,
                      ),
                      const SizedBox(height: AppSizes.paddingLg),
                      _sectionTitle(AppStrings.healthInformation),
                      const SizedBox(height: AppSizes.paddingSm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: AppDecorations.inputDecoration(
                                labelText: AppStrings.height,
                                hintText: AppStrings.heightUnit,
                                prefixIcon: Icons.straighten,
                              ),
                              validator: ProfileValidator.validateHeight,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingMd),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: AppDecorations.inputDecoration(
                                labelText: AppStrings.weight,
                                hintText: AppStrings.weightUnit,
                                prefixIcon: Icons.monitor_weight_outlined,
                              ),
                              validator: ProfileValidator.validateWeight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      DropdownButtonFormField<String>(
                        value: _bloodGroup,
                        decoration: AppDecorations.inputDecoration(
                          labelText: AppStrings.bloodGroup,
                          prefixIcon: Icons.bloodtype_outlined,
                        ),
                        items: _bloodGroups
                            .map((b) => DropdownMenuItem(
                                value: b, child: Text(b)))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _bloodGroup = value),
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      TextFormField(
                        controller: _emergencyContactController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: AppDecorations.inputDecoration(
                          labelText: AppStrings.emergencyContact,
                          prefixIcon: Icons.emergency_outlined,
                        ),
                        validator: ProfileValidator.validateEmergencyContact,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      TextFormField(
                        controller: _allergiesController,
                        textInputAction: TextInputAction.done,
                        maxLines: 2,
                        decoration: AppDecorations.inputDecoration(
                          labelText: AppStrings.allergies,
                          hintText: AppStrings.none,
                          prefixIcon: Icons.warning_amber_outlined,
                        ),
                        onFieldSubmitted: (_) => _handleSave(),
                      ),
                      const SizedBox(height: AppSizes.paddingLg),
                      PrimaryButton(
                        label: AppStrings.save,
                        isLoading: profileProvider.isSaving,
                        icon: Icons.save_outlined,
                        onPressed: _handleSave,
                      ),
                      const SizedBox(height: AppSizes.paddingMd),
                      OutlinedButton(
                        onPressed: profileProvider.isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
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
