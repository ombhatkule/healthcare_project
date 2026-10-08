import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_screen.dart';

/// Placeholder for the Notifications module.
/// Real push/local notifications land in a later phase.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Notifications',
      icon: Icons.notifications_outlined,
      message:
          'Stay up to date with appointment reminders and health alerts.',
      color: Color(0xFF3B82F6),
    );
  }
}
