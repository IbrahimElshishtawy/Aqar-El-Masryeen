import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

AppException mapException(Object error) {
  if (error is AppException) {
    return error;
  }
  if (error is FirebaseAuthException) {
    return AppException(
      error.message ?? 'Authentication failed.',
      code: error.code,
    );
  }
  if (error is FirebaseException) {
    return AppException(
      error.message ?? 'Firebase request failed.',
      code: error.code,
    );
  }
  return AppException(error.toString());
}
