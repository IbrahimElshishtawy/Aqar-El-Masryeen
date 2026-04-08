import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class SalesRepository {
  SalesRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<UnitSale>> watchAll() {
    final source = _firestore
        .collection(FirestorePaths.units)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitSale.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.units,
      source: source,
      encode: _serializeUnit,
      decode: _deserializeUnit,
    );
  }

  Stream<List<UnitSale>> watchByProperty(String propertyId) {
    final source = _firestore
        .collection(FirestorePaths.units)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitSale.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.unitsByProperty(propertyId),
      source: source,
      encode: _serializeUnit,
      decode: _deserializeUnit,
    );
  }

  Future<String> save(UnitSale unit) async {
    final id = unit.id.isEmpty ? _uuid.v4() : unit.id;
    await _firestore
        .collection(FirestorePaths.units)
        .doc(id)
        .set(
          unit.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> delete(String unitId) async {
    return _firestore.collection(FirestorePaths.units).doc(unitId).delete();
  }
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeUnit(UnitSale unit) {
  return {...unit.toMap(), 'id': unit.id};
}

UnitSale _deserializeUnit(Map<String, dynamic> map) {
  return UnitSale.fromMap(map['id'] as String? ?? '', map);
}
