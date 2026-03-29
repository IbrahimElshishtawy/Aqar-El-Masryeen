import 'package:aqarelmasryeen/core/firebase/firebase_options.dart';
import 'package:aqarelmasryeen/core/firebase/dev_phone_auth_config.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class BootstrapState {
  const BootstrapState({
    required this.firebaseConfigured,
    required this.firebaseReady,
    this.firebaseError,
  });

  final bool firebaseConfigured;
  final bool firebaseReady;
  final String? firebaseError;
}

abstract final class AppBootstrap {
  static Future<BootstrapState> initialize() async {
    if (!DefaultFirebaseOptions.isConfiguredForCurrentPlatform) {
      return const BootstrapState(
        firebaseConfigured: false,
        firebaseReady: false,
      );
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Touch the instances early so auth, Firestore, and Storage all resolve
      // against the same configured default app.
      FirebaseAuth.instance;
      FirebaseFirestore.instance;
      FirebaseStorage.instance;

      await _configurePhoneAuthTesting();

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await _activateAppCheck();

      return const BootstrapState(
        firebaseConfigured: true,
        firebaseReady: true,
      );
    } catch (error) {
      debugPrint('Firebase bootstrap failed: $error');
      return BootstrapState(
        firebaseConfigured: true,
        firebaseReady: false,
        firebaseError: error.toString(),
      );
    }
  }

  static Future<void> _activateAppCheck() async {
    if (!kReleaseMode) {
      return;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    } catch (error) {
      debugPrint('Firebase App Check activation skipped: $error');
    }
  }

  static Future<void> _configurePhoneAuthTesting() async {
    if (!DevPhoneAuthConfig.isEnabled) {
      return;
    }

    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
        phoneNumber: DevPhoneAuthConfig.phoneNumber,
        smsCode: DevPhoneAuthConfig.smsCode,
      );
    } catch (error) {
      debugPrint('Phone auth testing configuration skipped: $error');
    }
  }
}
