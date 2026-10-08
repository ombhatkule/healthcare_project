import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../models/booking_arguments.dart';
import '../models/appointment_model.dart';
import 'providers/appointment_controller.dart';

/// Shown after a successful booking.
///
/// Args: [AppointmentConfirmationArguments] with the saved appointment's id.
class AppointmentConfirmationScreen extends StatefulWidget {
  final AppointmentConfirmationArguments? args;

  const AppointmentConfirmationScreen({super.key, this.args});

  @override
  State<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState
    extends State<AppointmentConfirmationScreen> {
  AppointmentModel? _appointment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    final appointmentId = widget.args?.appointmentId;
    final uid = context.read<AuthProvider>().currentUid;
    if (appointmentId == null || uid == null || uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = AppStrings.appointmentNotFound;
      });
      return;
    }
    final controller = context.read<AppointmentController>();
    final found = await controller.loadAppointment(uid, appointmentId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!found) {
        _error = controller.errorMessage ?? AppStrings.appointmentNotFound;
      } else {
        _appointment = controller.selectedAppointment;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appointmentConfirmed)),
      body: SafeArea(
        child: _loading
            ? const LoadingWidget(message: AppStrings.loadingAppointmentDetails)
            : _error != null || _appointment == null
                ? ErrorStateWidget(
                    message: _error ?? AppStrings.appointmentLoadFailed,
                    onRetry: () {
                      setState(() => _loading = true);
                      _loadAppointment();
                    },
                  )
                : _buildSuccess(context, _appointment!),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, AppointmentModel appointment) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      children: [
        const SizedBox(height: AppSizes.paddingMd),
        const Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.success,
            child: Icon(Icons.check, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        const Center(
          child: Text(
            AppStrings.appointmentConfirmed,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingSm),
        const Center(
          child: Text(
            AppStrings.appointmentConfirmedMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: appointment.doctorName,
                value: appointment.specialty,
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: _formatDate(appointment.appointmentDate),
                value: appointment.appointmentTime,
              ),
              _InfoRow(
                icon: Icons.local_hospital_outlined,
                label: appointment.hospital,
                value: appointment.location,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingXl),
        PrimaryButton(
          label: AppStrings.viewAppointment,
          icon: Icons.visibility_outlined,
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.appointmentDetails,
              (route) => route.isFirst,
              arguments: AppointmentDetailsArguments(
                appointmentId: appointment.id,
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.paddingMd),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          },
          icon: const Icon(Icons.home_outlined),
          label: const Text(AppStrings.backToHome),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

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
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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