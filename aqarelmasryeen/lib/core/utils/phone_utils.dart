class PhoneUtils {
  const PhoneUtils._();

  static String normalize(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'[\s-]'), '');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');

    if (trimmed.startsWith('+')) {
      return '+$digitsOnly';
    }
    if (digitsOnly.startsWith('20')) {
      return '+$digitsOnly';
    }
    if (digitsOnly.startsWith('0')) {
      return '+20${digitsOnly.substring(1)}';
    }
    return '+$digitsOnly';
  }

  static String syntheticEmail(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return 'auth_$digits@auth.aqarelmasryeen.app';
  }

  static String maskForDisplay(String raw) {
    final normalized = normalize(raw);
    if (normalized.length <= 5) return normalized;
    final leading = normalized.substring(0, 4);
    final trailing = normalized.substring(normalized.length - 2);
    return '$leading ${'*' * (normalized.length - 6)} $trailing';
  }
}
