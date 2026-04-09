import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class MaterialExpenseRepository {
  MaterialExpenseRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<MaterialExpenseEntry>> watchAll() {
    final source = _firestore
        .collection(FirestorePaths.materialExpenses)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaterialExpenseEntry.fromMap(doc.id, doc.data()))
              .where((entry) => !entry.archived)
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.materialExpenses,
      source: source,
      encode: _serializeMaterialExpense,
      decode: _deserializeMaterialExpense,
    );
  }

  Stream<List<MaterialExpenseEntry>> watchByProperty(String propertyId) {
    final source = _firestore
        .collection(FirestorePaths.materialExpenses)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaterialExpenseEntry.fromMap(doc.id, doc.data()))
              .where(
                (entry) => entry.propertyId == propertyId && !entry.archived,
              )
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.materialExpensesByProperty(propertyId),
      source: source,
      encode: _serializeMaterialExpense,
      decode: _deserializeMaterialExpense,
    );
  }

  Future<String> save(MaterialExpenseEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    await _firestore
        .collection(FirestorePaths.materialExpenses)
        .doc(id)
        .set(
          entry.toMap()
            ..['createdAt'] =
                entry.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : entry.createdAt
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> softDelete(String entryId) {
    return _firestore
        .collection(FirestorePaths.materialExpenses)
        .doc(entryId)
        .update({'archived': true, 'updatedAt': DateTime.now()});
  }
}

final materialExpenseRepositoryProvider = Provider<MaterialExpenseRepository>((
  ref,
) {
  return MaterialExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeMaterialExpense(MaterialExpenseEntry entry) {
  return {...entry.toMap(), 'id': entry.id};
}

MaterialExpenseEntry _deserializeMaterialExpense(Map<String, dynamic> map) {
  return MaterialExpenseEntry.fromMap(map['id'] as String? ?? '', map);
}
