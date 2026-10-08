import '../../../core/constants/constants.dart';
import '../../../core/utils/app_utils.dart';

/// Form validation helpers for authentication inputs.
abstract final class AuthValidator {
  /// Validates the full name field.
  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return AppStrings.nameRequired;
    }
    if (name.length < 2) {
      return AppStrings.nameRequired;
    }
    return null;
  }

  /// Validates the email field format.
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return AppStrings.emailRequired;
    }
    if (!AppUtils.isValidEmail(email)) {
      return AppStrings.emailInvalid;
    }
    return null;
  }

  /// Validates the password field length.
  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (password.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validates the confirm password field matches the password.
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != password) {
      return AppStrings.passwordMismatch;
    }
    return null;
  }
}
