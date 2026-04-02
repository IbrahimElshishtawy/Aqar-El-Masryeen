import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PropertyRepository {
  PropertyRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<PropertyProject>> watchProperties() {
    return _firestore
        .collection(FirestorePaths.properties)
        .where('archived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PropertyProject.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<PropertyProject?> watchProperty(String propertyId) {
    return _firestore.collection(FirestorePaths.properties).doc(propertyId).snapshots().map(
          (doc) => doc.exists ? PropertyProject.fromMap(doc.id, doc.data()) : null,
        );
  }

  Future<String> save(PropertyProject property) async {
    final id = property.id.isEmpty ? _uuid.v4() : property.id;
    await _firestore.collection(FirestorePaths.properties).doc(id).set(
          property.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(ref.watch(firestoreProvider), ref.watch(uuidProvider));
});
