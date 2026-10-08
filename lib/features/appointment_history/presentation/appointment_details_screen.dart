import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/constants.dart';
import '../../../shared/enums/appointment_status.dart';
import '../../../shared/widgets/widgets.dart';
import '../../appointment_booking/models/appointment_model.dart';
import '../../appointment_booking/models/booking_arguments.dart';
import '../../appointment_booking/presentation/providers/appointment_controller.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Shows full details for a single appointment with status-aware actions.
///
/// Args: [AppointmentDetailsArguments] carrying the appointment id. The record
/// is loaded from Firestore scoped to the authenticated user.
class AppointmentDetailsScreen extends StatefulWidget {
  final AppointmentDetailsArguments? args;

  const AppointmentDetailsScreen({super.key, this.args});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  AppointmentModel? _appointment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  Future<void> _confirmCancel() async {
    final appointment = _appointment;
    final uid = context.read<AuthProvider>().currentUid;
    if (appointment == null || uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.cancelConfirmTitle),
        content: const Text(AppStrings.cancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.keepAppointment),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              AppStrings.cancelAppointmentConfirm,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<AppointmentController>();
    final success = await controller.cancel(uid, appointment.id);
    if (!mounted) return;
    if (success) {
      setState(() {
        _appointment = _appointment
            ?.copyWith(status: AppointmentStatus.cancelled);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.appointmentCancelled)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? AppStrings.cancellationFailed,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appointmentDetailsTitle)),
      body: SafeArea(
        child: _loading
            ? const LoadingWidget(message: AppStrings.loadingAppointmentDetails)
            : _error != null
                ? ErrorStateWidget(
                    message: _error!,
                    onRetry: () {
                      setState(() => _loading = true);
                      _load();
                    },
                  )
                : _buildDetails(context, _appointment!),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, AppointmentModel appointment) {
    final isCancelling =
        context.watch<AppointmentController>().isCancelling;
    final statusColor = _statusColor(appointment.status);

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      children: [
        // Doctor summary
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: Text(
                  _initials(appointment.doctorName),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.specialty,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),

        // Details
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              _DetailRow(icon: Icons.local_hospital_outlined, label: AppStrings.hospitalLabel, value: appointment.hospital),
              _DetailRow(icon: Icons.location_on_outlined, label: AppStrings.locationLabel, value: appointment.location),
              _DetailRow(icon: Icons.calendar_today_outlined, label: AppStrings.appointmentDateLabel, value: _formatLongDate(appointment.appointmentDate)),
              _DetailRow(icon: Icons.schedule, label: 'Time', value: appointment.appointmentTime),
              _DetailRow(icon: Icons.notes_outlined, label: AppStrings.reasonLabel, value: appointment.reasonForVisit.isEmpty ? AppStrings.noReasonProvided : appointment.reasonForVisit),
              if (appointment.notes.isNotEmpty)
                _DetailRow(icon: Icons.article_outlined, label: AppStrings.notesLabel, value: appointment.notes),
              _DetailRow(icon: Icons.currency_rupee, label: AppStrings.consultationFeeLabel, value: '₹${appointment.consultationFee}'),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),

        // Booking id + status
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.confirmation_number_outlined,
                label: AppStrings.bookingIdLabel,
                value: appointment.id,
              ),
              _DetailRow(
                icon: Icons.flag_outlined,
                label: AppStrings.appointmentStatusLabel,
                value: appointment.statusLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingLg),

        // Status-aware action
        if (appointment.status == AppointmentStatus.cancelled)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
              SizedBox(width: AppSizes.paddingSm),
              Text(
                'Status: Cancelled',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          )
        else
          PrimaryButton(
            label: AppStrings.cancelAppointment,
            icon: Icons.cancel_outlined,
            isLoading: isCancelling,
            onPressed: isCancelling ? null : _confirmCancel,
          ),
      ],
    );
  }

  Color _statusColor(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.pending => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.success,
      AppointmentStatus.completed => AppColors.info,
      AppointmentStatus.cancelled => AppColors.error,
    };
  }

  String _initials(String name) {
    final cleaned = name.replaceAll('Dr. ', '').trim();
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String _formatLongDate(DateTime date) {
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
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
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSizes.paddingSm),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}