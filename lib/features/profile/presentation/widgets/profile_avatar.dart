import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

/// Displays the user's profile photo if available, otherwise a clean default
/// avatar containing the user's initial.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withAlpha(30),
      foregroundImage: (_validUrl(imageUrl)) ? NetworkImage(imageUrl!) : null,
      child: _validUrl(imageUrl)
          ? null
          : Text(
              _initial(name),
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
    );
  }

  bool _validUrl(String? url) =>
      url != null && url.isNotEmpty && (url.startsWith('http') || url.startsWith('https'));

  String _initial(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
