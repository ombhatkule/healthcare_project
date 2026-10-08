import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../diet_exercise/presentation/providers/diet_exercise_controller.dart';
import '../../../diet_exercise/presentation/screens/screen_support.dart';
import '../../../diet_exercise/presentation/widgets/widgets.dart';

/// Manual daily activity tracking.
///
/// The app has no pedometer integration, so activity is entered by the user.
/// Steps can optionally be typed in by hand; the screen never claims to read
/// the phone's step counter.
class DailyActivityScreen extends StatefulWidget {
  const DailyActivityScreen({super.key});

  @override
  State<DailyActivityScreen> createState() => _DailyActivityScreenState();
}

class _DailyActivityScreenState extends State<DailyActivityScreen>
    with DietExerciseScreenState {
  bool _hasSyncedUid = false;
  String? _syncedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = signedInUid;

    if (_hasSyncedUid && uid == _syncedUid) return;
    _hasSyncedUid = true;
    _syncedUid = uid;

    if (uid == null || uid.isEmpty) return;
    runAfterFrame(() => dietExerciseController.load(uid));
  }

  Future<void> _openAddActivity(String uid) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _AddActivitySheet(),
    );
    if (added == true && mounted) {
      AppUtils.showSnackBar(context, AppStrings.activitySaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;
    final controller = context.watch<DietExerciseController>();
    final signedIn = uid != null && uid.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dailyActivityTitle),
        actions: [
          IconButton(
            key: const Key('activity_ai_action'),
            tooltip: AppStrings.askAiAboutDiet,
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
          ),
        ],
      ),
      floatingActionButton: signedIn
          ? FloatingActionButton.extended(
              key: const Key('add_activity_fab'),
              onPressed: controller.isSaving ? null : () => _openAddActivity(uid),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addActivity),
            )
          : null,
      body: SafeArea(
        child: controller.isLoading && controller.activity.date.isEmpty
            ? const LoadingWidget(message: AppStrings.loading)
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  signedIn ? 88 : AppSizes.paddingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: AppStrings.dailyActivityTitle,
                      subtitle:
                          'Log the movement you actually did today. This app '
                          'does not read your phone\'s step counter.',
                    ),
                    if (controller.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMd,
                        ),
                        child: Text(
                          controller.errorMessage ??
                              AppStrings.dietExerciseLoadFailed,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    if (!signedIn)
                      const Padding(
                        padding: EdgeInsets.all(AppSizes.paddingLg),
                        child: EmptyStateWidget(
                          icon: Icons.lock_outline,
                          title: AppStrings.signInToTrack,
                        ),
                      )
                    else
                      _buildBody(controller, uid),
                    const SizedBox(height: AppSizes.paddingSm),
                    const WellnessDisclaimer(compact: true),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBody(DietExerciseController controller, String uid) {
    final entries = controller.activityEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
          child: Row(
            children: [
              Expanded(
                child: ActivityProgressCard(
                  icon: Icons.timer_outlined,
                  label: AppStrings.exerciseProgressLabel,
                  value: '${controller.exerciseMinutes}',
                  supportingText: '${AppStrings.minutesUnit} of '
                      '${controller.exerciseGoalMinutes}',
                  progress: controller.exerciseProgress,
                ),
              ),
              const SizedBox(width: AppSizes.paddingSm),
              Expanded(
                child: ActivityProgressCard(
                  icon: Icons.check_circle_outline,
                  label: AppStrings.completedWorkoutsLabel,
                  value: '${controller.completedExerciseCount}',
                  supportingText: AppStrings.todayLabel,
                  progress: controller.exerciseProgress,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
          child: ActivityProgressCard(
            icon: Icons.local_drink_outlined,
            label: AppStrings.waterIntakeLabel,
            value: '${controller.waterGlasses} / ${controller.waterGoal}',
            supportingText: AppStrings.glassesUnit,
            progress: controller.waterProgress,
            color: AppColors.info,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
          child: ActivityProgressCard(
            icon: Icons.directions_walk_outlined,
            label: AppStrings.stepsLabel,
            value: '${controller.steps}',
            supportingText: 'manually entered',
            progress: 0,
            color: AppColors.accent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('add_activity_button'),
              onPressed:
                  controller.isSaving ? null : () => _openAddActivity(uid),
              icon: const Icon(Icons.add, size: 20),
              label: const Text(AppStrings.addActivity),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
          child: Text(
            AppStrings.todayLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.paddingLg),
            child: EmptyStateWidget(
              icon: Icons.event_note_outlined,
              title: AppStrings.noActivityLogged,
              subtitle: AppStrings.noActivityLoggedMessage,
            ),
          )
        else
          ...entries.map(
            (entry) => Card(
              key: Key('activity_entry_${entry.id}'),
              margin: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
                vertical: AppSizes.paddingXs,
              ),
              child: ListTile(
                leading: const Icon(Icons.timer_outlined,
                    color: AppColors.primary),
                title: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('${entry.minutes} ${AppStrings.minutesUnit}'),
                trailing: IconButton(
                  tooltip: AppStrings.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: controller.isSaving
                      ? null
                      : () async {
                          final removed =
                              await controller.removeActivityEntry(uid, entry.id);
                          if (mounted && removed) {
                            AppUtils.showSnackBar(
                                context, AppStrings.activityRemoved);
                          }
                        },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet used to log a manual activity entry.
///
/// Validation rejects empty names, non-numeric or non-positive durations and
/// absurdly large values.
class _AddActivitySheet extends StatefulWidget {
  const _AddActivitySheet();

  @override
  State<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends State<_AddActivitySheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _stepsProvided = false;

  @override
  void dispose() {
    _nameController.dispose();
    _minutesController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.signInToTrack, isError: true);
      return;
    }

    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final steps = int.tryParse(_stepsController.text.trim()) ?? 0;
    final controller = context.read<DietExerciseController>();

    // Steps and the entry live on the same day document, so they are saved in
    // one operation instead of racing two separate writes.
    controller
        .addActivityEntry(
          uid,
          name: _nameController.text,
          minutes: minutes,
          steps: steps > 0 ? steps : null,
        )
        .then((saved) {
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DietExerciseController>();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.paddingMd,
        right: AppSizes.paddingMd,
        top: AppSizes.paddingMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.paddingMd,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.addActivity,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  key: const Key('activity_name_field'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.activityNameLabel,
                    hintText: AppStrings.activityNameHint,
                    prefixIcon: Icons.directions_walk_outlined,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? AppStrings.activityNameRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  key: const Key('activity_minutes_field'),
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.activityDurationLabel,
                    hintText: AppStrings.activityDurationHint,
                    prefixIcon: Icons.timer_outlined,
                  ),
                  validator: _validateMinutes,
                ),
                const SizedBox(height: AppSizes.paddingMd),
                TextFormField(
                  key: const Key('activity_steps_field'),
                  controller: _stepsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) =>
                      setState(() => _stepsProvided = value.trim().isNotEmpty),
                  decoration: AppDecorations.inputDecoration(
                    labelText: AppStrings.stepsLabel,
                    hintText: AppStrings.stepsHint,
                    prefixIcon: Icons.directions_walk_outlined,
                  ),
                  validator: _validateSteps,
                ),
                if (_stepsProvided) ...[
                  const SizedBox(height: AppSizes.paddingXs),
                  const Text(
                    'Steps are entered by hand — this app does not read your '
                    'phone\'s step counter.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.paddingLg),
                PrimaryButton(
                  key: const Key('save_activity_button'),
                  label: AppStrings.saveActivity,
                  icon: Icons.check,
                  isLoading: controller.isSaving,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSizes.paddingSm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(AppStrings.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateMinutes(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return AppStrings.activityDurationRequired;
    final minutes = int.tryParse(text);
    if (minutes == null) return AppStrings.activityDurationInvalid;
    if (minutes <= 0) return AppStrings.activityDurationInvalid;
    if (minutes >= 600) return AppStrings.activityDurationTooLong;
    return null;
  }

  String? _validateSteps(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final steps = int.tryParse(text);
    if (steps == null || steps < 0) return AppStrings.stepsInvalid;
    return null;
  }
}