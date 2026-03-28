import 'dart:io';

import 'package:aqarelmasryeen/core/bootstrap/app_bootstrap.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  NotificationService({required BootstrapState bootstrapState})
    : _bootstrapState = bootstrapState;

  final BootstrapState _bootstrapState;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

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

    await _localNotifications.initialize(settings: settings);
  }

  Future<void> _initializeFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) {
        return;
      }
      showLocalNotification(
        title: notification.title ?? 'Aqar El Masryeen',
        body: notification.body ?? '',
      );
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
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

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      details: details,
    );
  }
}
