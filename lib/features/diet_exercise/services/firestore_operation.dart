import 'dart:async';

import '../../../core/errors/exceptions.dart';

/// Upper bound for a single Phase 15 Firestore read or write.
///
/// Firestore can wait forever for a server that never answers (offline device,
/// dropped connection, unreachable project). Wrapping every wellness call in
/// this timeout guarantees that each Future completes, so the controller's
/// `finally` blocks always run and `isLoading` / `isSaving` are always reset
/// instead of leaving a spinner or disabled buttons on screen forever.
const Duration firestoreOperationTimeout = Duration(seconds: 15);

/// Message used when an operation exceeds [firestoreOperationTimeout].
const String firestoreTimeoutMessage =
    'The request took too long and was cancelled. Please check your '
    'connection and try again.';

/// Runs one Firestore [operation] under [timeout] and maps every failure to a
/// safe, user-facing [AppException].
///
/// [failureMessage] is the fallback used when the cause cannot be classified.
/// Classified failures (permission, connectivity, timeout) keep their own
/// message so the UI can tell them apart. Document contents, credentials and
/// raw payloads are never surfaced.
///
/// [timeout] is injectable only so tests can exercise the timeout path
/// without waiting for the production budget.
Future<T> runFirestoreOperation<T>({
  required Future<T> Function() operation,
  required String failureMessage,
  Duration timeout = firestoreOperationTimeout,
}) async {
  try {
    return await operation().timeout(timeout);
  } on AppException {
    // Already classified (for example a missing user id from _requireAuth).
    rethrow;
  } on TimeoutException {
    throw const AppException(
      statusCode: 408,
      message: firestoreTimeoutMessage,
    );
  } catch (error) {
    throw AppException(message: mapFirestoreError(error, failureMessage));
  }
}

/// Maps a Firestore failure to a safe, user-facing message.
///
/// Follows the same classification the rest of the app already uses
/// (see `profile_service.dart` and `appointment_service.dart`) so a
/// permission problem never masquerades as a generic failure.
String mapFirestoreError(Object error, String failureMessage) {
  if (error is AppException) return error.message;
  final text = error.toString().toLowerCase();
  if (text.contains('permission-denied') || text.contains('permission denied')) {
    // A permission failure is a rules/configuration problem. The Firebase
    // session itself is still valid, so we must not tell the user to sign out
    // and sign in again: that cannot fix owner-scoped rules and only confuses.
    return 'You do not have permission to access your wellness data. '
        'Please try again later.';
  }
  if (text.contains('unavailable') ||
      text.contains('network') ||
      text.contains('offline') ||
      text.contains('failed host lookup')) {
    return 'No internet connection. Please check your connection and try '
        'again.';
  }
  if (text.contains('invalid-argument') || text.contains('data-loss')) {
    return 'Your saved wellness data could not be read. Please try again.';
  }
  return failureMessage;
}
