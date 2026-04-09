// ignore_for_file: avoid_types_as_parameter_names

import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/features/installments/domain/installment_plan_generator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
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

  Future<String> syncUnitInstallments({
    required UnitSale unit,
    required String actorId,
    String? preferredPlanId,
  }) async {
    final scheduleCount = unit.installmentScheduleCount;
    if (scheduleCount <= 0 || unit.id.isEmpty) {
      return preferredPlanId ?? '';
    }

    final installmentsSnapshot = await _firestore
        .collection(FirestorePaths.installments)
        .where('unitId', isEqualTo: unit.id)
        .get();
    final paymentsSnapshot = await _firestore
        .collection(FirestorePaths.payments)
        .where('unitId', isEqualTo: unit.id)
        .get();
    final plansSnapshot = await _firestore
        .collection(FirestorePaths.installmentPlans)
        .where('unitId', isEqualTo: unit.id)
        .limit(1)
        .get();

    final existingInstallments = installmentsSnapshot.docs
        .map((doc) => Installment.fromMap(doc.id, doc.data()))
        .sorted((a, b) {
          final sequenceCompare = a.sequence.compareTo(b.sequence);
          if (sequenceCompare != 0) {
            return sequenceCompare;
          }
          final createdCompare = a.createdAt.compareTo(b.createdAt);
          if (createdCompare != 0) {
            return createdCompare;
          }
          return a.id.compareTo(b.id);
        });
    final paymentDocsByInstallmentId =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final paymentDoc in paymentsSnapshot.docs) {
      final installmentId = (paymentDoc.data()['installmentId'] as String?)
          ?.trim();
      if (installmentId == null || installmentId.isEmpty) {
        continue;
      }
      paymentDocsByInstallmentId
          .putIfAbsent(installmentId, () => [])
          .add(paymentDoc);
    }

    final existingPlanDoc = plansSnapshot.docs.firstOrNull;
    final existingPlan = existingPlanDoc == null
        ? null
        : InstallmentPlan.fromMap(existingPlanDoc.id, existingPlanDoc.data());
    final planId = preferredPlanId?.trim().isNotEmpty == true
        ? preferredPlanId!.trim()
        : existingPlan?.id.isNotEmpty == true
        ? existingPlan!.id
        : 'auto_${unit.id}';

    final startDate =
        existingPlan?.startDate ??
        existingInstallments.firstOrNull?.dueDate ??
        unit.createdAt;
    final intervalDays =
        existingPlan?.intervalDays ?? _inferIntervalDays(existingInstallments);
    final financedAmount = (unit.contractAmount - unit.downPayment)
        .clamp(0, unit.contractAmount)
        .toDouble();
    final installmentAmount = scheduleCount <= 0
        ? 0.0
        : financedAmount / scheduleCount;
    final now = DateTime.now();
    final batch = _firestore.batch();
    final installmentsBySequence = existingInstallments.groupListsBy(
      (installment) => installment.sequence,
    );

    batch.set(
      _firestore.collection(FirestorePaths.installmentPlans).doc(planId),
      InstallmentPlan(
        id: planId,
        propertyId: unit.propertyId,
        unitId: unit.id,
        installmentCount: scheduleCount,
        startDate: startDate,
        intervalDays: intervalDays,
        installmentAmount: installmentAmount,
        createdAt: existingPlan?.createdAt ?? now,
        updatedAt: now,
        createdBy: existingPlan?.createdBy ?? actorId,
        updatedBy: actorId,
      ).toMap(),
      SetOptions(merge: true),
    );

    for (var sequence = 1; sequence <= scheduleCount; sequence++) {
      final bucket = installmentsBySequence.remove(sequence) ?? const [];
      final dueDate = startDate.add(
        Duration(days: intervalDays * (sequence - 1)),
      );

      if (bucket.isEmpty) {
        final installmentId = _uuid.v4();
        final newInstallment = Installment(
          id: installmentId,
          planId: planId,
          propertyId: unit.propertyId,
          unitId: unit.id,
          sequence: sequence,
          amount: installmentAmount,
          paidAmount: 0,
          dueDate: dueDate,
          status: _resolveInstallmentStatus(
            amount: installmentAmount,
            paidAmount: 0,
            dueDate: dueDate,
          ),
          createdAt: now,
          updatedAt: now,
          createdBy: actorId,
          updatedBy: actorId,
        );
        batch.set(
          _firestore.collection(FirestorePaths.installments).doc(installmentId),
          newInstallment.toMap(),
          SetOptions(merge: true),
        );
        continue;
      }

      final primary = bucket.first;
      final paidAmount = bucket.fold<double>(0, (sum, installment) {
        final docs = paymentDocsByInstallmentId[installment.id] ?? const [];
        return sum +
            docs.fold<double>(
              0,
              (paymentSum, doc) =>
                  paymentSum +
                  ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
            );
      });
      final resolvedDueDate =
          primary.dueDate == DateTime.fromMillisecondsSinceEpoch(0)
          ? dueDate
          : primary.dueDate;
      final updatedPrimary = primary.copyWith(
        planId: planId,
        propertyId: unit.propertyId,
        unitId: unit.id,
        sequence: sequence,
        amount: installmentAmount,
        paidAmount: paidAmount,
        dueDate: resolvedDueDate,
        status: _resolveInstallmentStatus(
          amount: installmentAmount,
          paidAmount: paidAmount,
          dueDate: resolvedDueDate,
        ),
        updatedAt: now,
        updatedBy: actorId,
      );
      batch.set(
        _firestore.collection(FirestorePaths.installments).doc(primary.id),
        updatedPrimary.toMap(),
        SetOptions(merge: true),
      );

      for (final duplicate in bucket.skip(1)) {
        final linkedPayments =
            paymentDocsByInstallmentId[duplicate.id] ?? const [];
        for (final paymentDoc in linkedPayments) {
          batch.update(paymentDoc.reference, {
            'installmentId': primary.id,
            'updatedAt': now,
          });
        }
        batch.delete(
          _firestore.collection(FirestorePaths.installments).doc(duplicate.id),
        );
      }
    }

    for (final extraBucket in installmentsBySequence.values) {
      for (final installment in extraBucket) {
        final hasLinkedPayments =
            (paymentDocsByInstallmentId[installment.id] ?? const []).isNotEmpty;
        if (hasLinkedPayments) {
          continue;
        }
        batch.delete(
          _firestore
              .collection(FirestorePaths.installments)
              .doc(installment.id),
        );
      }
    }

    await batch.commit();
    return planId;
  }

  Future<void> saveInstallment(Installment installment) {
    final id = installment.id.isEmpty ? _uuid.v4() : installment.id;
    final status = _resolveInstallmentStatus(
      amount: installment.amount,
      paidAmount: installment.paidAmount,
      dueDate: installment.dueDate,
    );
    return _firestore
        .collection(FirestorePaths.installments)
        .doc(id)
        .set(
          installment.toMap()
            ..['updatedAt'] = DateTime.now()
            ..['status'] = status.name
            ..['paidAmount'] = installment.paidAmount,
          SetOptions(merge: true),
        );
  }

  Future<void> deleteInstallment(String installmentId) async {
    final paymentsSnapshot = await _firestore
        .collection(FirestorePaths.payments)
        .where('installmentId', isEqualTo: installmentId)
        .get();
    final batch = _firestore.batch();
    batch.delete(
      _firestore.collection(FirestorePaths.installments).doc(installmentId),
    );
    for (final paymentDoc in paymentsSnapshot.docs) {
      batch.delete(paymentDoc.reference);
    }
    await batch.commit();
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

InstallmentStatus _resolveInstallmentStatus({
  required double amount,
  required double paidAmount,
  required DateTime dueDate,
}) {
  if (paidAmount >= amount && amount > 0) {
    return InstallmentStatus.paid;
  }
  if (paidAmount > 0) {
    return InstallmentStatus.partiallyPaid;
  }
  if (dueDate.isBefore(DateTime.now())) {
    return InstallmentStatus.overdue;
  }
  return InstallmentStatus.pending;
}

int _inferIntervalDays(List<Installment> installments) {
  if (installments.length < 2) {
    return 30;
  }

  final sortedDates = installments
      .map((installment) => installment.dueDate)
      .sorted((a, b) => a.compareTo(b));
  final diffs = <int>[];
  for (var index = 1; index < sortedDates.length; index++) {
    final diff = sortedDates[index].difference(sortedDates[index - 1]).inDays;
    if (diff > 0) {
      diffs.add(diff);
    }
  }
  if (diffs.isEmpty) {
    return 30;
  }
  return diffs.first;
}
