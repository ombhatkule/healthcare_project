import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../models/models.dart';
import '../providers/diet_exercise_controller.dart';
import '../widgets/widgets.dart';

/// Lets the user choose a wellness goal, food preference and activity level.
///
/// These are habit preferences only — the screen states plainly that they are
/// not a treatment plan.
class DietExercisePreferencesScreen extends StatefulWidget {
  const DietExercisePreferencesScreen({super.key});

  @override
  State<DietExercisePreferencesScreen> createState() =>
      _DietExercisePreferencesScreenState();
}

class _DietExercisePreferencesScreenState
    extends State<DietExercisePreferencesScreen> {
  late WellnessGoal _goal;
  late FoodPreference _foodPreference;
  late WellnessActivityLevel _activityLevel;
  late int _waterGoal;
  late int _exerciseGoal;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    final stored = context.read<DietExerciseController>().preferences;
    _goal = stored.goal;
    _foodPreference = stored.foodPreference;
    _activityLevel = stored.activityLevel;
    _waterGoal = stored.waterGoal;
    _exerciseGoal = stored.dailyExerciseGoalMinutes;
    _initialised = true;
  }

  Future<void> _save() async {
    final uid = context.read<AuthProvider>().currentUid;
    if (uid == null || uid.isEmpty) {
      AppUtils.showSnackBar(context, AppStrings.signInToTrack, isError: true);
      return;
    }

    final controller = context.read<DietExerciseController>();
    final saved = await controller.savePreferences(
      uid,
      DietExercisePreferences(
        goal: _goal,
        foodPreference: _foodPreference,
        activityLevel: _activityLevel,
        waterGoal: _waterGoal,
        dailyExerciseGoalMinutes: _exerciseGoal,
        hasSelectedGoal: true,
      ),
    );

    if (!mounted) return;
    if (saved) {
      AppUtils.showSnackBar(context, AppStrings.preferencesSaved);
      Navigator.of(context).pop(true);
    } else {
      AppUtils.showSnackBar(
        context,
        controller.errorMessage ?? AppStrings.preferencesFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DietExerciseController>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.wellnessPreferencesTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: AppStrings.wellnessPreferencesTitle,
                subtitle: AppStrings.wellnessGoalHelper,
              ),
              if (controller.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingMd,
                  ),
                  child: Text(
                    controller.errorMessage ?? AppStrings.preferencesFailed,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              _OptionSection<WellnessGoal>(
                title: AppStrings.wellnessGoalLabel,
                options: WellnessGoal.values,
                labelOf: (goal) => goal.label,
                descriptionOf: (goal) => goal.description,
                selected: _goal,
                onSelected: (goal) => setState(() => _goal = goal),
              ),
              _OptionSection<FoodPreference>(
                title: AppStrings.foodPreferenceLabel,
                options: FoodPreference.values,
                labelOf: (value) => value.label,
                descriptionOf: (value) => value.description,
                selected: _foodPreference,
                onSelected: (value) => setState(() => _foodPreference = value),
              ),
              _OptionSection<WellnessActivityLevel>(
                title: AppStrings.activityLevelLabel,
                options: WellnessActivityLevel.values,
                labelOf: (value) => value.label,
                descriptionOf: (value) => value.description,
                selected: _activityLevel,
                onSelected: (value) => setState(() => _activityLevel = value),
              ),
              _GoalStepperCard(
                title: AppStrings.waterGoalLabel,
                value: '$_waterGoal ${AppStrings.glassesUnit}',
                onDecrease: _waterGoal > HydrationRecord.minGoal
                    ? () => setState(() => _waterGoal -= 1)
                    : null,
                onIncrease: _waterGoal < HydrationRecord.maxGoal
                    ? () => setState(() => _waterGoal += 1)
                    : null,
              ),
              _GoalStepperCard(
                title: AppStrings.dailyExerciseGoalLabel,
                value: '$_exerciseGoal ${AppStrings.minutesUnit}',
                onDecrease: _exerciseGoal >
                        DietExercisePreferences.minExerciseGoalMinutes
                    ? () => setState(() => _exerciseGoal -= 5)
                    : null,
                onIncrease: _exerciseGoal <
                        DietExercisePreferences.maxExerciseGoalMinutes
                    ? () => setState(() => _exerciseGoal += 5)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingMd,
                ),
                child: PrimaryButton(
                  key: const Key('save_preferences_button'),
                  label: AppStrings.savePreferences,
                  icon: Icons.save_outlined,
                  isLoading: controller.isSaving,
                  onPressed: _save,
                ),
              ),
              const WellnessDisclaimer(
                text: AppStrings.wellnessGoalsAreNotTreatment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled group of radio-style option cards built with a Wrap so long labels
/// wrap instead of overflowing.
class _OptionSection<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final String Function(T option) labelOf;
  final String Function(T option) descriptionOf;
  final T selected;
  final ValueChanged<T> onSelected;

  const _OptionSection({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.descriptionOf,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          ...options.map(
            (option) => _OptionTile(
              key: Key('option_${title}_${labelOf(option)}'),
              label: labelOf(option),
              description: descriptionOf(option),
              isSelected: option == selected,
              onTap: () => onSelected(option),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingXs,
      ),
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      description,
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
        ),
      ),
    );
  }
}

/// A +/- control for the user's own numeric wellness goals.
class _GoalStepperCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _GoalStepperCard({
    required this.title,
    required this.value,
    this.onDecrease,
    this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingXs,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    AppStrings.generalGuidanceLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDecrease,
              tooltip: 'Decrease',
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 76,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: onIncrease,
              tooltip: 'Increase',
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}