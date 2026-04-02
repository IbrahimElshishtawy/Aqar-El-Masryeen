import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PartnerRepository {
  PartnerRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<Partner>> watchPartners() {
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
