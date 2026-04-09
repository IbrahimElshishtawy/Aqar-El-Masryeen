import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationNavigationController
    extends Notifier<NotificationRoutePayload?> {
  @override
  NotificationRoutePayload? build() => null;

  void queue(NotificationRoutePayload payload) {
    if (payload.route.trim().isEmpty) {
      return;
    }
    state = payload;
  }

  void clear() {
    state = null;
  }
}

final notificationNavigationControllerProvider = NotifierProvider<
  NotificationNavigationController,
  NotificationRoutePayload?
>(NotificationNavigationController.new);
