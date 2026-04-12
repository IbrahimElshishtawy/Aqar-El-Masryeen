import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAvailability {
  const BiometricAvailability({
    required this.isDeviceSupported,
    required this.availableBiometrics,
  });

  final bool isDeviceSupported;
  final List<BiometricType> availableBiometrics;

  bool get canUseSecureUnlock =>
      isDeviceSupported || availableBiometrics.isNotEmpty;

  String get methodsLabel {
    if (availableBiometrics.isEmpty) {
      return 'Device credentials';
    }

    final labels = <String>{};
    for (final biometric in availableBiometrics) {
      switch (biometric) {
        case BiometricType.face:
          labels.add('Face unlock');
        case BiometricType.fingerprint:
          labels.add('Fingerprint');
        case BiometricType.iris:
          labels.add('Iris');
        case BiometricType.strong:
          labels.add('Strong biometrics');
        case BiometricType.weak:
          labels.add('Biometrics');
      }
    }
    labels.add('Device passcode/PIN');
    return labels.join(' / ');
  }
}

class BiometricService {
  BiometricService(this._localAuth);

  final LocalAuthentication _localAuth;

  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on LocalAuthException catch (error, stackTrace) {
      switch (error.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          debugPrint('Biometric methods unavailable: ${error.code.name}');
          debugPrintStack(stackTrace: stackTrace, maxFrames: 4);
          return const <BiometricType>[];
        default:
          rethrow;
      }
    }
  }

  Future<BiometricAvailability> getAvailability() async {
    final methods = await getAvailableBiometrics();
    var isDeviceSupported = false;
    try {
      isDeviceSupported = await _localAuth.isDeviceSupported();
    } on LocalAuthException catch (error, stackTrace) {
      debugPrint('Secure unlock support check failed: ${error.code.name}');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 4);
    }
    return BiometricAvailability(
      isDeviceSupported: isDeviceSupported,
      availableBiometrics: methods,
    );
  }

  Future<bool> authenticate({
    String reason = 'Unlock your finance workspace',
  }) async {
    final availability = await getAvailability();
    if (!availability.canUseSecureUnlock) {
      throw const AppException(
        'Secure device authentication is not available on this device.',
      );
    }

    return _localAuth.authenticate(
      localizedReason: reason,
      biometricOnly: false,
      sensitiveTransaction: true,
      persistAcrossBackgrounding: true,
    );
  }
}
