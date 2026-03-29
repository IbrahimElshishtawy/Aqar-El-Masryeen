class PasswordPolicyResult {
  const PasswordPolicyResult({
    required this.value,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialCharacter,
  });

  final String value;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialCharacter;

  bool get isStrong =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialCharacter;

  double get progress {
    final checks = <bool>[
      hasMinLength,
      hasUppercase,
      hasLowercase,
      hasDigit,
      hasSpecialCharacter,
    ];
    final passed = checks.where((item) => item).length;
    return passed / checks.length;
  }

  String get summary {
    if (value.isEmpty) {
      return 'Use at least 8 characters with upper/lowercase letters, a number, and a symbol.';
    }
    if (isStrong) {
      return 'Strong password ready for secure sign-in.';
    }
    return 'Add the missing rules to continue securely.';
  }
}

abstract final class PasswordPolicy {
  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _special = RegExp(
    r'[!@#$%^&*(),.?":{}|<>\[\]\\\/_\-+=~`]',
  );

  static PasswordPolicyResult evaluate(String value) {
    return PasswordPolicyResult(
      value: value,
      hasMinLength: value.length >= 8,
      hasUppercase: _uppercase.hasMatch(value),
      hasLowercase: _lowercase.hasMatch(value),
      hasDigit: _digit.hasMatch(value),
      hasSpecialCharacter: _special.hasMatch(value),
    );
  }

  static String? validate(String value) {
    final result = evaluate(value);
    if (result.isStrong) {
      return null;
    }
    return result.summary;
  }
}
