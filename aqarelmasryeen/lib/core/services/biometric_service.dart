import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isDeviceSupported() => _localAuthentication.isDeviceSupported();

  Future<bool> canCheckBiometrics() => _localAuthentication.canCheckBiometrics;

  Future<List<BiometricType>> getAvailableBiometrics() {
    return _localAuthentication.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometrics() async {
    final supported = await isDeviceSupported();
    if (!supported) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason: 'Unlock Aqar El Masryeen',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }

  Future<bool> authenticateWithDeviceCredential() async {
    final supported = await isDeviceSupported();
    if (!supported) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason: 'Verify device access for Aqar El Masryeen',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }

  String preferredBiometricLabel(List<BiometricType> availableBiometrics) {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Use Face ID';
    }
    if (availableBiometrics.contains(BiometricType.fingerprint) ||
        availableBiometrics.contains(BiometricType.strong) ||
        availableBiometrics.contains(BiometricType.weak)) {
      return 'Use Fingerprint';
    }
    return 'Use Biometrics';
  }
}
