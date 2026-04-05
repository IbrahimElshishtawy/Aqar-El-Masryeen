import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PartnerLedgerRepository {
  PartnerLedgerRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<PartnerLedgerEntry>> watchAll() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.allPartnerLedgerEntries,
      );
    }

    return _firestore
        .collection(FirestorePaths.partnerLedgers)
        .where('archived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PartnerLedgerEntry.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> saveAuthorized(PartnerLedgerEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.savePartnerLedgerEntry(
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
        .collection(FirestorePaths.partnerLedgers)
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

  Future<void> softDeleteAuthorized(String entryId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.softDeletePartnerLedgerEntry(entryId);
    }

    return _firestore
        .collection(FirestorePaths.partnerLedgers)
        .doc(entryId)
        .update({'archived': true, 'updatedAt': DateTime.now()});
  }
}

final partnerLedgerRepositoryProvider = Provider<PartnerLedgerRepository>((
  ref,
) {
  return PartnerLedgerRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
  );
});
