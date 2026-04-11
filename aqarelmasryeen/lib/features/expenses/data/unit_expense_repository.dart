import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class UnitExpenseRepository {
  UnitExpenseRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<UnitExpenseRecord>> watchByUnit({
    required String unitId,
    required String workspaceId,
  }) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <UnitExpenseRecord>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.unitExpenses)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .where('unitId', isEqualTo: unitId)
        .where('archived', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitExpenseRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.unitExpensesByUnit(
        unitId,
        workspaceId: normalizedWorkspaceId,
      ),
      source: source,
      encode: _serializeUnitExpense,
      decode: _deserializeUnitExpense,
    );
  }

  Future<String> save(UnitExpenseRecord expense) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    await _firestore
        .collection(FirestorePaths.unitExpenses)
        .doc(id)
        .set(
          expense.toMap()
            ..['createdAt'] =
                expense.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : expense.createdAt
            ..['workspaceId'] = expense.workspaceId.trim()
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> softDelete(String expenseId) {
    return _firestore
        .collection(FirestorePaths.unitExpenses)
        .doc(expenseId)
        .update({'archived': true, 'updatedAt': DateTime.now()});
  }
}

final unitExpenseRepositoryProvider = Provider<UnitExpenseRepository>((ref) {
  return UnitExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeUnitExpense(UnitExpenseRecord expense) {
  return {...expense.toMap(), 'id': expense.id};
}

UnitExpenseRecord _deserializeUnitExpense(Map<String, dynamic> map) {
  return UnitExpenseRecord.fromMap(map['id'] as String? ?? '', map);
}
