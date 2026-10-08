import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../diet_exercise/models/models.dart';
import '../../../diet_exercise/presentation/providers/diet_exercise_controller.dart';
import '../../../diet_exercise/presentation/screens/screen_support.dart';
import '../../../diet_exercise/presentation/widgets/widgets.dart';
import '../../../diet_exercise/services/services.dart';

/// The Exercise module landing screen.
///
/// Combines today's routine, the exercise library, water and activity tracking
/// and the weekly progress shortcut. Pure exercise content only — no diet
/// sections.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with DietExerciseScreenState {
  bool _hasSyncedUid = false;
  String? _syncedUid;
  ExerciseCategory? _selectedCategory;

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

  List<ExerciseItem> get _visibleExercises =>
      ExerciseService.byCategory(_selectedCategory);

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;
    final controller = context.watch<DietExerciseController>();
    final routine = controller.dailyRoutine;
    final library = _visibleExercises;
    final signedIn = uid != null && uid.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.exerciseTitle),
        actions: [
          IconButton(
            key: const Key('exercise_preferences_action'),
            tooltip: AppStrings.wellnessPreferencesTitle,
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.dietExercisePreferences),
          ),
          IconButton(
            key: const Key('exercise_ai_action'),
            tooltip: AppStrings.askAiAboutDiet,
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading && controller.workout.date.isEmpty
            ? const LoadingWidget(message: AppStrings.loading)
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: AppStrings.yourExercisePlan,
                      subtitle: AppStrings.dietExerciseSubtitle,
                    ),
                    if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMd,
                        ),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (controller.hasError)
                      InlineErrorBanner(
                        message: controller.errorMessage ??
                            AppStrings.dietExerciseLoadFailed,
                        onRetry: () => controller.load(uid!),
                        onDismiss: controller.clearError,
                        isLoading: controller.isLoading,
                      ),
                    const SectionTitle(AppStrings.todaysProgressLabel),
                    _buildSummaryRow(controller),
                    WaterProgressCard(
                      glasses: controller.waterGlasses,
                      goal: controller.waterGoal,
                      enabled: signedIn && !controller.isSaving,
                      onIncrement: signedIn
                          ? () => controller.incrementWater(uid)
                          : null,
                      onDecrement: signedIn
                          ? () => controller.decrementWater(uid)
                          : null,
                    ),
                    _RoutineSection(
                      routine: routine,
                      controller: controller,
                    ),
                    _buildProgressCard(controller),
                    _CategoryFilters(
                      selected: _selectedCategory,
                      onSelected: (category) =>
                          setState(() => _selectedCategory = category),
                    ),
                    if (library.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSizes.paddingXl),
                        child: EmptyStateWidget(
                          icon: Icons.search_off_outlined,
                          title: 'No exercises in this category',
                          subtitle:
                              'Choose a different category to keep browsing.',
                        ),
                      )
                    else
                      ...library.map(
                        (exercise) => ExerciseCard(
                          exercise: exercise,
                          isCompleted:
                              controller.isExerciseCompleted(exercise.id),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.dietExerciseDetail,
                            arguments: ExerciseDetailArguments(
                              exerciseId: exercise.id,
                            ),
                          ),
                          onToggleCompleted: signedIn
                              ? (controller.isSaving
                                  ? null
                                  : () =>
                                      controller.toggleExercise(uid, exercise))
                              : null,
                        ),
                      ),
                    const WellnessDisclaimer(
                      text: AppStrings.exerciseSafetyNote,
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                      ),
                      child: PrimaryButton(
                        key: const Key('exercise_ask_ai_button'),
                        label: AppStrings.askAiAboutDiet,
                        icon: Icons.smart_toy_outlined,
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryRow(DietExerciseController controller) {
    final activitySupporting = controller.manualActivityMinutes > 0
        ? '${controller.manualActivityMinutes} ${AppStrings.minutesUnit}'
        : AppStrings.todayLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ActivityProgressCard(
              icon: Icons.local_drink_outlined,
              label: AppStrings.waterIntakeLabel,
              value: '${controller.waterGlasses} / ${controller.waterGoal}',
              supportingText: AppStrings.glassesUnit,
              progress: controller.waterProgress,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: ActivityProgressCard(
              icon: Icons.timer_outlined,
              label: AppStrings.exerciseProgressLabel,
              value: '${controller.exerciseMinutes} / '
                  '${controller.exerciseGoalMinutes}',
              supportingText: AppStrings.minutesUnit,
              progress: controller.exerciseProgress,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: ActivityProgressCard(
              icon: Icons.directions_walk_outlined,
              label: AppStrings.activityProgressLabel,
              value: '${controller.activity.entryCount}',
              supportingText: activitySupporting,
              progress: 0,
              color: AppColors.accent,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.dietExerciseActivity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(DietExerciseController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_outlined, color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingSm),
                Expanded(
                  child: Text(
                    AppStrings.progressTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              '${controller.completedExerciseCount} '
              '${AppStrings.completedWorkoutsLabel.toLowerCase()} • '
              '${controller.waterGlasses} ${AppStrings.glassesUnit} today',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('view_progress_button'),
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.dietExerciseProgress),
                icon: const Icon(Icons.bar_chart_outlined, size: 18),
                label: const Text(AppStrings.progressTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's routine header with a start button and completion count.
class _RoutineSection extends StatelessWidget {
  final List<ExerciseItem> routine;
  final DietExerciseController controller;

  const _RoutineSection({
    required this.routine,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final done = routine
        .where((exercise) => controller.isExerciseCompleted(exercise.id))
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today_outlined, color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingSm),
                Expanded(
                  child: Text(
                    AppStrings.todaysExerciseLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$done / ${routine.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: routine.isEmpty ? 0 : done / routine.length,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              '${controller.exerciseMinutes} of '
              '${controller.exerciseGoalMinutes} ${AppStrings.minutesUnit} '
              '${AppStrings.generalGuidanceLabel.toLowerCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('start_workout_button'),
                onPressed: routine.isEmpty
                    ? null
                    : () {
                        ExerciseItem? next;
                        for (final exercise in routine) {
                          if (!controller.isExerciseCompleted(exercise.id)) {
                            next = exercise;
                            break;
                          }
                        }
                        final target = next ?? routine.first;
                        Navigator.of(context).pushNamed(
                          AppRoutes.dietExerciseDetail,
                          arguments:
                              ExerciseDetailArguments(exerciseId: target.id),
                        );
                      },
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text(AppStrings.startWorkout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal category filter. Uses a Wrap so no item can overflow.
class _CategoryFilters extends StatelessWidget {
  final ExerciseCategory? selected;
  final ValueChanged<ExerciseCategory?> onSelected;

  const _CategoryFilters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMd,
        AppSizes.paddingMd,
        AppSizes.paddingMd,
        AppSizes.paddingXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.exerciseLibraryLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          Wrap(
            spacing: AppSizes.paddingSm,
            runSpacing: AppSizes.paddingSm,
            children: [
              FilterChip(
                key: const Key('exercise_category_all'),
                label: Text(AppStrings.allCategories),
                selected: selected == null,
                onSelected: (_) => onSelected(null),
              ),
              ...ExerciseCategory.values.map(
                (category) => FilterChip(
                  key: Key('exercise_category_${category.key}'),
                  avatar: Icon(category.icon, size: 16),
                  label: Text(category.label),
                  selected: selected == category,
                  onSelected: (_) => onSelected(
                    selected == category ? null : category,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}