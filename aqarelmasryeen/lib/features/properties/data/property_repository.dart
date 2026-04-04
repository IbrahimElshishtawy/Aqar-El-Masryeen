import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PropertyRepository {
  PropertyRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<PropertyProject>> watchProperties() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.activeProperties,
      );
    }
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
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () => MockWorkspaceStore.instance.propertyById(propertyId),
      );
    }
    return _firestore
        .collection(FirestorePaths.properties)
        .doc(propertyId)
        .snapshots()
        .map(
          (doc) =>
              doc.exists ? PropertyProject.fromMap(doc.id, doc.data()) : null,
        );
  }

  Future<String> save(PropertyProject property) async {
    final id = property.id.isEmpty ? _uuid.v4() : property.id;
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.saveProperty(
        PropertyProject(
          id: id,
          name: property.name,
          location: property.location,
          description: property.description,
          status: property.status,
          totalBudget: property.totalBudget,
          totalSalesTarget: property.totalSalesTarget,
          createdAt: property.createdAt,
          updatedAt: DateTime.now(),
          createdBy: property.createdBy,
          updatedBy: property.updatedBy,
          archived: property.archived,
        ),
      );
      return id;
    }
    await _firestore
        .collection(FirestorePaths.properties)
        .doc(id)
        .set(
          property.toMap()
            ..['createdAt'] =
                property.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : property.createdAt
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> archive(String propertyId, {required String actorId}) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.archiveProperty(
        propertyId,
        actorId: actorId,
      );
    }
    return _firestore
        .collection(FirestorePaths.properties)
        .doc(propertyId)
        .update({
          'archived': true,
          'updatedAt': DateTime.now(),
          'updatedBy': actorId,
          'status': 'archived',
        });
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
  );
});
