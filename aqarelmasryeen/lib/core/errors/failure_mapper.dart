import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

AppException mapException(Object error) {
  if (error is AppException) {
    return error;
  }
  if (error is FirebaseAuthException) {
    final message = error.message ?? '';
    switch (error.code) {
      case 'invalid-email':
        return const AppException(
          'أدخل بريدًا إلكترونيًا صحيحًا.',
          code: 'invalid_email',
        );
      case 'too-many-requests':
        return const AppException(
          'تم رصد عدد كبير من المحاولات. انتظر قليلًا ثم حاول مرة أخرى.',
          code: 'rate_limited',
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return const AppException(
          'البريد الإلكتروني أو كلمة المرور غير صحيحة. راجع البيانات وحاول مرة أخرى.',
          code: 'invalid_credentials',
        );
      case 'email-already-in-use':
        return const AppException(
          'هذا البريد الإلكتروني مستخدم بالفعل.',
          code: 'email_in_use',
        );
      case 'weak-password':
        return const AppException(
          'استخدم كلمة مرور أقوى تحتوي على حروف كبيرة وصغيرة وأرقام ورموز.',
          code: 'weak_password',
        );
      case 'user-disabled':
        return const AppException(
          'هذا الحساب معطل. تواصل مع المسؤول.',
          code: 'account_disabled',
        );
      case 'operation-not-allowed':
        return const AppException(
          'تسجيل الدخول بالبريد الإلكتروني وكلمة المرور غير مفعّل في Firebase Authentication.',
          code: 'operation_not_allowed',
        );
      case 'network-request-failed':
        return const AppException(
          'حدث خطأ في الشبكة. تحقق من الاتصال ثم حاول مرة أخرى.',
          code: 'network_error',
        );
      case 'requires-recent-login':
        return const AppException(
          'يرجى تسجيل الدخول مرة أخرى قبل تعديل بيانات الحساب الحساسة.',
          code: 'requires_recent_login',
        );
      default:
        return AppException(
          message.isEmpty ? 'فشلت عملية التحقق.' : message,
          code: error.code,
        );
    }
  }
  if (error is LocalAuthException) {
    switch (error.code) {
      case LocalAuthExceptionCode.userCanceled:
        return const AppException(
          'تم إلغاء عملية التحقق.',
          code: 'local_auth_canceled',
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return const AppException(
          'قم بإعداد البصمة أو رمز قفل الجهاز لتفعيل الفتح الآمن.',
          code: 'local_auth_not_configured',
        );
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return const AppException(
          'التحقق بالبصمة مقفل مؤقتًا. استخدم بيانات قفل الجهاز أو حاول لاحقًا.',
          code: 'local_auth_lockout',
        );
      default:
        return AppException(
          error.description ?? 'فشل التحقق الآمن.',
          code: error.code.name,
        );
    }
  }
  if (error is FirebaseException) {
    if (error.plugin == 'cloud_firestore') {
      final message = error.message ?? '';
      if (message.contains('database (default) does not exist')) {
        return const AppException(
          'لم يتم إعداد Cloud Firestore لهذا المشروع بعد. أنشئ قاعدة البيانات الافتراضية من Firebase Console ثم حاول مرة أخرى.',
          code: 'firestore_not_configured',
        );
      }
      switch (error.code) {
        case 'unavailable':
          return const AppException(
            'خدمة Cloud Firestore غير متاحة الآن. إذا كان المشروع جديدًا فأنشئ قاعدة البيانات الافتراضية أولًا.',
            code: 'firestore_unavailable',
          );
        case 'permission-denied':
          return const AppException(
            'تم رفض الوصول إلى Firestore. راجع App Check وقواعد الحماية في Firestore.',
            code: 'firestore_permission_denied',
          );
      }
    }
    return AppException(error.message ?? 'فشل طلب Firebase.', code: error.code);
  }
  return AppException(error.toString());
}
