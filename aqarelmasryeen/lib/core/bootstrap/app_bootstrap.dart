import 'dart:ui';

import 'package:aqarelmasryeen/core/firebase/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await _activateAppCheck();

      return const BootstrapState(firebaseConfigured: true, firebaseReady: true);
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
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
      );
    } catch (error) {
      debugPrint('Firebase App Check activation skipped: $error');
    }
  }
}
