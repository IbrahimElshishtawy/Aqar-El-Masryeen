import 'dart:ui' show DartPluginRegistrant;
import 'dart:async';
import 'dart:convert';

import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/services/firebase_initializer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await initializeFirebase();

  // Notification payloads are already displayed by the OS in background states.
  // We only synthesize a local alert for data-only payloads carrying title/body.
  if (message.notification != null) {
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  await _initializeLocalNotificationsPlugin(plugin);
  await _showMessageAsLocalNotification(plugin, message);
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
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final route = map['route'] as String?;
      if (route == null || route.isEmpty) return null;
      return NotificationRoutePayload(
        route: route,
        extraId: map['extraId'] as String?,
      );
    } catch (_) {
      return null;
    }
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
    await _messaging.setAutoInitEnabled(true);
    _initializationFuture ??= _initializeCore(onNotificationTap);
    await _initializationFuture;
    unawaited(_warmUpToken());
  }

  Future<void> _initializeCore(
    void Function(NotificationRoutePayload payload) onNotificationTap,
  ) async {
    await _requestPermissions();
    await _initializeLocalNotifications(onNotificationTap: onNotificationTap);
    await _handleLocalNotificationLaunch(onNotificationTap);

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

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      unawaited(_handleTokenRefresh(token));
    });
  }

  Future<void> _handleLocalNotificationLaunch(
    void Function(NotificationRoutePayload payload) onNotificationTap,
  ) async {
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) {
      return;
    }

    final payload = NotificationRoutePayload.tryDecode(
      launchDetails?.notificationResponse?.payload,
    );
    if (payload != null) {
      onNotificationTap(payload);
    }
  }

  Future<void> _warmUpToken() async {
    try {
      final token = await _messaging.getToken();
      await _syncCurrentToken(token);
    } catch (_) {
      // Token warm-up should never block app startup.
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    unawaited(_analytics.logEvent(name: 'fcm_token_refreshed'));
    await _syncCurrentToken(token);
  }

  Future<void> _syncCurrentToken(String? token) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final resolvedToken = token?.trim();
    if (currentUser == null || resolvedToken == null || resolvedToken.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(currentUser.uid)
          .set({
            'fcmTokens': FieldValue.arrayUnion([resolvedToken]),
            'lastFcmToken': resolvedToken,
            'lastFcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Failed to sync FCM token: $error');
      reportToCrashlytics(error, stackTrace);
    }
  }

  Future<NotificationSettings> _requestPermissions() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _initializeLocalNotifications({
    required void Function(NotificationRoutePayload payload) onNotificationTap,
  }) async {
    await _initializeLocalNotificationsPlugin(
      _localNotifications,
      onDidReceiveNotificationResponse: (response) {
        final payload = NotificationRoutePayload.tryDecode(response.payload);
        if (payload != null) {
          onNotificationTap(payload);
        }
      },
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    await _showMessageAsLocalNotification(_localNotifications, message);
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
      notificationDetails: _notificationDetails,
      payload: payload,
    );
  }
}

Future<void> _initializeLocalNotificationsPlugin(
  FlutterLocalNotificationsPlugin plugin, {
  DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
}) async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOS = DarwinInitializationSettings();

  await plugin.initialize(
    settings: const InitializationSettings(android: android, iOS: iOS),
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );

  const channel = AndroidNotificationChannel(
    AppConfig.notificationChannelId,
    AppConfig.notificationChannelName,
    description: AppConfig.notificationChannelDescription,
    importance: Importance.max,
  );

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

Future<void> _showMessageAsLocalNotification(
  FlutterLocalNotificationsPlugin plugin,
  RemoteMessage message,
) async {
  final title = _resolveNotificationTitle(message);
  final body = _resolveNotificationBody(message);
  if (title.isEmpty && body.isEmpty) {
    return;
  }

  await plugin.show(
    id: message.messageId.hashCode ^ title.hashCode ^ body.hashCode,
    title: title,
    body: body,
    notificationDetails: _notificationDetails,
    payload: message.data['payload'] as String?,
  );
}

String _resolveNotificationTitle(RemoteMessage message) {
  return message.notification?.title?.trim() ??
      (message.data['title'] as String? ?? '').trim();
}

String _resolveNotificationBody(RemoteMessage message) {
  return message.notification?.body?.trim() ??
      (message.data['body'] as String? ?? '').trim();
}

const NotificationDetails _notificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    AppConfig.notificationChannelId,
    AppConfig.notificationChannelName,
    channelDescription: AppConfig.notificationChannelDescription,
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
