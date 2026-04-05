import 'dart:async';

import 'package:aqarelmasryeen/app/app.dart';
import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    runApp(const ProviderScope(child: AqarPartnersApp()));
  }, reportToCrashlytics);
}
