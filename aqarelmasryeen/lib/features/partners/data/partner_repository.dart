import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PartnerRepository {
  PartnerRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<Partner>> watchPartners({required String workspaceId}) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <Partner>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.partners)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Partner.fromMap(doc.id, doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.partners(workspaceId: normalizedWorkspaceId),
      source: source,
      encode: _serializePartner,
      decode: _deserializePartner,
    );
  }

  Future<void> delete(String partnerId) async {
    await _firestore
        .collection(FirestorePaths.partners)
        .doc(partnerId)
        .delete();
  }

  Future<String> upsert(Partner partner) async {
    final id = partner.id.isEmpty ? _uuid.v4() : partner.id;
    await _firestore
        .collection(FirestorePaths.partners)
        .doc(id)
        .set(
          partner.toMap()
            ..['workspaceId'] = partner.workspaceId.trim()
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> linkPartnerToUser({
    required Partner partner,
    required AppUser user,
    required String workspaceId,
  }) async {
    final partnerRef = _firestore
        .collection(FirestorePaths.partners)
        .doc(partner.id);
    final userRef = _firestore.collection(FirestorePaths.users).doc(user.uid);
    final lookupRef = _firestore
        .collection(FirestorePaths.userEmailLookup)
        .doc(user.email.trim().toLowerCase());
    final batch = _firestore.batch();
    batch.set(partnerRef, {
      ...partner.toMap(),
      'userId': user.uid,
      'linkedEmail': user.email.trim().toLowerCase(),
      'workspaceId': workspaceId.trim(),
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'workspaceId': workspaceId.trim(),
      'linkedPartnerId': partner.id,
      'linkedPartnerName': partner.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (user.email.trim().isNotEmpty) {
      batch.set(lookupRef, {
        'uid': user.uid,
        'email': user.email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
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
