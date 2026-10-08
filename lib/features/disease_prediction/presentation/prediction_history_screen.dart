import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import 'providers/disease_prediction_controller.dart';
import 'widgets/widgets.dart';

/// Prediction History screen.
///
/// Displays the user's prediction history. The current history is **mock**
/// data (plus any predictions created during this session) — it is not yet
/// persisted. Persistence will be added in a later phase.
class PredictionHistoryScreen extends StatelessWidget {
  const PredictionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<DiseasePredictionController>().history;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.predictionHistoryTitle)),
      body: SafeArea(
        child: history.isEmpty
            ? EmptyPredictionHistory(
                message: AppStrings.emptyPredictionHistory,
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                itemCount: history.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.paddingSm),
                itemBuilder: (context, index) => PredictionHistoryCard(
                  item: history[index],
                ),
              ),
      ),
    );
  }
}
