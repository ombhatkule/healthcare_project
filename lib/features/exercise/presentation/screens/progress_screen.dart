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

/// Progress overview: today plus the last seven days.
///
/// Uses dependency-free Flutter progress widgets rather than a chart package.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
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
    runAfterFrame(() {
      dietExerciseController.load(uid);
      dietExerciseController.loadHistory(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().currentUid;
    final controller = context.watch<DietExerciseController>();

    if (uid == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.progressTitle)),
        body: const SafeArea(
          child: EmptyStateWidget(
            icon: Icons.lock_outline,
            title: AppStrings.signInToTrack,
          ),
        ),
      );
    }

    final history = controller.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.progressTitle),
        actions: [
          IconButton(
            key: const Key('progress_refresh_action'),
            tooltip: AppStrings.retry,
            icon: const Icon(Icons.refresh),
            onPressed: controller.isHistoryLoading
                ? null
                : () => controller.loadHistory(uid),
          ),
        ],
      ),
      body: SafeArea(
        child: controller.isHistoryLoading && history.isEmpty
            ? const LoadingWidget(message: AppStrings.loading)
            : RefreshIndicator(
                onRefresh: () => controller.loadHistory(uid),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSizes.paddingXl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (controller.hasError)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.paddingMd,
                          ),
                          child: Text(
                            controller.errorMessage ??
                                AppStrings.historyLoadFailed,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      _TodaySection(controller: controller),
                      if (history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSizes.paddingLg),
                          child: EmptyStateWidget(
                            icon: Icons.insights_outlined,
                            title: AppStrings.noHistoryLabel,
                            subtitle: AppStrings.noHistoryMessage,
                          ),
                        )
                      else
                        ..._weeklySections(controller, history),
                      const SizedBox(height: AppSizes.paddingSm),
                      const WellnessDisclaimer(compact: true),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  List<Widget> _weeklySections(
    DietExerciseController controller,
    List<DailyActivitySummary> history,
  ) {
    final activeDays = history.where((day) => day.exerciseMinutes > 0).length;
    final waterDays = history.where((day) => day.waterProgress >= 1).length;
    final totalMinutes = history.fold<int>(
      0,
      (sum, day) => sum + day.exerciseMinutes,
    );
    final totalCompleted = history.fold<int>(
      0,
      (sum, day) => sum + day.completedExercises,
    );

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                label: AppStrings.exerciseConsistencyLabel,
                value: '$activeDays / ${history.length}',
                caption: AppStrings.daysLabel,
                progress: history.isEmpty ? 0 : activeDays / history.length,
              ),
            ),
            const SizedBox(width: AppSizes.paddingSm),
            Expanded(
              child: _StatCard(
                label: AppStrings.waterConsistencyLabel,
                value: '$waterDays / ${history.length}',
                caption: AppStrings.daysLabel,
                progress:
                    history.isEmpty ? 0 : waterDays / history.length,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ),
      _ChartCard(
        title: '${AppStrings.exerciseProgressLabel} • '
            '${AppStrings.lastSevenDaysLabel}',
        footer: '$totalMinutes ${AppStrings.minutesUnit} total',
        child: ProgressChart(
          data: history,
          valueOf: (day) => day.exerciseMinutes.toDouble(),
          labelBuilder: (value) => value.toInt().toString(),
          barColor: AppColors.primary,
        ),
      ),
      _ChartCard(
        title: AppStrings.waterIntakeLabel,
        footer:
            '$totalCompleted ${AppStrings.completedWorkoutsLabel.toLowerCase()}',
        child: ProgressChart(
          data: history,
          valueOf: (day) => day.waterGlasses.toDouble(),
          labelBuilder: (value) => value.toInt().toString(),
          barColor: AppColors.info,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('progress_open_activity'),
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.dietExerciseActivity),
            icon: const Icon(Icons.directions_walk_outlined, size: 18),
            label: const Text(AppStrings.dailyActivityTitle),
          ),
        ),
      ),
    ];
  }
}

class _TodaySection extends StatelessWidget {
  final DietExerciseController controller;

  const _TodaySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final today = controller.todaySummary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.todayLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSm),
          ActivityProgressCard(
            icon: Icons.local_drink_outlined,
            label: AppStrings.waterIntakeLabel,
            value: '${today.waterGlasses} / ${today.waterGoal}',
            supportingText: AppStrings.glassesUnit,
            progress: today.waterProgress,
            color: AppColors.info,
          ),
          ActivityProgressCard(
            icon: Icons.timer_outlined,
            label: AppStrings.exerciseProgressLabel,
            value:
                '${today.exerciseMinutes} / ${controller.exerciseGoalMinutes}',
            supportingText: AppStrings.minutesUnit,
            progress: controller.exerciseProgress,
          ),
          ActivityProgressCard(
            icon: Icons.check_circle_outline,
            label: AppStrings.completedWorkoutsLabel,
            value: '${today.completedExercises}',
            supportingText: AppStrings.todayLabel,
            progress: controller.exerciseProgress,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String footer;

  const _ChartCard({
    required this.title,
    required this.child,
    required this.footer,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingMd),
            child,
            const SizedBox(height: AppSizes.paddingSm),
            Text(
              footer,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final double progress;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.progress,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: safeProgress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}