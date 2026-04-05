import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class SalesRepository {
  SalesRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<UnitSale>> watchAll() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.allUnits,
      );
    }
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
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () => MockWorkspaceStore.instance.unitsByProperty(propertyId),
      );
    }
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
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.saveUnit(
        UnitSale(
          id: id,
          propertyId: unit.propertyId,
          unitNumber: unit.unitNumber,
          floor: unit.floor,
          unitType: unit.unitType,
          area: unit.area,
          customerName: unit.customerName,
          customerPhone: unit.customerPhone,
          saleAmount: unit.saleAmount,
          totalPrice: unit.totalPrice,
          contractAmount: unit.contractAmount,
          downPayment: unit.downPayment,
          remainingAmount: unit.remainingAmount,
          installmentScheduleCount: unit.installmentScheduleCount,
          paymentPlanType: unit.paymentPlanType,
          status: unit.status,
          notes: unit.notes,
          projectedCompletionDate: unit.projectedCompletionDate,
          createdAt: unit.createdAt,
          updatedAt: DateTime.now(),
          createdBy: unit.createdBy,
          updatedBy: unit.updatedBy,
        ),
      );
      return id;
    }
    await _firestore
        .collection(FirestorePaths.units)
        .doc(id)
        .set(
          unit.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> delete(String unitId) async {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.deleteUnit(unitId);
    }

    return _firestore.collection(FirestorePaths.units).doc(unitId).delete();
  }
}

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(ref.watch(firestoreProvider), ref.watch(uuidProvider));
});
