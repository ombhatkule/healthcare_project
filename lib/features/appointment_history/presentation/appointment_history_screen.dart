import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../appointment_booking/models/appointment_model.dart';
import '../../appointment_booking/presentation/providers/appointment_controller.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../appointment_booking/models/booking_arguments.dart';

/// The "Appointments" bottom navigation tab.
///
/// Shows the authenticated user's appointments grouped into Upcoming, Past,
/// and Cancelled. Tapping an appointment opens its details.
class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _loadedForUid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadIfNeeded(BuildContext context, String uid) {
    final controller = context.read<AppointmentController>();
    if (uid != _loadedForUid) {
      _loadedForUid = uid;
      controller.loadAppointments(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final uid = authProvider.currentUid;

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appointmentsTitle)),
        body: const SafeArea(
          child: EmptyStateWidget(
            icon: Icons.event_note_outlined,
            title: AppStrings.appointmentsTitle,
            subtitle: AppStrings.signInRequired,
          ),
        ),
      );
    }

    _loadIfNeeded(context, uid);

    final controller = context.watch<AppointmentController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appointmentsTitle),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: AppStrings.upcomingAppointments),
            Tab(text: AppStrings.pastAppointments),
            Tab(text: AppStrings.cancelledAppointments),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _AppointmentList(
              isLoading: controller.isLoading,
              hasError: controller.hasError,
              errorMessage: controller.errorMessage,
              appointments: controller.upcomingAppointments,
              onRetry: () => controller.loadAppointments(uid),
              emptyTitle: AppStrings.noUpcomingAppointments,
              emptyMessage: AppStrings.noUpcomingMessage,
            ),
            _AppointmentList(
              isLoading: controller.isLoading,
              hasError: controller.hasError,
              errorMessage: controller.errorMessage,
              appointments: controller.pastAppointments,
              onRetry: () => controller.loadAppointments(uid),
              emptyTitle: AppStrings.noPastAppointments,
              emptyMessage: AppStrings.noUpcomingMessage,
            ),
            _AppointmentList(
              isLoading: controller.isLoading,
              hasError: controller.hasError,
              errorMessage: controller.errorMessage,
              appointments: controller.cancelledAppointments,
              onRetry: () => controller.loadAppointments(uid),
              emptyTitle: AppStrings.noCancelledAppointments,
              emptyMessage: AppStrings.noUpcomingMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tab's list of appointments.
class _AppointmentList extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final List<AppointmentModel> appointments;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;

  const _AppointmentList({
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.appointments,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && appointments.isEmpty) {
      return const LoadingWidget(message: 'Loading appointments...');
    }

    if (hasError && appointments.isEmpty) {
      return ErrorStateWidget(
        message: errorMessage ?? AppStrings.appointmentsLoadFailed,
        onRetry: onRetry,
      );
    }

    if (appointments.isEmpty) {
      return _EmptyAppointments(
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRetry(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.paddingSm),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _AppointmentTile(
            appointment: appointment,
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.appointmentDetails,
                arguments: AppointmentDetailsArguments(
                  appointmentId: appointment.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Tap-to-open appointment tile.
class _AppointmentTile extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;

  const _AppointmentTile({
    required this.appointment,
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
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Text(
                  DateTime(appointment.appointmentDate.year,
                          appointment.appointmentDate.month,
                          appointment.appointmentDate.day)
                      .day
                      .toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      appointment.specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_shortDate(appointment.appointmentDate)} · ${appointment.appointmentTime}',
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
              Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Empty state for a tab.
class _EmptyAppointments extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyAppointments({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSizes.paddingMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLg),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.doctorSearch);
              },
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text(AppStrings.findADoctor),
            ),
          ],
        ),
      ),
    );
  }
}