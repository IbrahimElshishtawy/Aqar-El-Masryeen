import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class SalesRepository {
  SalesRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<UnitSale>> watchAll() {
    return _firestore
        .collection(FirestorePaths.units)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitSale.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<UnitSale>> watchByProperty(String propertyId) {
    return _firestore
        .collection(FirestorePaths.units)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UnitSale.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> save(UnitSale unit) async {
    final id = unit.id.isEmpty ? _uuid.v4() : unit.id;
    await _firestore
        .collection(FirestorePaths.units)
        .doc(id)
        .set(
          unit.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(firestoreProvider), ref.watch(uuidProvider));
});
