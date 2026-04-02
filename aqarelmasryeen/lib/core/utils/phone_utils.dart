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
}
