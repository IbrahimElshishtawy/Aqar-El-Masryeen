abstract final class PhoneUtils {
  static String normalize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      return '';
    }
    if (cleaned.startsWith('+')) {
      return '+${cleaned.replaceAll(RegExp(r'[^\d]'), '')}';
    }
    if (cleaned.startsWith('00')) {
      return '+${cleaned.substring(2)}';
    }
    if (cleaned.startsWith('20')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0')) {
      return '+20${cleaned.substring(1)}';
    }
    return '+$cleaned';
  }

  static String syntheticEmail(String phone) {
    final digits = normalize(phone).replaceAll(RegExp(r'[^\d]'), '');
    return 'auth_$digits@auth.aqarelmasryeen.app';
  }

  static String mask(String phone) {
    final normalized = normalize(phone);
    if (normalized.length <= 6) {
      return normalized;
    }

    final start = normalized.substring(0, 4);
    final end = normalized.substring(normalized.length - 2);
    return '$start ****** $end';
  }
}
