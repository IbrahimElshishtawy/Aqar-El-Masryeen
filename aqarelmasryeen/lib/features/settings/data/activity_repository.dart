import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ActivityRepository {
  ActivityRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<ActivityLogEntry>> watchRecent({
    String? propertyId,
    required String workspaceId,
  }) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <ActivityLogEntry>[]);
    }

    final source = (() {
      Query<Map<String, dynamic>> query = _firestore
          .collection(FirestorePaths.activityLogs)
          .where('workspaceId', isEqualTo: normalizedWorkspaceId);
      final normalizedPropertyId = propertyId?.trim() ?? '';
      if (normalizedPropertyId.isNotEmpty) {
        query = query.where('entityId', isEqualTo: normalizedPropertyId);
      }
      return query.orderBy('createdAt', descending: true).limit(20).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ActivityLogEntry.fromMap(doc.id, doc.data()))
            .toList(),
      );
    })();

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.activity(
        propertyId: propertyId,
        workspaceId: normalizedWorkspaceId,
      ),
      source: source,
      encode: _serializeActivityLog,
      decode: _deserializeActivityLog,
    );
  }

  Future<void> log({
    required String actorId,
    required String actorName,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> metadata = const {},
    String? workspaceId,
  }) async {
    final id = _uuid.v4();
    final resolvedWorkspaceId = await _resolveWorkspaceId(
      actorId: actorId,
      workspaceId: workspaceId,
    );
    if (resolvedWorkspaceId.isEmpty) {
      return;
    }
    return _firestore.collection(FirestorePaths.activityLogs).doc(id).set({
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': DateTime.now(),
      'metadata': metadata,
      'workspaceId': resolvedWorkspaceId,
    });
  }

  Future<String> _resolveWorkspaceId({
    required String actorId,
    required String? workspaceId,
  }) async {
    final normalizedWorkspaceId = workspaceId?.trim() ?? '';
    if (normalizedWorkspaceId.isNotEmpty) {
      return normalizedWorkspaceId;
    }

    final normalizedActorId = actorId.trim();
    if (normalizedActorId.isEmpty) {
      return '';
    }

    final userSnapshot = await _firestore
        .collection(FirestorePaths.users)
        .doc(normalizedActorId)
        .get();
    return (userSnapshot.data()?['workspaceId'] as String? ?? '').trim();
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeActivityLog(ActivityLogEntry entry) {
  return {...entry.toMap(), 'id': entry.id};
}

ActivityLogEntry _deserializeActivityLog(Map<String, dynamic> map) {
  return ActivityLogEntry.fromMap(map['id'] as String? ?? '', map);
}
