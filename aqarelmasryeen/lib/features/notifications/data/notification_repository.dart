import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository {
  NotificationRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<AppNotificationItem>> watchNotifications(String userId) {
    final source = AppConfig.useMockData
        ? MockWorkspaceStore.instance.watch(
            () => MockWorkspaceStore.instance.notificationsFor(userId),
          )
        : _firestore
              .collection(FirestorePaths.notifications)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map(
                      (doc) => AppNotificationItem.fromMap(doc.id, doc.data()),
                    )
                    .toList(),
              );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.notifications(userId),
      source: source,
      encode: _serializeNotification,
      decode: _deserializeNotification,
    );
  }

  Future<void> create({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required String route,
    String? referenceKey,
    Map<String, dynamic>? metadata,
  }) {
    final id = referenceKey?.trim().isNotEmpty == true
        ? referenceKey!.trim()
        : _uuid.v4();
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.createNotification(
        AppNotificationItem(
          id: id,
          userId: userId,
          title: title,
          body: body,
          type: type,
          route: route,
          isRead: false,
          createdAt: DateTime.now(),
          referenceKey: referenceKey ?? '',
          metadata: metadata ?? const {},
        ),
      );
    }
    return _firestore.collection(FirestorePaths.notifications).doc(id).set({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'route': route,
      'isRead': false,
      'createdAt': DateTime.now(),
      'referenceKey': referenceKey ?? '',
      'metadata': metadata ?? const {},
    });
  }

  Future<void> createSecurityNotification({
    required String userId,
    required String title,
    required String body,
    required String route,
  }) {
    return create(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.newDeviceLogin,
      route: route,
    );
  }

  Future<void> markRead(String notificationId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.markNotificationRead(notificationId);
    }
    return _firestore
        .collection(FirestorePaths.notifications)
        .doc(notificationId)
        .update({'isRead': true});
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeNotification(AppNotificationItem item) {
  return {...item.toMap(), 'id': item.id};
}

AppNotificationItem _deserializeNotification(Map<String, dynamic> map) {
  return AppNotificationItem.fromMap(map['id'] as String? ?? '', map);
}
