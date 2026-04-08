import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/features/installments/domain/installment_plan_generator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class InstallmentRepository {
  InstallmentRepository(
    this._firestore,
    this._uuid,
    this._generator,
    this._cache,
  );

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final InstallmentPlanGenerator _generator;
  final LocalCacheService _cache;

  Stream<List<Installment>> watchAllInstallments() {
    final source = _firestore
        .collection(FirestorePaths.installments)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Installment.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.installments,
      source: source,
      encode: _serializeInstallment,
      decode: _deserializeInstallment,
    );
  }

  Stream<List<InstallmentPlan>> watchPlansByProperty(String propertyId) {
    final source = _firestore
        .collection(FirestorePaths.installmentPlans)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InstallmentPlan.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.installmentPlansByProperty(propertyId),
      source: source,
      encode: _serializeInstallmentPlan,
      decode: _deserializeInstallmentPlan,
    );
  }

  Stream<List<Installment>> watchInstallmentsByProperty(String propertyId) {
    final source = _firestore
        .collection(FirestorePaths.installments)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Installment.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.installmentsByProperty(propertyId),
      source: source,
      encode: _serializeInstallment,
      decode: _deserializeInstallment,
    );
  }

  Stream<List<Installment>> watchInstallmentsByUnit(String unitId) {
    final source = _firestore
        .collection(FirestorePaths.installments)
        .where('unitId', isEqualTo: unitId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Installment.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.installmentsByUnit(unitId),
      source: source,
      encode: _serializeInstallment,
      decode: _deserializeInstallment,
    );
  }

  Future<void> savePlan(
    InstallmentPlan plan, {
    required String actorId,
    bool generateInstallments = true,
  }) async {
    final planId = plan.id.isEmpty ? _uuid.v4() : plan.id;
    final planWithId = InstallmentPlan(
      id: planId,
      propertyId: plan.propertyId,
      unitId: plan.unitId,
      installmentCount: plan.installmentCount,
      startDate: plan.startDate,
      intervalDays: plan.intervalDays,
      installmentAmount: plan.installmentAmount,
      createdAt: plan.createdAt,
      updatedAt: DateTime.now(),
      createdBy: plan.createdBy,
      updatedBy: actorId,
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection(FirestorePaths.installmentPlans).doc(planId),
      planWithId.toMap(),
      SetOptions(merge: true),
    );

    if (generateInstallments) {
      final generated = _generator.generate(plan: planWithId, actorId: actorId);
      for (final installment in generated) {
        final id = _uuid.v4();
        batch.set(
          _firestore.collection(FirestorePaths.installments).doc(id),
          installment.toMap()
            ..['planId'] = planId
            ..['status'] = installment.status.name,
        );
      }
    }

    await batch.commit();
  }

  Future<void> updateInstallmentPayment({
    required String installmentId,
    required double paidAmount,
  }) async {
    final ref = _firestore
        .collection(FirestorePaths.installments)
        .doc(installmentId);
    final snap = await ref.get();
    final installment = Installment.fromMap(snap.id, snap.data());
    final totalPaid = installment.paidAmount + paidAmount;
    final status = totalPaid >= installment.amount
        ? InstallmentStatus.paid
        : totalPaid > 0
        ? InstallmentStatus.partiallyPaid
        : installment.dueDate.isBefore(DateTime.now())
        ? InstallmentStatus.overdue
        : InstallmentStatus.pending;
    await ref.update({
      'paidAmount': totalPaid,
      'status': status.name,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> saveInstallment(Installment installment) {
    final id = installment.id.isEmpty ? _uuid.v4() : installment.id;
    return _firestore
        .collection(FirestorePaths.installments)
        .doc(id)
        .set(
          installment.toMap()
            ..['updatedAt'] = DateTime.now()
            ..['status'] = installment.status.name,
          SetOptions(merge: true),
        );
  }

  Future<void> deleteInstallment(String installmentId) {
    return _firestore
        .collection(FirestorePaths.installments)
        .doc(installmentId)
        .delete();
  }
}

final installmentRepositoryProvider = Provider<InstallmentRepository>((ref) {
  return InstallmentRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    const InstallmentPlanGenerator(),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeInstallmentPlan(InstallmentPlan plan) {
  return {...plan.toMap(), 'id': plan.id};
}

InstallmentPlan _deserializeInstallmentPlan(Map<String, dynamic> map) {
  return InstallmentPlan.fromMap(map['id'] as String? ?? '', map);
}

Map<String, dynamic> _serializeInstallment(Installment installment) {
  return {...installment.toMap(), 'id': installment.id};
}

Installment _deserializeInstallment(Map<String, dynamic> map) {
  return Installment.fromMap(map['id'] as String? ?? '', map);
}
