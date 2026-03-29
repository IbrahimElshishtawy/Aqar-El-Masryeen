import 'package:aqarelmasryeen/firebase_options.dart' as generated;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  static bool get isConfiguredForCurrentPlatform {
    try {
      currentPlatform;
      return true;
    } on UnsupportedError {
      return false;
    }
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return generated.DefaultFirebaseOptions.currentPlatform;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return generated.DefaultFirebaseOptions.currentPlatform;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options are not configured for this platform.',
        );
    }
  }
}
