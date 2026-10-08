import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../diet_exercise/models/models.dart';
import '../../../diet_exercise/presentation/providers/diet_exercise_controller.dart';
import '../../../diet_exercise/presentation/widgets/widgets.dart';
import '../../../diet_exercise/services/services.dart';

/// Detail view for one exercise from the library.
///
/// Opening this screen never marks the exercise as completed — only the
/// explicit "Mark as Completed" action does.
class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseItem exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DietExerciseController>();
    final uid = context.watch<AuthProvider>().currentUid;
    final isCompleted = controller.isExerciseCompleted(exercise.id);

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(exercise: exercise, isCompleted: isCompleted),
              if (exercise.instructions.isNotEmpty)
                _DetailSection(
                  icon: Icons.info_outline,
                  title: AppStrings.instructionsLabel2,
                  child: Text(
                    exercise.instructions,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              if (exercise.steps.isNotEmpty)
                _DetailSection(
                  icon: Icons.list_alt_outlined,
                  title: AppStrings.howToStepsLabel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...exercise.steps.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSizes.paddingSm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor:
                                        AppColors.primary.withValues(alpha: 0.12),
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.paddingSm),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              if (exercise.safetyNote.isNotEmpty)
                _SafetySection(note: exercise.safetyNote),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingMd,
                ),
                child: isCompleted
                    ? OutlinedButton.icon(
                        key: const Key('exercise_detail_completed'),
                        onPressed: (uid == null || uid.isEmpty)
                            ? null
                            : () => controller.toggleExercise(uid, exercise),
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text('Completed'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      )
                    : PrimaryButton(
                        key: const Key('exercise_detail_mark_completed'),
                        label: AppStrings.markCompletedLabel,
                        icon: Icons.check_circle_outline,
                        isLoading: controller.isSaving,
                        onPressed: (uid == null || uid.isEmpty)
                            ? null
                            : () => controller.toggleExercise(uid, exercise),
                      ),
              ),
              if (isCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMd),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      const SizedBox(width: AppSizes.paddingXs),
                      Text(
                        AppStrings.completedLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSizes.paddingMd),
              const WellnessDisclaimer(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// Name, difficulty, duration and the current completion state.
class _HeaderCard extends StatelessWidget {
  final ExerciseItem exercise;
  final bool isCompleted;

  const _HeaderCard({required this.exercise, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
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
                Icon(exercise.category.icon,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingXs),
                Expanded(
                  child: Text(
                    exercise.category.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (isCompleted)
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: AppColors.success),
                      SizedBox(width: AppSizes.paddingXs),
                      Text(
                        AppStrings.completedLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            Wrap(
              spacing: AppSizes.paddingSm,
              runSpacing: AppSizes.paddingSm,
              children: [
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: AppStrings.durationLabel2,
                  value: '${exercise.durationMinutes} '
                      '${AppStrings.minutesUnit}',
                ),
                _InfoPill(
                  icon: Icons.signal_cellular_alt_outlined,
                  label: AppStrings.difficultyLabel2,
                  value: exercise.difficulty.label,
                ),
              ],
            ),
            if (exercise.description.isNotEmpty) ...[
              const SizedBox(height: AppSizes.paddingSm),
              Text(
                exercise.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.paddingXs),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingXs),
                Expanded(
                  child: Text(
                    title,
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
            child,
          ],
        ),
      ),
    );
  }
}

class _SafetySection extends StatelessWidget {
  final String note;

  const _SafetySection({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.health_and_safety_outlined,
              color: AppColors.warning, size: 18),
          const SizedBox(width: AppSizes.paddingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.safetyNoteLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXs),
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

/// Convenience helper used by the router so an unknown id never crashes.
ExerciseDetailScreen? buildExerciseDetailScreen(String? exerciseId) {
  if (exerciseId == null || exerciseId.isEmpty) return null;
  final exercise = ExerciseService.byId(exerciseId);
  if (exercise == null) return null;
  return ExerciseDetailScreen(exercise: exercise);
}