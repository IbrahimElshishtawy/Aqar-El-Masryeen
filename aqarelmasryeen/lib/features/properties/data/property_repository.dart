import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PropertyRepository {
  PropertyRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<PropertyProject>> watchProperties({
    String workspaceId = '',
    Set<String> accountUserIds = const <String>{},
  }) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <PropertyProject>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.properties)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .where('archived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PropertyProject.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.properties(workspaceId: normalizedWorkspaceId),
      source: source,
      encode: _serializeProperty,
      decode: _deserializeProperty,
    );
  }

  Stream<PropertyProject?> watchProperty(
    String propertyId, {
    String workspaceId = '',
  }) {
    final normalizedWorkspaceId = workspaceId.trim();
    final source = _firestore
        .collection(FirestorePaths.properties)
        .doc(propertyId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          final property = PropertyProject.fromMap(doc.id, doc.data());
          if (normalizedWorkspaceId.isNotEmpty &&
              property.workspaceId.trim() != normalizedWorkspaceId) {
            return null;
          }
          return property;
        });

    return CachePolicy.watchObject(
      cache: _cache,
      cacheKey: CacheKeys.property(
        propertyId,
        workspaceId: normalizedWorkspaceId,
      ),
      source: source,
      encode: _serializeProperty,
      decode: _deserializeProperty,
    );
  }

  Future<String> save(PropertyProject property) async {
    final id = property.id.isEmpty ? _uuid.v4() : property.id;
    await _firestore
        .collection(FirestorePaths.properties)
        .doc(id)
        .set(
          property.toMap()
            ..['createdAt'] =
                property.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : property.createdAt
            ..['workspaceId'] = property.workspaceId.trim()
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> archive(String propertyId, {required String actorId}) {
    return _firestore
        .collection(FirestorePaths.properties)
        .doc(propertyId)
        .update({
          'archived': true,
          'updatedAt': DateTime.now(),
          'updatedBy': actorId,
          'status': 'archived',
        });
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeProperty(PropertyProject property) {
  return {...property.toMap(), 'id': property.id};
}

PropertyProject _deserializeProperty(Map<String, dynamic> map) {
  return PropertyProject.fromMap(map['id'] as String? ?? '', map);
}
