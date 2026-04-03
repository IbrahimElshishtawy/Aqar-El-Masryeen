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
          'Enter a valid email address.',
          code: 'invalid_email',
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
          'Incorrect email or password. Check your credentials and try again.',
          code: 'invalid_credentials',
        );
      case 'email-already-in-use':
        return const AppException(
          'This email is already in use.',
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
          'Email/password sign-in is not enabled in Firebase Authentication.',
          code: 'operation_not_allowed',
        );
      case 'network-request-failed':
        return const AppException(
          'Network error. Check your connection and try again.',
          code: 'network_error',
        );
      case 'requires-recent-login':
        return const AppException(
          'Please sign in again before changing sensitive account details.',
          code: 'requires_recent_login',
        );
      default:
        return AppException(
          message.isEmpty ? 'Authentication failed.' : message,
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
