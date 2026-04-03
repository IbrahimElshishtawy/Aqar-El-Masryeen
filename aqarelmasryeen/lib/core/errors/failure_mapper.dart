import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

AppException mapException(Object error) {
  if (error is AppException) {
    return error;
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return const AppException(
          'The verification code is invalid or has expired. Request a new code and try again.',
          code: 'invalid_otp',
        );
      case 'session-expired':
        return const AppException(
          'The verification session expired. Request a new code.',
          code: 'otp_expired',
        );
      case 'invalid-phone-number':
        return const AppException(
          'Enter a valid phone number with country code.',
          code: 'invalid_phone',
        );
      case 'too-many-requests':
        return const AppException(
          'Too many attempts were detected. Wait a moment and try again.',
          code: 'rate_limited',
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return const AppException(
          'Incorrect credentials. Check your email or phone and password.',
          code: 'invalid_credentials',
        );
      case 'email-already-in-use':
        return const AppException(
          'This email is already linked to another account.',
          code: 'email_in_use',
        );
      case 'weak-password':
        return const AppException(
          'Use a stronger password with upper and lower case letters, numbers, and symbols.',
          code: 'weak_password',
        );
      case 'user-disabled':
        return const AppException(
          'This account is disabled. Contact the administrator.',
          code: 'account_disabled',
        );
      case 'operation-not-allowed':
        return const AppException(
          'This sign-in method is not enabled in Firebase.',
          code: 'operation_not_allowed',
        );
      default:
        return AppException(
          error.message ?? 'Authentication failed.',
          code: error.code,
        );
    }
  }
  if (error is LocalAuthException) {
    switch (error.code) {
      case LocalAuthExceptionCode.userCanceled:
        return const AppException(
          'Authentication was canceled.',
          code: 'local_auth_canceled',
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return const AppException(
          'Set up biometrics or a device passcode to enable secure unlock.',
          code: 'local_auth_not_configured',
        );
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return const AppException(
          'Biometric authentication is temporarily locked. Use device credentials or try again later.',
          code: 'local_auth_lockout',
        );
      default:
        return AppException(
          error.description ?? 'Secure authentication failed.',
          code: error.code.name,
        );
    }
  }
  if (error is FirebaseException) {
    if (error.plugin == 'cloud_firestore') {
      final message = error.message ?? '';
      if (message.contains('database (default) does not exist')) {
        return const AppException(
          'Cloud Firestore is not set up for this Firebase project yet. Create the default Firestore database in Firebase Console, then try again.',
          code: 'firestore_not_configured',
        );
      }
      switch (error.code) {
        case 'unavailable':
          return const AppException(
            'Cloud Firestore is unavailable right now. If this is a new project, create the default Firestore database first.',
            code: 'firestore_unavailable',
          );
        case 'permission-denied':
          return const AppException(
            'Firestore access was denied. Check your Firebase App Check and Firestore security rules.',
            code: 'firestore_permission_denied',
          );
      }
    }
    return AppException(
      error.message ?? 'Firebase request failed.',
      code: error.code,
    );
  }
  return AppException(error.toString());
}
