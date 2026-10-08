import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/diet_exercise_controller.dart';

/// Shared behaviour for the Phase 15 screens.
///
/// Every screen reads the signed-in uid and kicks off its data load from
/// `didChangeDependencies`. The controller notifies listeners synchronously, so
/// calling it directly from there would mark widgets dirty while Flutter is
/// still building. [runAfterFrame] defers the work until the current frame is
/// done, so a load can never be started while widgets are being built.
mixin DietExerciseScreenState<T extends StatefulWidget> on State<T> {
  /// The controller injected by the app.
  DietExerciseController get dietExerciseController =>
      context.read<DietExerciseController>();

  /// The signed-in user id, or null when signed out.
  String? get signedInUid => context.read<AuthProvider>().currentUid;

  /// Runs [action] right after the current frame, once Flutter is no longer
  /// building widgets.
  void runAfterFrame(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }
}