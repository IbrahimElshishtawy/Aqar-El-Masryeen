import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '__ANDROID_API_KEY__',
    appId: '__ANDROID_APP_ID__',
    messagingSenderId: '__MESSAGING_SENDER_ID__',
    projectId: '__PROJECT_ID__',
    storageBucket: '__STORAGE_BUCKET__',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '__IOS_API_KEY__',
    appId: '__IOS_APP_ID__',
    messagingSenderId: '__MESSAGING_SENDER_ID__',
    projectId: '__PROJECT_ID__',
    storageBucket: '__STORAGE_BUCKET__',
    iosBundleId: '__IOS_BUNDLE_ID__',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '__MACOS_API_KEY__',
    appId: '__MACOS_APP_ID__',
    messagingSenderId: '__MESSAGING_SENDER_ID__',
    projectId: '__PROJECT_ID__',
    storageBucket: '__STORAGE_BUCKET__',
    iosBundleId: '__MACOS_BUNDLE_ID__',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '__WINDOWS_API_KEY__',
    appId: '__WINDOWS_APP_ID__',
    messagingSenderId: '__MESSAGING_SENDER_ID__',
    projectId: '__PROJECT_ID__',
    storageBucket: '__STORAGE_BUCKET__',
  );

  static bool get isConfiguredForCurrentPlatform {
    final options = _currentPlatformOrNull();
    if (options == null) {
      return false;
    }

    return !options.apiKey.startsWith('__') &&
        !options.appId.startsWith('__') &&
        !options.projectId.startsWith('__');
  }

  static FirebaseOptions get currentPlatform {
    final options = _currentPlatformOrNull();
    if (options == null) {
      throw UnsupportedError('Firebase options are not configured for this platform.');
    }
    return options;
  }

  static FirebaseOptions? _currentPlatformOrNull() {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }
}
