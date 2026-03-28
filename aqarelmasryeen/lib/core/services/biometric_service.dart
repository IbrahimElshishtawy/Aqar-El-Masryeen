import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isDeviceSupported() => _localAuthentication.isDeviceSupported();

  Future<bool> canCheckBiometrics() => _localAuthentication.canCheckBiometrics;

  Future<bool> authenticate() async {
    final supported = await isDeviceSupported();
    if (!supported) {
      return false;
    }

    return _localAuthentication.authenticate(
      localizedReason: 'Unlock Aqar El Masryeen',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }
}
