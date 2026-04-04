import 'package:aqarelmasryeen/core/config/app_config.dart';

class AuthValidators {
  const AuthValidators._();

  static String? email(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'البريد الإلكتروني مطلوب.';
    }
    final email = (value ?? '').trim();
    final isValid = RegExp(
      r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    ).hasMatch(email);
    if (!isValid) {
      return 'أدخل بريدًا إلكترونيًا صحيحًا.';
    }
    return null;
  }

  static String? name(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'الاسم الكامل مطلوب.';
    }
    if (input.length < 3) {
      return 'أدخل الاسم الكامل للشريك.';
    }
    if (!RegExp(r"^[A-Za-z\u0600-\u06FF\s'.-]+$").hasMatch(input)) {
      return 'استخدم الحروف فقط في اسم الشريك.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'كلمة المرور مطلوبة.';
    }
    if (password.length < AppConfig.minPasswordLength) {
      return 'استخدم ${AppConfig.minPasswordLength} أحرف على الأقل.';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=/\[\]\\;]',
    ).hasMatch(password);
    if (password.contains(' ')) {
      return 'يجب ألا تحتوي كلمة المرور على مسافات.';
    }
    if (!hasUpper || !hasLower || !hasNumber || !hasSymbol) {
      return 'استخدم حروفًا كبيرة وصغيرة وأرقامًا ورموزًا.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'أدخل كلمة المرور.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'أكد كلمة المرور.';
    }
    if ((value ?? '') != password) {
      return 'كلمتا المرور غير متطابقتين.';
    }
    return null;
  }
}
