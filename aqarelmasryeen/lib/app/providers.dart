import 'package:aqarelmasryeen/core/security/biometric_service.dart';
import 'package:aqarelmasryeen/core/services/device_info_service.dart';
import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:aqarelmasryeen/core/services/secure_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);
final analyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);
final crashlyticsProvider = Provider<FirebaseCrashlytics>(
  (ref) => FirebaseCrashlytics.instance,
);
final messagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: true,
        migrateOnAlgorithmChange: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_CBC_PKCS7Padding,
        sharedPreferencesName: 'AqarElMasryeenSecureStorageV2',
        preferencesKeyPrefix: 'aqarelmasryeen_v2',
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ),
);
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(LocalAuthentication()),
);
final uuidProvider = Provider<Uuid>((ref) => const Uuid());
final localNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => flutterLocalNotificationsPlugin,
);
final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) =>
      DeviceInfoService(DeviceInfoPlugin(), ref.watch(secureStorageProvider)),
);
final notificationServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return FirebaseMessagingService(
    ref.watch(messagingProvider),
    ref.watch(localNotificationsProvider),
    ref.watch(analyticsProvider),
  );
});
