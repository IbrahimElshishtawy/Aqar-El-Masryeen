import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class MaterialExpenseRepository {
  MaterialExpenseRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<MaterialExpenseEntry>> watchAll() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.allMaterialExpenses,
      );
    }

    return _firestore
        .collection(FirestorePaths.materialExpenses)
        .where('archived', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaterialExpenseEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<MaterialExpenseEntry>> watchByProperty(String propertyId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () =>
            MockWorkspaceStore.instance.materialExpensesByProperty(propertyId),
      );
    }

    return _firestore
        .collection(FirestorePaths.materialExpenses)
        .where('propertyId', isEqualTo: propertyId)
        .where('archived', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaterialExpenseEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> save(MaterialExpenseEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.saveMaterialExpense(
        entry.copyWith(
          id: id,
          updatedAt: DateTime.now(),
          createdAt: entry.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
              ? DateTime.now()
              : entry.createdAt,
        ),
      );
      return id;
    }

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
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.softDeleteMaterialExpense(entryId);
    }

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
  );
});
