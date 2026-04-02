import 'package:aqarelmasryeen/core/errors/app_exception.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService(this._localAuth);

  final LocalAuthentication _localAuth;

  Future<bool> canCheckBiometrics() async {
    return await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
  }

  Future<bool> authenticate() async {
    final available = await canCheckBiometrics();
    if (!available) {
      throw const AppException(
        'Biometric authentication is not available on this device.',
      );
    }

    return _localAuth.authenticate(
      localizedReason: 'Unlock your finance workspace',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}
