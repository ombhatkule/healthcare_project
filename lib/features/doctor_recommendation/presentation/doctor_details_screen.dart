import 'package:flutter/material.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../appointment_booking/models/booking_arguments.dart';
import '../models/navigation_args.dart';

/// Shows full details for a single doctor.
///
/// Args: [DoctorDetailsArgs] carrying the [Doctor] to display. The "Book
/// Appointment" CTA launches the appointment booking flow with this doctor.
class DoctorDetailsScreen extends StatelessWidget {
  final DoctorDetailsArgs? args;

  const DoctorDetailsScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final doctor = args?.doctor;

    if (doctor == null) {
      return const Scaffold(
        body: EmptyStateWidget(
          icon: Icons.person_off_outlined,
          title: AppStrings.doctorNotFound,
          subtitle: AppStrings.doctorNotFoundMessage,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.doctorDetailsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            AppColors.primaryLight.withValues(alpha: 0.2),
                        child: Text(
                          doctor.initials,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingXs),
                            Text(
                              doctor.specialty,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            _InfoRow(
              icon: Icons.school_outlined,
              label: AppStrings.qualificationLabel,
              value: doctor.qualification,
            ),
            _InfoRow(
              icon: Icons.work_history_outlined,
              label: AppStrings.experienceLabel,
              value: '${doctor.experienceYears} ${AppStrings.yearExperienceLabel}',
            ),
            _InfoRow(
              icon: Icons.local_hospital_outlined,
              label: AppStrings.hospitalLabel,
              value: doctor.hospital,
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: AppStrings.locationLabel,
              value: doctor.location,
            ),
            _InfoRow(
              icon: Icons.currency_rupee,
              label: AppStrings.consultationFeeLabel,
              value: doctor.feeLabel,
            ),
            _InfoRow(
              icon: Icons.star_rounded,
              label: AppStrings.ratingLabel,
              value: '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount})',
            ),
            _InfoRow(
              icon: Icons.translate_outlined,
              label: AppStrings.languagesLabel,
              value: doctor.languages.join(', '),
            ),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: AppStrings.availabilityLabel,
              value: doctor.availableToday
                  ? AppStrings.availableToday
                  : AppStrings.notAvailableToday,
            ),
            const SizedBox(height: AppSizes.paddingLg),
            PrimaryButton(
              label: AppStrings.bookAppointment,
              icon: Icons.event_available_outlined,
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.appointmentBooking,
                  arguments: BookingArguments(doctor: doctor),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single label/value row inside the details screen.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSizes.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXs),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}