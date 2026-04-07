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

class PartnerRepository {
  PartnerRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<Partner>> watchPartners() {
    final source = AppConfig.useMockData
        ? MockWorkspaceStore.instance.watch(MockWorkspaceStore.instance.partners)
        : _firestore
              .collection(FirestorePaths.partners)
              .orderBy('createdAt')
              .snapshots()
              .map(
                (snapshot) => snapshot.docs
                    .map((doc) => Partner.fromMap(doc.id, doc.data()))
                    .toList(),
              );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.partners,
      source: source,
      encode: _serializePartner,
      decode: _deserializePartner,
    );
  }

  Future<String> upsert(Partner partner) async {
    final id = partner.id.isEmpty ? _uuid.v4() : partner.id;
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.upsertPartner(
        Partner(
          id: id,
          userId: partner.userId,
          name: partner.name,
          shareRatio: partner.shareRatio,
          contributionTotal: partner.contributionTotal,
          createdAt: partner.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      return id;
    }
    await _firestore
        .collection(FirestorePaths.partners)
        .doc(id)
        .set(
          partner.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }
}

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializePartner(Partner partner) {
  return {...partner.toMap(), 'id': partner.id};
}

Partner _deserializePartner(Map<String, dynamic> map) {
  return Partner.fromMap(map['id'] as String? ?? '', map);
}
