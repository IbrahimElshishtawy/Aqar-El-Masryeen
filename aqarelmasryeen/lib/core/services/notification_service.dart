import 'dart:convert';
import 'dart:async';

import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/services/firebase_initializer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initializeFirebase();
}

void reportToCrashlytics(Object error, StackTrace stackTrace) {
  if (Firebase.apps.isEmpty) {
    return;
  }
  FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
}

class NotificationRoutePayload {
  const NotificationRoutePayload({required this.route, this.extraId});

  final String route;
  final String? extraId;

  String encode() => jsonEncode({'route': route, 'extraId': extraId});

  static NotificationRoutePayload? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final route = map['route'] as String?;
    if (route == null) return null;
    return NotificationRoutePayload(
      route: route,
      extraId: map['extraId'] as String?,
    );
  }
}

class FirebaseMessagingService {
  FirebaseMessagingService(
    this._messaging,
    this._localNotifications,
    this._analytics,
  );

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseAnalytics _analytics;
  static bool _backgroundHandlerRegistered = false;
  Future<void>? _initializationFuture;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  static void registerBackgroundHandler() {
    if (_backgroundHandlerRegistered) {
      return;
    }
    _backgroundHandlerRegistered = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> initialize({
    required void Function(NotificationRoutePayload payload) onNotificationTap,
  }) async {
    await initializeFirebase();
    _initializationFuture ??= _initializeCore(onNotificationTap);
    await _initializationFuture;
    unawaited(_warmUpToken());
  }

  Future<void> _initializeCore(
    void Function(NotificationRoutePayload payload) onNotificationTap,
  ) async {
    await _requestPermissions();
    await _initializeLocalNotifications(onNotificationTap: onNotificationTap);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _onMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _onMessageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp
        .listen((message) {
          final payload = NotificationRoutePayload.tryDecode(
            message.data['payload'] as String?,
          );
          if (payload != null) {
            onNotificationTap(payload);
          }
        });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final payload = NotificationRoutePayload.tryDecode(
        initialMessage.data['payload'] as String?,
      );
      if (payload != null) {
        onNotificationTap(payload);
      }
    }

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((_) {
      unawaited(_analytics.logEvent(name: 'fcm_token_refreshed'));
    });
  }

  Future<void> _warmUpToken() async {
    try {
      await _messaging.getToken();
    } catch (_) {
      // Token warm-up should never block app startup.
    }
  }

  Future<NotificationSettings> _requestPermissions() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
  }

  Future<void> _initializeLocalNotifications({
    required void Function(NotificationRoutePayload payload) onNotificationTap,
  }) async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: iOS),
      onDidReceiveNotificationResponse: (response) {
        final payload = NotificationRoutePayload.tryDecode(response.payload);
        if (payload != null) onNotificationTap(payload);
      },
    );

    const channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDescription,
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await showLocalAlert(
      id: notification.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: message.data['payload'] as String?,
    );
  }

  Future<void> showLocalAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConfig.notificationChannelId,
          AppConfig.notificationChannelName,
          channelDescription: AppConfig.notificationChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
