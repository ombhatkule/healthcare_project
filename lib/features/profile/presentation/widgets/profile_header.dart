import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import 'profile_avatar.dart';

/// The header shown at the top of the profile screen.
///
/// Displays the profile photo (or default avatar), the user's display name,
/// email, and an "Edit Profile" action.
class ProfileHeader extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final String? email;
  final VoidCallback? onEdit;
  final bool showEdit;

  const ProfileHeader({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.email,
    this.onEdit,
    this.showEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileAvatar(imageUrl: imageUrl, name: displayName, radius: 44),
        const SizedBox(height: AppSizes.paddingMd),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.paddingXs),
          Text(
            email!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (showEdit) ...[
          const SizedBox(height: AppSizes.paddingSm),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(AppStrings.editProfile),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
