import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/mock_dashboard_data.dart';
import 'widgets/widgets.dart';

/// The Home dashboard tab.
///
/// Displays a professional health dashboard with:
///  - a welcome header using the authenticated user's name
///  - quick actions
///  - healthcare services
///  - appointment summary (mock data)
///  - health summary (mock data)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final displayName = authProvider.displayName ?? 'Patient';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => _navigate(context, AppRoutes.profile),
          ),
        ],
      ),
      // Floating AI Assistant shortcut; sits above the shell's bottom
      // navigation and opens the same screen as the welcome-card action.
      floatingActionButton: FloatingActionButton(
        key: const Key('ai_assistant_fab'),
        heroTag: 'ai_assistant_fab',
        tooltip: AppStrings.aiFloatingButtonTooltip,
        onPressed: () => _navigate(context, AppRoutes.aiAssistant),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.smart_toy_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: ListView(
          // Extra bottom padding so the last section can scroll clear of the
          // floating AI button instead of hiding underneath it.
          padding: const EdgeInsets.only(bottom: AppSizes.paddingXl * 3),
          children: [
            // Welcome section
            DashboardHeader(
              displayName: displayName,
              onAiAssist: () => _navigate(context, AppRoutes.aiAssistant),
            ),

            // Quick actions
            const DashboardSectionTitle(title: 'Quick Actions'),
            _buildQuickActions(context),

            const SizedBox(height: AppSizes.paddingMd),

            // Healthcare services
            const DashboardSectionTitle(title: 'Healthcare Services'),
            _buildHealthcareServices(context),

            const SizedBox(height: AppSizes.paddingMd),

            // Appointment summary
            const DashboardSectionTitle(title: 'Upcoming Appointment'),
            _buildAppointmentSummary(context),

            const SizedBox(height: AppSizes.paddingMd),

            // Health summary
            const DashboardSectionTitle(title: 'Health Summary'),
            HealthSummaryCard(summary: MockDashboardData.healthSummary),

            const SizedBox(height: AppSizes.paddingLg),

            // Disclaimer
            _buildDisclaimerBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickActionItem(
        icon: Icons.analytics_outlined,
        title: 'Disease Prediction',
        description: 'AI-based symptom assessment',
        color: const Color(0xFF5C6BC0),
        route: AppRoutes.diseasePrediction,
      ),
      QuickActionItem(
        icon: Icons.person_search_outlined,
        title: 'Find a Doctor',
        description: 'Search qualified professionals',
        color: const Color(0xFF10B981),
        route: AppRoutes.doctorSearch,
      ),
      QuickActionItem(
        icon: Icons.event_available_outlined,
        title: 'Book Appointment',
        description: 'Schedule a visit',
        color: const Color(0xFFF59E0B),
        // Booking requires a selected doctor, so route users through
        // doctor search first.
        route: AppRoutes.doctorSearch,
      ),
      QuickActionItem(
        icon: Icons.smart_toy_outlined,
        title: 'AI Assistant',
        description: 'Chat for health guidance',
        color: const Color(0xFF3B82F6),
        route: AppRoutes.aiAssistant,
      ),
    ];

    return SizedBox(
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.paddingMd),
        itemBuilder: (context, index) {
          final action = actions[index];
          return SizedBox(
            width: 150,
            child: QuickActionCard(
              icon: action.icon,
              title: action.title,
              description: action.description,
              color: action.color,
              onTap: () => _navigate(context, action.route),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthcareServices(BuildContext context) {
    final services = [
      ServiceItem(
        icon: Icons.medical_information_outlined,
        title: 'Medical Records',
        color: AppColors.primary,
        route: AppRoutes.medicalRecords,
      ),
      ServiceItem(
        icon: Icons.receipt_long_outlined,
        title: 'Prescriptions',
        color: const Color(0xFF5C6BC0),
        route: AppRoutes.prescriptions,
      ),
      ServiceItem(
        icon: Icons.restaurant_menu_outlined,
        title: 'Diet',
        color: const Color(0xFFEF4444),
        route: AppRoutes.diet,
      ),
      ServiceItem(
        icon: Icons.fitness_center_outlined,
        title: 'Exercise',
        color: const Color(0xFF26A69A),
        route: AppRoutes.exercise,
      ),
      ServiceItem(
        icon: Icons.local_hospital_outlined,
        title: 'Hospitals',
        color: const Color(0xFF7E57C2),
        route: AppRoutes.hospitalLocator,
      ),
      ServiceItem(
        icon: Icons.local_pharmacy_outlined,
        title: 'Pharmacies',
        color: const Color(0xFFFF7043),
        route: AppRoutes.pharmacyLocator,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.gridCrossAxisSpacing,
        mainAxisSpacing: AppSizes.gridMainAxisSpacing,
        childAspectRatio: 1.1,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return HealthcareServiceCard(
          icon: service.icon,
          title: service.title,
          color: service.color,
          onTap: () => _navigate(context, service.route),
        );
      },
    );
  }

  Widget _buildAppointmentSummary(BuildContext context) {
    final appointment = MockDashboardData.upcomingAppointment;

    if (appointment == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        child: EmptyAppointmentCard(
          onBook: () => _navigate(context, AppRoutes.doctorSearch),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      child: AppointmentCard(
        appointment: appointment,
        onTap: () => _navigate(context, AppRoutes.appointmentHistory),
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Text(
              AppStrings.disclaimer,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Holds the display data for a quick action card.
class QuickActionItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;

  const QuickActionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
  });
}

/// Holds the display data for a healthcare service card.
class ServiceItem {
  final IconData icon;
  final String title;
  final Color color;
  final String route;

  const ServiceItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.route,
  });
}
