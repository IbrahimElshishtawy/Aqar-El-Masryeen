import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class NotificationRepository {
  NotificationRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<AppNotificationItem>> watchNotifications(String userId) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotificationItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> create({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    required String route,
  }) {
    final id = _uuid.v4();
    return _firestore.collection(FirestorePaths.notifications).doc(id).set({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'route': route,
      'isRead': false,
      'createdAt': DateTime.now(),
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
  );
});
