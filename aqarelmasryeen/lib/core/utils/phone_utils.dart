class PhoneUtils {
  const PhoneUtils._();

  static String normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+20')) return digits;
    if (digits.startsWith('20')) return '+$digits';
    if (digits.startsWith('0')) return '+2${digits.substring(1)}';
    return digits.startsWith('+') ? digits : '+$digits';
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
