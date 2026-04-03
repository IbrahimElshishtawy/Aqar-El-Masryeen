import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/utils/phone_utils.dart';

class AuthValidators {
  const AuthValidators._();

  static String? identifier(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Enter your email or phone number.';
    }
    if (input.contains('@')) {
      return email(input);
    }
    return phone(input);
  }

  static String? phone(String? value) {
    final phone = (value ?? '').trim();
    final normalized = PhoneUtils.normalize(phone);
    final isValid = RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized);
    if (!isValid) {
      return 'Enter a valid phone number with country code.';
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
    final input = (value ?? '').trim();
    if (input.length < 3) {
      return 'Enter the full partner name.';
    }
    if (!RegExp(r"^[A-Za-z\u0600-\u06FF\s'.-]+$").hasMatch(input)) {
      return 'Use letters only for the partner name.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < AppConfig.minPasswordLength) {
      return 'Use at least ${AppConfig.minPasswordLength} characters.';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\[\]\\;]').hasMatch(
      password,
    );
    if (password.contains(' ')) {
      return 'Password must not contain spaces.';
    }
    if (!hasUpper || !hasLower || !hasNumber || !hasSymbol) {
      return 'Use upper and lower case letters, numbers, and symbols.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Enter your password.';
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
