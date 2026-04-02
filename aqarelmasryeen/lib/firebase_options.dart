import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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
        return android;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCL-Y4qhkdOT80u7Ro1vaL9lA7idcUie3Y',
    appId: '1:55493381725:android:514946b81ac7baf516c7b4',
    messagingSenderId: '55493381725',
    projectId: 'aqar-146b6',
    storageBucket: 'aqar-146b6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:55493381725:ios:aea3632d8f9017b716c7b4',
    messagingSenderId: '55493381725',
    projectId: 'aqar-146b6',
    storageBucket: 'aqar-146b6.firebasestorage.app',
    iosBundleId: 'com.example.aqarelmasryeen',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_MACOS_API_KEY',
    appId: '1:55493381725:ios:aea3632d8f9017b716c7b4',
    messagingSenderId: '55493381725',
    projectId: 'aqar-146b6',
    storageBucket: 'aqar-146b6.firebasestorage.app',
    iosBundleId: 'com.example.aqarelmasryeen',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WINDOWS_API_KEY',
    appId: '1:55493381725:web:edfe77f4718f699416c7b4',
    messagingSenderId: '55493381725',
    projectId: 'aqar-146b6',
    storageBucket: 'aqar-146b6.firebasestorage.app',
    authDomain: 'aqar-146b6.firebaseapp.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:55493381725:web:36b87d058fc9e81f16c7b4',
    messagingSenderId: '55493381725',
    projectId: 'aqar-146b6',
    storageBucket: 'aqar-146b6.firebasestorage.app',
    authDomain: 'aqar-146b6.firebaseapp.com',
    measurementId: 'G-REPLACE_ME',
  );
}
