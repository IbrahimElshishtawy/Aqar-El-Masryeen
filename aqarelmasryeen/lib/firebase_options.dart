import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
    apiKey: 'AIzaSyDSm9TbHE-Fo-zaJD5gx-mAQE_6RrYz7ZI',
    appId: '1:288037062988:android:ba75ae2955602da1a127e9',
    messagingSenderId: '288037062988',
    projectId: 'aqarr-cfd58',
    storageBucket: 'aqarr-cfd58.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBx7NUVZZYAxjqfEyl7PVZKzVJDOur0fhE',
    appId: '1:288037062988:ios:72dbe6d71916d24aa127e9',
    messagingSenderId: '288037062988',
    projectId: 'aqarr-cfd58',
    storageBucket: 'aqarr-cfd58.firebasestorage.app',
    iosBundleId: 'com.example.aqarelmasryeen',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBx7NUVZZYAxjqfEyl7PVZKzVJDOur0fhE',
    appId: '1:288037062988:ios:72dbe6d71916d24aa127e9',
    messagingSenderId: '288037062988',
    projectId: 'aqarr-cfd58',
    storageBucket: 'aqarr-cfd58.firebasestorage.app',
    iosBundleId: 'com.example.aqarelmasryeen',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCFH6tZRTB6aP_QcuRNT-I0u9NMy58Dl5Y',
    appId: '1:288037062988:web:f58e59d729cc988ca127e9',
    messagingSenderId: '288037062988',
    projectId: 'aqarr-cfd58',
    authDomain: 'aqarr-cfd58.firebaseapp.com',
    storageBucket: 'aqarr-cfd58.firebasestorage.app',
    measurementId: 'G-0NGGV3B02X',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCFH6tZRTB6aP_QcuRNT-I0u9NMy58Dl5Y',
    appId: '1:288037062988:web:8983cf44faadb9fda127e9',
    messagingSenderId: '288037062988',
    projectId: 'aqarr-cfd58',
    authDomain: 'aqarr-cfd58.firebaseapp.com',
    storageBucket: 'aqarr-cfd58.firebasestorage.app',
    measurementId: 'G-Z9TYBD0Y47',
  );

}