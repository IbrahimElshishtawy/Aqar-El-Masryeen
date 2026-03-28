import 'dart:convert';
import 'dart:io';

import 'package:aqarelmasryeen/app/routes/app_routes.dart';
import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:aqarelmasryeen/core/constants/storage_keys.dart';
import 'package:aqarelmasryeen/core/firebase/firebase_options.dart';
import 'package:aqarelmasryeen/core/services/local_cache_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!DefaultFirebaseOptions.isConfiguredForCurrentPlatform) {
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService extends GetxService {
  NotificationService({
    required BootstrapState bootstrapState,
    required LocalCacheService localCacheService,
  }) : _bootstrapState = bootstrapState,
       _localCacheService = localCacheService;

  final BootstrapState _bootstrapState;
  final LocalCacheService _localCacheService;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _localCacheService.initialize();
    await _initializeLocalNotifications();

    if (_bootstrapState.firebaseReady && _supportsFcm) {
      await _initializeFcm();
    }

    _initialized = true;
  }

  bool get _supportsFcm =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      windows: WindowsInitializationSettings(
        appName: 'Aqar El Masryeen',
        appUserModelId: 'com.aqarelmasryeen.app',
        guid: '4fdfc758-143a-4c0a-9e6d-4d6a7d178f21',
      ),
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );
  }

  Future<void> _initializeFcm() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _localCacheService.writeString(StorageKeys.notificationToken, token);
    }

    messaging.onTokenRefresh.listen((token) {
      _localCacheService.writeString(StorageKeys.notificationToken, token);
    });

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) {
        return;
      }
      showLocalNotification(
        title: notification.title ?? 'Aqar El Masryeen',
        body: notification.body ?? '',
        section: message.data['section'] as String?,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _openSection(message.data['section'] as String?);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _openSection(initialMessage.data['section'] as String?);
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? section,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aqar_default',
        'General',
        channelDescription: 'General workspace notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    final payload = section == null ? null : jsonEncode({'section': section});

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return;
    }
    final data = jsonDecode(payload) as Map<String, dynamic>;
    _openSection(data['section'] as String?);
  }

  void _openSection(String? section) {
    Get.offAllNamed(
      AppRoutes.dashboard,
      arguments: {'section': section ?? 'notifications'},
    );
  }
}
