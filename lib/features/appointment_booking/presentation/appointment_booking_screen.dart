import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_router.dart';
import '../../../core/constants/constants.dart';
import '../../../shared/enums/appointment_status.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../doctor_recommendation/models/doctor.dart';
import '../models/appointment_model.dart';
import '../models/booking_arguments.dart';
import '../services/appointment_availability_service.dart';
import 'providers/appointment_controller.dart';

/// Booking date bounds.
///
/// Only future dates can be booked; the window is today..today+[maxDays].
abstract final class BookingDateRange {
  static const int maxDays = 90;

  /// Earliest selectable date (today, at midnight).
  static DateTime min() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Latest selectable date.
  static DateTime max() => min().add(const Duration(days: maxDays));
}

/// The multi-step appointment booking flow.
///
/// Steps: Select Date → Select Time → Appointment Info → Review → Confirm.
///
/// Args: [BookingArguments] carrying the [Doctor] selected from Doctor
/// Details / Search / Recommendation.
class AppointmentBookingScreen extends StatefulWidget {
  final BookingArguments? args;

  const AppointmentBookingScreen({super.key, this.args});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  int _step = 0;
  DateTime? _selectedDate;
  TimeOfDayValue? _selectedSlot;
  List<TimeOfDayValue> _availableSlots = [];
  bool _loadingSlots = false;
  bool _confirming = false;
  String? _errorText;

  AppointmentStatus get _confirmedStatus => AppointmentStatus.confirmed;

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Doctor? get _doctor => widget.args?.doctor;

  bool get _isFinalStep => _step == 3;

  @override
  Widget build(BuildContext context) {
    final doctor = _doctor;
    final isBooking = context.watch<AppointmentController>().isBooking;
    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appointmentBookingTitle)),
        body: const SafeArea(
          child: EmptyStateWidget(
            icon: Icons.person_off_outlined,
            title: AppStrings.doctorNotFound,
            subtitle: AppStrings.doctorRequired,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appointmentBookingTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingMd,
                  AppSizes.paddingSm,
                  AppSizes.paddingMd,
                  AppSizes.paddingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DoctorSummaryCard(doctor: doctor),
                    const SizedBox(height: AppSizes.paddingMd),
                    _StepIndicator(currentStep: _step),
                    const SizedBox(height: AppSizes.paddingMd),
                    ..._buildStepContent(),
                  ],
                ),
              ),
            ),
            _BottomActionBar(
              isFinalStep: _isFinalStep,
              showBack: _step > 0,
              isConfirming: isBooking,
              onBack: _step > 0 ? () => _goBack() : null,
              onContinue: _step < 3 && !isBooking ? _continue : null,
              onConfirm: _step == 3 && !isBooking ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStepContent() {
    return switch (_step) {
      0 => [
          _SectionHeader(
            title: AppStrings.appointmentSelectDate,
            subtitle: 'Choose a day for your visit to ${_doctor?.name}.',
          ),
          const SizedBox(height: AppSizes.paddingMd),
          _DatePickerCard(
            selectedDate: _selectedDate,
            onTap: _pickDate,
          ),
          if (_errorText != null && _step == 0) ...[
            const SizedBox(height: AppSizes.paddingMd),
            _ValidationMessage(message: _errorText!),
          ],
        ],
      1 => [
          _SectionHeader(
            title: AppStrings.availableTimeLabel,
            subtitle: 'Slots are shown for ${_selectedDate != null ? _formatLongDate(_selectedDate!) : AppStrings.selectDateHint}',
          ),
          const SizedBox(height: AppSizes.paddingMd),
          if (_loadingSlots)
            const LoadingWidget(message: 'Checking available slots...')
          else
            _TimeSlotGrid(
              slots: _availableSlots,
              selectedSlot: _selectedSlot,
              onSelect: (slot) {
                setState(() {
                  _selectedSlot = slot;
                  _errorText = null;
                });
              },
            ),
          if (_errorText != null && _step == 1) ...[
            const SizedBox(height: AppSizes.paddingMd),
            _ValidationMessage(message: _errorText!),
          ],
        ],
      2 => [
          _SectionHeader(
            title: AppStrings.appointmentInfoTitle,
            subtitle: 'Help the doctor prepare for your visit.',
          ),
          const SizedBox(height: AppSizes.paddingMd),
          TextField(
            controller: _reasonController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: AppStrings.reasonForVisitLabel,
              hintText: AppStrings.reasonForVisitHint,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: AppSizes.paddingMd),
          TextField(
            controller: _notesController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: AppStrings.additionalNotesLabel,
              hintText: AppStrings.additionalNotesHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      _ => [
          _ReviewCard(
            doctor: _doctor!,
            date: _selectedDate!,
            slot: _selectedSlot!,
            reason: _reasonController.text.trim(),
            fee: _doctor!.consultationFee,
          ),
        ],
    };
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final start = BookingDateRange.min();
    final end = BookingDateRange.max();

    final picked = await showDatePicker(
      context: context,
      initialDate: (_selectedDate != null && !_selectedDate!.isBefore(start)) ? _selectedDate! : start,
      firstDate: start,
      lastDate: end,
      helpText: AppStrings.appointmentSelectDate,
    );

    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _selectedSlot = null;
      _availableSlots = [];
      _errorText = null;
    });
    // Prefetch slots for the selected date.
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final doctor = _doctor;
    final date = _selectedDate;
    if (doctor == null || date == null) return;

    setState(() => _loadingSlots = true);

    final availability =
        context.read<AppointmentAvailabilityService>();
    try {
      final slots =
          await availability.getAvailableSlots(doctorId: doctor.id, date: date);
      if (!mounted || _selectedDate != date) return;
      setState(() {
        _availableSlots = slots;
        _loadingSlots = false;
        if (_selectedSlot != null && !_availableSlots.contains(_selectedSlot)) {
          _selectedSlot = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableSlots = [];
        _loadingSlots = false;
      });
    }
  }

  void _continue() {
    switch (_step) {
      case 0:
        if (_selectedDate == null) {
          setState(() => _errorText = AppStrings.selectDateRequired);
          return;
        }
      case 1:
        if (_selectedSlot == null) {
          setState(() => _errorText = AppStrings.selectTimeRequired);
          return;
        }
      default:
        break;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _errorText = null;
      _step += 1;
    });
  }

  void _goBack() {
    setState(() {
      _errorText = null;
      _step -= 1;
    });
  }

  Future<void> _confirm() async {
    final doctor = _doctor;
    final date = _selectedDate;
    final slot = _selectedSlot;

    if (doctor == null || date == null || slot == null) {
      setState(() => _errorText = AppStrings.selectTimeRequired);
      return;
    }

    // Prevent double submission from rapid taps while already booking.
    if (_confirming) return;
    _confirming = true;

    try {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.currentUid;
      if (uid == null || uid.isEmpty) {
        _showMessage(AppStrings.signInRequired);
        return;
      }

      final controller = context.read<AppointmentController>();

      final appointment = AppointmentModel(
        id: '', // assigned by Firestore
        userId: uid,
        doctorId: doctor.id,
        doctorName: doctor.name,
        specialty: doctor.specialty,
        hospital: doctor.hospital,
        location: doctor.location,
        appointmentDate: date,
        appointmentTime: slot.formatted,
        status: _confirmedStatus,
        reasonForVisit: _reasonController.text.trim(),
        notes: _notesController.text.trim(),
        consultationFee: doctor.consultationFee,
        createdAt: DateTime.now(),
      );

      final saved = await controller.book(appointment);
      if (!mounted) return;
      if (saved == null) {
        final message = controller.errorMessage;
        if (message != null && message.isNotEmpty) {
          _showMessage(message);
        } else {
          _showMessage(AppStrings.bookingFailed);
        }
        return;
      }

      await Navigator.of(context).pushReplacementNamed(
        AppRoutes.appointmentConfirmation,
        arguments: AppointmentConfirmationArguments(appointmentId: saved.id),
      );
    } finally {
      _confirming = false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatLongDate(DateTime date) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Compact doctor summary shown at the top of the booking flow.
class _DoctorSummaryCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorSummaryCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: AppDecorations.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: Text(
              doctor.initials,
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
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialty,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
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

/// Horizontal step indicator.
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  static const _labels = ['Date', 'Time', 'Info', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length, (index) {
        final isActive = index == currentStep;
        final isDone = index < currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isActive || isDone
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      child: Icon(
                        isDone
                            ? Icons.check
                            : Icons.circle,
                        size: isDone ? 14 : 8,
                        color: isActive || isDone
                            ? Colors.white
                            : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < _labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: index < currentStep
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Date-selection card with a prominent picker button.
class _DatePickerCard extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onTap;

  const _DatePickerCard({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        decoration: AppDecorations.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSizes.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.appointmentDateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate == null
                        ? AppStrings.noDateSelected
                        : _formatDate(selectedDate!),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selectedDate == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final time = date;
    return '${time.day} ${months[time.month - 1]} ${time.year}';
  }
}

/// Grid of selectable time slots.
class _TimeSlotGrid extends StatelessWidget {
  final List<TimeOfDayValue> slots;
  final TimeOfDayValue? selectedSlot;
  final ValueChanged<TimeOfDayValue> onSelect;

  const _TimeSlotGrid({
    required this.slots,
    required this.selectedSlot,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: const Column(
          children: [
            Icon(Icons.schedule, color: AppColors.textHint, size: 40),
            SizedBox(height: AppSizes.paddingSm),
            Text(
              'No slots are available on this date.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Please choose another date.',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSizes.paddingSm,
        mainAxisSpacing: AppSizes.paddingSm,
        mainAxisExtent: 46,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = slot == selectedSlot;
        return InkWell(
          onTap: () => onSelect(slot),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              slot.formatted,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Section heading inside the flow.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Inline validation message.
class _ValidationMessage extends StatelessWidget {
  final String message;

  const _ValidationMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
        const SizedBox(width: AppSizes.paddingXs),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Bottom action bar with Back / Continue / Confirm buttons.
class _BottomActionBar extends StatelessWidget {
  final bool isFinalStep;
  final bool showBack;
  final bool isConfirming;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;
  final VoidCallback? onConfirm;

  const _BottomActionBar({
    required this.isFinalStep,
    required this.showBack,
    required this.isConfirming,
    required this.onBack,
    required this.onContinue,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMd,
        AppSizes.paddingSm,
        AppSizes.paddingMd,
        AppSizes.paddingMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showBack) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text(AppStrings.backButton),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMd),
            ],
            Expanded(
              flex: 2,
              child: isFinalStep
                  ? PrimaryButton(
                      label: AppStrings.confirmAppointment,
                      icon: Icons.check,
                      isLoading: isConfirming,
                      onPressed: onConfirm,
                    )
                  : PrimaryButton(
                      label: AppStrings.continueButton,
                      icon: Icons.arrow_forward,
                      onPressed: onContinue,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Review card shown on the final step.
class _ReviewCard extends StatelessWidget {
  final Doctor doctor;
  final DateTime date;
  final TimeOfDayValue slot;
  final String reason;
  final int fee;

  const _ReviewCard({
    required this.doctor,
    required this.date,
    required this.slot,
    required this.reason,
    required this.fee,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: AppStrings.reviewAppointmentTitle,
          subtitle: 'Please review your appointment details before confirming.',
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Column(
            children: [
              _ReviewRow(icon: Icons.person_outline, label: 'Doctor', value: doctor.name),
              _ReviewRow(icon: Icons.local_hospital_outlined, label: 'Specialty', value: doctor.specialty),
              _ReviewRow(icon: Icons.local_hospital_outlined, label: 'Hospital', value: doctor.hospital),
              _ReviewRow(icon: Icons.location_on_outlined, label: 'Location', value: doctor.location),
              _ReviewRow(icon: Icons.calendar_today_outlined, label: 'Date', value: _formatReviewDate(date)),
              _ReviewRow(icon: Icons.schedule, label: 'Time', value: slot.formatted),
              _ReviewRow(icon: Icons.notes_outlined, label: 'Reason', value: reason.isEmpty ? AppStrings.noReasonProvided : reason),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          decoration: AppDecorations.cardDecoration,
          child: Row(
            children: [
              const Icon(Icons.currency_rupee, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSizes.paddingSm),
              const Text(
                AppStrings.consultationFeeLabel,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '₹$fee',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatReviewDate(DateTime date) {
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

/// A single review row.
class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow({
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
            width: 90,
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