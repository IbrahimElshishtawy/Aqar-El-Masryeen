import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
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

  Stream<List<ActivityLogEntry>> watchRecent({String? propertyId}) {
    final source = AppConfig.useMockData
        ? MockWorkspaceStore.instance.watch(
            () => MockWorkspaceStore.instance.recentActivity(propertyId: propertyId),
          )
        : (() {
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
          })();

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.activity(propertyId: propertyId),
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
  }) {
    final id = _uuid.v4();
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.logActivity(
        ActivityLogEntry(
          id: id,
          actorId: actorId,
          actorName: actorName,
          action: action,
          entityType: entityType,
          entityId: entityId,
          createdAt: DateTime.now(),
          metadata: metadata,
        ),
      );
    }
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
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeActivityLog(ActivityLogEntry entry) {
  return {...entry.toMap(), 'id': entry.id};
}

ActivityLogEntry _deserializeActivityLog(Map<String, dynamic> map) {
  return ActivityLogEntry.fromMap(map['id'] as String? ?? '', map);
}
