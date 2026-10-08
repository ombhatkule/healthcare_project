import '../../../core/constants/constants.dart';

/// Form validation helpers for the user profile.
/// Medical values (height, weight etc.) are only validated for reasonable
/// numeric input — no medical judgment is made based on the entered values.
abstract final class ProfileValidator {
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

  /// Validates a phone number field. Empty is allowed unless [required].
  static String? validatePhone(String? value, {bool required = false}) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return required ? AppStrings.invalidPhone : null;
    }
    return _isValidPhone(phone) ? null : AppStrings.invalidPhone;
  }

  /// Validates the emergency contact, which is considered required contact
  /// information but empty is tolerated to avoid blocking profile creation.
  static String? validateEmergencyContact(String? value) =>
      validatePhone(value);

  /// Validates an optional numeric field (e.g. height / weight).
  static String? validateNumber(String? value, {required String message}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) {
      return message;
    }
    return null;
  }

  static String? validateHeight(String? value) => validateNumber(
        value,
        message: AppStrings.invalidHeight,
      );

  static String? validateWeight(String? value) => validateNumber(
        value,
        message: AppStrings.invalidWeight,
      );

  static bool _isValidPhone(String phone) {
    return RegExp(r'^[+]?[0-9\s\-()]{7,20}$').hasMatch(phone);
  }
}
