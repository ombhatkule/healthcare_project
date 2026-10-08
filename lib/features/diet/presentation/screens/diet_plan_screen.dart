import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../diet_exercise/presentation/providers/diet_exercise_controller.dart';
import '../../../diet_exercise/presentation/screens/screen_support.dart';
import '../../../diet_exercise/presentation/widgets/widgets.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// The full daily diet plan.
///
/// Opens from the Diet module landing screen (or the legacy diet
/// recommendation route), so there is only ever one diet plan screen.
class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with DietExerciseScreenState {
  bool _hasSyncedUid = false;
  String? _syncedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = signedInUid;

    // Re-runs on every controller notification, so the sync is keyed on the uid
    // to make sure a load is only ever started once per user.
    if (_hasSyncedUid && uid == _syncedUid) return;
    _hasSyncedUid = true;
    _syncedUid = uid;

    if (uid == null || uid.isEmpty) return;
    runAfterFrame(() => dietExerciseController.load(uid));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DietExerciseController>();

    // The plan is personalized with the profile, which may finish loading after
    // this screen; the deferred sync keeps the plan in step with it.
    final profile = context.watch<ProfileProvider>().profile;
    if (profile != controller.profile) {
      runAfterFrame(() => controller.setProfile(profile));
    }
    final plan = controller.dietPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dietPlanTitle),
        actions: [
          IconButton(
            key: const Key('diet_plan_exercise_action'),
            tooltip: AppStrings.viewExercises,
            icon: const Icon(Icons.fitness_center_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.exercise),
          ),
          IconButton(
            key: const Key('diet_plan_ai_action'),
            tooltip: AppStrings.askAiAboutDiet,
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading && plan.isEmpty
            ? const LoadingWidget(message: AppStrings.loading)
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingXl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(
                      title: AppStrings.todaysDietPlanLabel,
                      subtitle: plan.subtitle,
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
                    if (plan.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(AppSizes.paddingXl),
                        child: EmptyStateWidget(
                          icon: Icons.restaurant_menu_outlined,
                          title: 'No meal suggestions available',
                          subtitle:
                              'Please try again in a moment. General guidance '
                              'will be shown here.',
                        ),
                      )
                    else
                      ...plan.meals.map(
                        (meal) => MealCard(meal: meal),
                      ),
                    _NutritionGuidanceSection(tips: plan.nutritionTips),
                    _PersonalizationSection(
                      notes: plan.personalizationNotes,
                      onCustomize: () => Navigator.of(context)
                          .pushNamed(AppRoutes.dietExercisePreferences),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                        vertical: AppSizes.paddingSm,
                      ),
                      child: PrimaryButton(
                        key: const Key('diet_plan_ask_ai_button'),
                        label: AppStrings.askAiAboutDiet,
                        icon: Icons.smart_toy_outlined,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.aiAssistant),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSm),
                    WellnessDisclaimer(text: plan.disclaimer),
                    const WellnessDisclaimer(compact: true),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NutritionGuidanceSection extends StatelessWidget {
  final List<String> tips;

  const _NutritionGuidanceSection({required this.tips});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();

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
                const Icon(Icons.eco_outlined, color: AppColors.success),
                const SizedBox(width: AppSizes.paddingSm),
                Expanded(
                  child: Text(
                    AppStrings.nutritionGuidanceLabel,
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
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: AppColors.success),
                    ),
                    const SizedBox(width: AppSizes.paddingSm),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
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
    );
  }
}

class _PersonalizationSection extends StatelessWidget {
  final List<String> notes;
  final VoidCallback onCustomize;

  const _PersonalizationSection({
    required this.notes,
    required this.onCustomize,
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
                const Icon(Icons.person_outline, color: AppColors.secondary),
                const SizedBox(width: AppSizes.paddingSm),
                Expanded(
                  child: Text(
                    AppStrings.personalizedForYouLabel,
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
            ...notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingXs),
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('diet_plan_customize_button'),
                onPressed: onCustomize,
                icon: const Icon(Icons.tune_outlined, size: 18),
                label: const Text(AppStrings.wellnessPreferencesTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}