/// Shared form validators used across auth, profile, and calendar forms.
abstract final class Validators {
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredMessage = required(value, fieldName: 'Email');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final normalized = value!.trim();
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final requiredMessage = required(value, fieldName: 'Password');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (value!.trim().length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? confirmation(String? value, String originalValue) {
    final requiredMessage = required(value, fieldName: 'Confirmation');
    if (requiredMessage != null) {
      return requiredMessage;
    }

    if (value!.trim() != originalValue.trim()) {
      return 'Values do not match.';
    }
    return null;
  }
}
