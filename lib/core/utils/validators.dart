abstract final class MazonnValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'Enter a valid phone number';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid price';
    return null;
  }
}
