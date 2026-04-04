import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PartnerRepository {
  PartnerRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<Partner>> watchPartners() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.partners,
      );
    }
    return _firestore
        .collection(FirestorePaths.partners)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Partner.fromMap(doc.id, doc.data()))
              .toList(),
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
  );
});
