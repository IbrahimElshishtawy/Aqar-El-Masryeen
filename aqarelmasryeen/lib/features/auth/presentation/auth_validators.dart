class AuthValidators {
  const AuthValidators._();

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length < 8) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();
    final isValid = RegExp(
      r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    ).hasMatch(email);
    if (!isValid) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? name(String? value) {
    if ((value ?? '').trim().length < 2) {
      return 'Enter the partner name.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    if (!hasLetter || !hasNumber) {
      return 'Use letters and numbers for a stronger password.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '') != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? otp(String? value) {
    if ((value ?? '').trim().length != 6) {
      return 'Enter the 6-digit code.';
    }
    return null;
  }
}
