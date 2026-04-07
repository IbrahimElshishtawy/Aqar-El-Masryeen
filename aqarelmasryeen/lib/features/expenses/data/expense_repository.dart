import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ExpenseRepository {
  ExpenseRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<ExpenseRecord>> watchAll() {
    final source = AppConfig.useMockData
        ? MockWorkspaceStore.instance.watch(
            MockWorkspaceStore.instance.allExpenses,
          )
        : _firestore
              .collection(FirestorePaths.expenses)
              .where('archived', isEqualTo: false)
              .orderBy('date', descending: true)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => ExpenseRecord.fromMap(doc.id, doc.data()))
                    .toList(),
              );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.expenses,
      source: source,
      encode: _serializeExpense,
      decode: _deserializeExpense,
    );
  }

  Stream<List<ExpenseRecord>> watchByProperty(String propertyId) {
    final source = AppConfig.useMockData
        ? MockWorkspaceStore.instance.watch(
            () => MockWorkspaceStore.instance.expensesByProperty(propertyId),
          )
        : _firestore
              .collection(FirestorePaths.expenses)
              .where('propertyId', isEqualTo: propertyId)
              .where('archived', isEqualTo: false)
              .orderBy('date', descending: true)
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => ExpenseRecord.fromMap(doc.id, doc.data()))
                    .toList(),
              );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.expensesByProperty(propertyId),
      source: source,
      encode: _serializeExpense,
      decode: _deserializeExpense,
    );
  }

  Future<String> save(ExpenseRecord expense) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.saveExpense(
        ExpenseRecord(
          id: id,
          propertyId: expense.propertyId,
          amount: expense.amount,
          category: expense.category,
          description: expense.description,
          paidByPartnerId: expense.paidByPartnerId,
          paymentMethod: expense.paymentMethod,
          date: expense.date,
          attachmentUrl: expense.attachmentUrl,
          notes: expense.notes,
          createdBy: expense.createdBy,
          updatedBy: expense.updatedBy,
          createdAt: expense.createdAt,
          updatedAt: DateTime.now(),
          archived: expense.archived,
        ),
      );
      return id;
    }
    await _firestore
        .collection(FirestorePaths.expenses)
        .doc(id)
        .set(
          expense.toMap()
            ..['createdAt'] =
                expense.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : expense.createdAt
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> softDelete(String expenseId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.softDeleteExpense(expenseId);
    }
    return _firestore.collection(FirestorePaths.expenses).doc(expenseId).update(
      {'archived': true, 'updatedAt': DateTime.now()},
    );
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeExpense(ExpenseRecord expense) {
  return {...expense.toMap(), 'id': expense.id};
}

ExpenseRecord _deserializeExpense(Map<String, dynamic> map) {
  return ExpenseRecord.fromMap(map['id'] as String? ?? '', map);
}
