import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
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

  Stream<List<AppNotificationItem>> watchNotifications({
    required String userId,
    required String workspaceId,
  }) {
    final normalizedUserId = userId.trim();
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedUserId.isEmpty || normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <AppNotificationItem>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: normalizedUserId)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AppNotificationItem.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
                ..length = snapshot.docs.length > 50
                    ? 50
                    : snapshot.docs.length,
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.notifications(
        normalizedUserId,
        workspaceId: normalizedWorkspaceId,
      ),
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
    String? workspaceId,
  }) {
    final id = referenceKey?.trim().isNotEmpty == true
        ? referenceKey!.trim()
        : _uuid.v4();
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
      'workspaceId': workspaceId ?? '',
      'pushDelivery': const {
        'status': 'queued',
        'reason': 'awaiting_function_dispatch',
      },
    });
  }

  Future<void> createForUsers({
    required Iterable<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    required String route,
    String? workspaceId,
    String? referenceKeyPrefix,
    Map<String, dynamic>? metadata,
  }) async {
    final uniqueIds = userIds
        .map((userId) => userId.trim())
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (uniqueIds.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final userId in uniqueIds) {
      final referenceKey = referenceKeyPrefix?.trim().isNotEmpty == true
          ? '${referenceKeyPrefix!.trim()}-$userId'
          : _uuid.v4();
      batch.set(
        _firestore.collection(FirestorePaths.notifications).doc(referenceKey),
        {
          'userId': userId,
          'title': title,
          'body': body,
          'type': type.name,
          'route': route,
          'isRead': false,
          'createdAt': DateTime.now(),
          'referenceKey': referenceKey,
          'metadata': metadata ?? const {},
          'workspaceId': workspaceId ?? '',
          'pushDelivery': const {
            'status': 'queued',
            'reason': 'awaiting_function_dispatch',
          },
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> createSecurityNotification({
    required String userId,
    required String title,
    required String body,
    required String route,
    String? workspaceId,
  }) {
    return create(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.newDeviceLogin,
      route: route,
      workspaceId: workspaceId,
    );
  }

  Future<void> markRead(String notificationId) {
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
