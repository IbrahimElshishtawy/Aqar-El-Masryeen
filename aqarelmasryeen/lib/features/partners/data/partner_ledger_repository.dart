import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PartnerLedgerRepository {
  PartnerLedgerRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<PartnerLedgerEntry>> watchAll() {
    final source = _firestore
        .collection(FirestorePaths.partnerLedgers)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PartnerLedgerEntry.fromMap(doc.id, doc.data()))
              .where((entry) => !entry.archived)
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.partnerLedger,
      source: source,
      encode: _serializePartnerLedgerEntry,
      decode: _deserializePartnerLedgerEntry,
    );
  }

  Future<String> saveAuthorized(PartnerLedgerEntry entry) async {
    final id = entry.id.isEmpty ? _uuid.v4() : entry.id;
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
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializePartnerLedgerEntry(PartnerLedgerEntry entry) {
  return {...entry.toMap(), 'id': entry.id};
}

PartnerLedgerEntry _deserializePartnerLedgerEntry(Map<String, dynamic> map) {
  return PartnerLedgerEntry.fromMap(map['id'] as String? ?? '', map);
}
