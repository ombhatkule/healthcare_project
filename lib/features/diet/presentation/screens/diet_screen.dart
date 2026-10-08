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
import '../../../profile/presentation/providers/profile_provider.dart';

/// The Diet module landing screen.
///
/// Pure diet content only: today's goal, the meal plan summary and the link to
/// the full plan. Water, exercise and activity live on the Exercise module.
class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen>
    with DietExerciseScreenState {
  bool _hasSyncedUid = false;
  String? _syncedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uid = signedInUid;

    // This method runs again whenever the controller notifies, so the sync is
    // keyed on the uid: without the guard the notification would schedule
    // another sync and the screen would rebuild forever.
    if (_hasSyncedUid && uid == _syncedUid) return;
    _hasSyncedUid = true;
    _syncedUid = uid;

    final controller = dietExerciseController;
    if (uid == null || uid.isEmpty) {
      runAfterFrame(() {
        if (controller.date.isNotEmpty || controller.isSignedIn) {
          controller.reset();
        }
      });
      return;
    }
    runAfterFrame(() => controller.load(uid));
  }

  void _openPreferences(String uid) {
    Navigator.of(context).pushNamed(AppRoutes.dietExercisePreferences);
  }

  void _openFullPlan() {
    Navigator.of(context).pushNamed(AppRoutes.dietExerciseDiet);
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;
    final controller = context.watch<DietExerciseController>();

    // Personalization inputs come from the existing profile module; the
    // controller tolerates a null profile and falls back to generic guidance.
    final profile = context.watch<ProfileProvider>().profile;
    if (profile != controller.profile) {
      runAfterFrame(() => controller.setProfile(profile));
    }

    if (uid == null || uid.isEmpty) {
      return SignedOutScaffold(
        title: AppStrings.dietTitle,
        icon: Icons.restaurant_menu_outlined,
        message: 'General diet guidance is still available once you sign in '
            'and start tracking your habits.',
      );
    }

    final hasData = !controller.dietPlan.isEmpty;
    if (controller.isLoading && !hasData) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.dietTitle)),
        body: const SafeArea(
          child: LoadingWidget(message: AppStrings.loading),
        ),
      );
    }

    // A failed read is deliberately NOT a full-screen error state: the meal
    // plan and the goal fall back to safe defaults, so the module stays usable
    // and the failure is reported through the dismissible banner below.

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dietTitle),
        actions: [
          IconButton(
            key: const Key('diet_preferences_action'),
            tooltip: AppStrings.wellnessPreferencesTitle,
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => _openPreferences(uid),
          ),
          IconButton(
            key: const Key('diet_ai_action'),
            tooltip: AppStrings.askAiAboutDiet,
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSizes.paddingXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: AppStrings.yourDietPlan,
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
                  message:
                      controller.errorMessage ?? AppStrings.dietExerciseLoadFailed,
                  onRetry: () => controller.load(uid),
                  onDismiss: controller.clearError,
                  isLoading: controller.isLoading,
                ),
              const SectionTitle(AppStrings.todaysGoalLabel),
              _WellnessGoalCard(
                preferences: controller.preferences,
                onTap: () => _openPreferences(uid),
              ),
              DietSummaryCard(plan: controller.dietPlan, onViewFullPlan: _openFullPlan),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingSm,
                ),
                child: PrimaryButton(
                  key: const Key('ask_ai_assistant_button'),
                  label: AppStrings.askAiAboutDiet,
                  icon: Icons.smart_toy_outlined,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.aiAssistant),
                ),
              ),
              const SizedBox(height: AppSizes.paddingSm),
              WellnessDisclaimer(text: AppStrings.dietPlanDisclaimer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card showing the current wellness goal, food preference and activity level.
class _WellnessGoalCard extends StatelessWidget {
  final DietExercisePreferences preferences;
  final VoidCallback onTap;

  const _WellnessGoalCard({
    required this.preferences,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: InkWell(
        key: const Key('wellness_goal_card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMd),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child:
                    const Icon(Icons.flag_outlined, color: AppColors.secondary),
              ),
              const SizedBox(width: AppSizes.paddingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.wellnessGoalLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preferences.hasSelectedGoal
                          ? preferences.goal.label
                          : AppStrings.notSpecifiedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${preferences.foodPreference.label} • '
                      '${preferences.activityLevelLabel}',
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
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}