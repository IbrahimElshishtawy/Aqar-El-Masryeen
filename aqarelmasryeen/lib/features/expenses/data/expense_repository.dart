import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class ExpenseRepository {
  ExpenseRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<ExpenseRecord>> watchAll() {
    return _firestore
        .collection(FirestorePaths.expenses)
        .where('archived', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ExpenseRecord>> watchByProperty(String propertyId) {
    return _firestore
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
  }

  Future<void> save(ExpenseRecord expense) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    await _firestore
        .collection(FirestorePaths.expenses)
        .doc(id)
        .set(
          expense.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
  }

  Future<void> softDelete(String expenseId) {
    return _firestore.collection(FirestorePaths.expenses).doc(expenseId).update(
      {'archived': true, 'updatedAt': DateTime.now()},
    );
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
  );
});
