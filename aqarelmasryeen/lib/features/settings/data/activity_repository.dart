import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ActivityRepository {
  ActivityRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<ActivityLogEntry>> watchRecent({String? propertyId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestorePaths.activityLogs)
        .orderBy('createdAt', descending: true)
        .limit(20);
    if (propertyId != null) {
      query = query.where('entityId', isEqualTo: propertyId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ActivityLogEntry.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> log({
    required String actorId,
    required String actorName,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> metadata = const {},
  }) {
    final id = _uuid.v4();
    return _firestore.collection(FirestorePaths.activityLogs).doc(id).set({
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': DateTime.now(),
      'metadata': metadata,
    });
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
  );
});
