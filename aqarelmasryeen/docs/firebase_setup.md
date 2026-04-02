# Firebase Setup Notes

## Required Firebase Products

- Authentication: phone auth and email/password
- Firestore: app data
- Storage: property files
- Cloud Messaging: partner alerts
- Analytics: usage telemetry
- Crashlytics: crash reporting

## Android

- `android/app/google-services.json` is already present.
- Notification permission is declared in [AndroidManifest.xml](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/android/app/src/main/AndroidManifest.xml).
- Notification channel configuration lives in [notification_service.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/core/services/notification_service.dart).

## iOS

- Add `ios/Runner/GoogleService-Info.plist` from Firebase Console.
- In Xcode enable:
  - Push Notifications
  - Background Modes > Remote notifications
  - Associated Domains only if deep links later move beyond router paths
- APNs auth key or certificate must be uploaded in Firebase Console for production FCM delivery.
- `UIBackgroundModes` and Face ID usage description are already defined in [Info.plist](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/ios/Runner/Info.plist).
- App delegate entry point is [AppDelegate.swift](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/ios/Runner/AppDelegate.swift).

## Initialization Flow

- Firebase bootstraps in [bootstrap.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/app/bootstrap.dart)
- Core Firebase init is in [firebase_initializer.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/core/services/firebase_initializer.dart)
- Notification setup and foreground handling are in [notification_service.dart](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/lib/core/services/notification_service.dart)

## Firestore Indexes

- Composite indexes are defined in [firestore.indexes.json](/e:/FlutterProjects/aqar%20masrien/Aqar%20El%20Masryeen/aqarelmasryeen/firestore.indexes.json).
