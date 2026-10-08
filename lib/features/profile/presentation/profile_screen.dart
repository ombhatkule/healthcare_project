import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'providers/profile_provider.dart';
import 'widgets/widgets.dart';

/// The User Profile screen.
///
/// Displays the authenticated user's personal and health information from
/// Firestore, plus account settings. Handles loading / error / empty states
/// gracefully and supports editing the profile and signing out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadTriggered) return;
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUid;
    if (uid != null && uid.isNotEmpty) {
      _loadTriggered = true;
      // ProfileProvider notifies its listeners synchronously, so starting the
      // read straight from didChangeDependencies would mark widgets dirty while
      // Flutter is still building. Defer it to just after the current frame.
      final provider = context.read<ProfileProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) provider.loadProfile(uid);
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await AppUtils.showConfirmDialog(
      context,
      title: AppStrings.logoutConfirmTitle,
      content: AppStrings.logoutConfirmMessage,
      confirmText: AppStrings.logoutConfirmTitle,
      cancelText: AppStrings.logoutMaybeLater,
    );
    if (!confirmed || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.logout();
    if (!context.mounted) return;

    if (success) {
      AppUtils.showSnackBar(context, AppStrings.logoutSuccess);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      AppUtils.showSnackBar(
        context,
        authProvider.errorMessage ?? AppStrings.error,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();
    final profile = profileProvider.profile;

    final displayName = _resolveName(profile, authProvider);
    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : authProvider.userEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _buildBody(profileProvider, authProvider, displayName, email),
      ),
    );
  }

  String _resolveName(UserProfile? profile, AuthProvider authProvider) {
    if (profile != null && profile.fullName.isNotEmpty) {
      return profile.fullName;
    }
    return authProvider.displayName ?? 'Patient';
  }

  Widget _buildBody(
    ProfileProvider provider,
    AuthProvider authProvider,
    String displayName,
    String? email,
  ) {
    if (provider.isLoading) {
      return const LoadingWidget(message: AppStrings.loading);
    }
    if (provider.hasError && provider.profile == null) {
      return ErrorStateWidget(
        message: provider.errorMessage ?? AppStrings.profileLoadFailed,
        onRetry: () {
          final uid = authProvider.currentUid;
          if (uid != null) {
            provider.loadProfile(uid);
          }
        },
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        final uid = authProvider.currentUid;
        if (uid != null) {
          await provider.loadProfile(uid);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.paddingMd,
          AppSizes.paddingLg,
          AppSizes.paddingMd,
          AppSizes.paddingLg,
        ),
        children: [
          ProfileHeader(
            imageUrl: provider.profile?.profileImageUrl,
            displayName: displayName,
            email: email,
            onEdit: () => _openEdit(),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          ProfileSection(
            title: AppStrings.personalInformation,
            icon: Icons.person_outline,
            children: [
              ProfileInfoTile(
                icon: Icons.badge_outlined,
                label: AppStrings.fullName,
                value: displayName,
              ),
              ProfileInfoTile(
                icon: Icons.email_outlined,
                label: AppStrings.email,
                value: email,
              ),
              ProfileInfoTile(
                icon: Icons.phone_outlined,
                label: AppStrings.phoneNumber,
                value: provider.profile?.phoneNumber,
              ),
              ProfileInfoTile(
                icon: Icons.cake_outlined,
                label: AppStrings.dateOfBirth,
                value: provider.profile?.dateOfBirth != null
                    ? AppUtils.formatDate(provider.profile!.dateOfBirth!)
                    : null,
              ),
              ProfileInfoTile(
                icon: Icons.wc_outlined,
                label: AppStrings.gender,
                value: provider.profile?.gender,
              ),
            ],
          ),
          ProfileSection(
            title: AppStrings.healthInformation,
            icon: Icons.favorite_outline,
            children: [
              HealthInfoTile(
                label: AppStrings.height,
                value: provider.profile?.height?.toString(),
                unit: AppStrings.heightUnit,
              ),
              HealthInfoTile(
                label: AppStrings.weight,
                value: provider.profile?.weight?.toString(),
                unit: AppStrings.weightUnit,
              ),
              HealthInfoTile(
                label: AppStrings.bloodGroup,
                value: provider.profile?.bloodGroup,
              ),
              HealthInfoTile(
                label: AppStrings.emergencyContact,
                value: provider.profile?.emergencyContact,
              ),
              HealthInfoTile(
                label: AppStrings.allergies,
                value: provider.profile?.allergies,
              ),
            ],
          ),
          _buildAccountSettings(),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return ProfileSection(
      title: AppStrings.accountSettings,
      icon: Icons.settings_outlined,
      children: [
        SettingsTile(
          icon: Icons.edit_outlined,
          title: AppStrings.editProfile,
          onTap: () => _openEdit(),
        ),
        SettingsTile(
          icon: Icons.notifications_outlined,
          title: AppStrings.notificationSettings,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
        ),
        SettingsTile(
          icon: Icons.lock_outline,
          title: AppStrings.privacy,
          onTap: () => _openPlaceholder(AppStrings.privacy, AppStrings.privacyMessage),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          title: AppStrings.aboutApplication,
          onTap: () => _openPlaceholder(
            AppStrings.aboutApplication,
            AppStrings.aboutApplicationMessage,
          ),
        ),
        SettingsTile(
          icon: Icons.developer_mode_outlined,
          title: 'Developer Settings',
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
        ),
        const Divider(height: AppSizes.paddingLg),
        SettingsTile(
          icon: Icons.logout,
          title: AppStrings.logout,
          color: AppColors.error,
          trailing: const SizedBox.shrink(),
          onTap: () => _handleLogout(context),
        ),
      ],
    );
  }

  void _openEdit() {
    Navigator.of(context).pushNamed(AppRoutes.editProfile);
  }

  void _openPlaceholder(String title, String message) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceholderScreen(
          title: title,
          icon: Icons.info_outline,
          message: message,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
