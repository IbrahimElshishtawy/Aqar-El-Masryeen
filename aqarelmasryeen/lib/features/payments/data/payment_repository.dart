// ignore_for_file: avoid_types_as_parameter_names

import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';

import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PaymentRepository {
  PaymentRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<PaymentRecord>> watchAll({required String workspaceId}) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <PaymentRecord>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.payments)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.payments(workspaceId: normalizedWorkspaceId),
      source: source,
      encode: _serializePayment,
      decode: _deserializePayment,
    );
  }

  Stream<List<PaymentRecord>> watchByProperty(
    String propertyId, {
    required String workspaceId,
  }) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <PaymentRecord>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.payments)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.paymentsByProperty(
        propertyId,
        workspaceId: normalizedWorkspaceId,
      ),
      source: source,
      encode: _serializePayment,
      decode: _deserializePayment,
    );
  }

  Stream<List<PaymentRecord>> watchByUnit(
    String unitId, {
    required String workspaceId,
  }) {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return Stream.value(const <PaymentRecord>[]);
    }

    final source = _firestore
        .collection(FirestorePaths.payments)
        .where('workspaceId', isEqualTo: normalizedWorkspaceId)
        .where('unitId', isEqualTo: unitId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.paymentsByUnit(
        unitId,
        workspaceId: normalizedWorkspaceId,
      ),
      source: source,
      encode: _serializePayment,
      decode: _deserializePayment,
    );
  }

  Future<String> save(PaymentRecord payment) async {
    final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
    final paymentsCollection = _firestore.collection(FirestorePaths.payments);
    final previousSnapshot = payment.id.isEmpty
        ? null
        : await paymentsCollection.doc(payment.id).get();
    final previousPayment = previousSnapshot != null && previousSnapshot.exists
        ? PaymentRecord.fromMap(previousSnapshot.id, previousSnapshot.data())
        : null;

    await _firestore
        .collection(FirestorePaths.payments)
        .doc(id)
        .set(
          payment.toMap()
            ..['createdAt'] =
                payment.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : payment.createdAt
            ..['workspaceId'] = payment.workspaceId.trim()
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );

    final previousInstallmentId = previousPayment?.installmentId?.trim();
    final nextInstallmentId = payment.installmentId?.trim();

    if (previousInstallmentId != null &&
        previousInstallmentId.isNotEmpty &&
        previousInstallmentId != nextInstallmentId) {
      await _recalculateInstallment(previousInstallmentId);
    }
    if (nextInstallmentId != null && nextInstallmentId.isNotEmpty) {
      await _recalculateInstallment(nextInstallmentId);
    }
    final unitId = payment.unitId.trim();
    if (unitId.isNotEmpty) {
      await _syncUnitFinancialSnapshot(unitId);
    }

    return id;
  }

  Future<void> delete(String paymentId) async {
    final ref = _firestore.collection(FirestorePaths.payments).doc(paymentId);
    final snapshot = await ref.get();
    final payment = snapshot.exists
        ? PaymentRecord.fromMap(snapshot.id, snapshot.data())
        : null;
    await ref.delete();

    final installmentId = payment?.installmentId?.trim();
    if (installmentId != null && installmentId.isNotEmpty) {
      await _recalculateInstallment(installmentId);
    }
    final unitId = payment?.unitId.trim();
    if (unitId != null && unitId.isNotEmpty) {
      await _syncUnitFinancialSnapshot(unitId);
    }
  }

  Future<void> _recalculateInstallment(String installmentId) async {
    final installmentRef = _firestore
        .collection(FirestorePaths.installments)
        .doc(installmentId);
    final installmentSnapshot = await installmentRef.get();
    if (!installmentSnapshot.exists) {
      return;
    }

    final installment = Installment.fromMap(
      installmentSnapshot.id,
      installmentSnapshot.data(),
    );
    final paymentsSnapshot = await _firestore
        .collection(FirestorePaths.payments)
        .where('installmentId', isEqualTo: installmentId)
        .where('workspaceId', isEqualTo: installment.workspaceId)
        .get();
    final payments = paymentsSnapshot.docs
        .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final paidAmount = payments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final status = paidAmount >= installment.amount
        ? InstallmentStatus.paid
        : paidAmount > 0
        ? InstallmentStatus.partiallyPaid
        : installment.dueDate.isBefore(DateTime.now())
        ? InstallmentStatus.overdue
        : InstallmentStatus.pending;

    await installmentRef.update({
      'paidAmount': paidAmount,
      'status': status.name,
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> _syncUnitFinancialSnapshot(String unitId) async {
    final unitRef = _firestore.collection(FirestorePaths.units).doc(unitId);
    final unitSnapshot = await unitRef.get();
    if (!unitSnapshot.exists) {
      return;
    }

    final unit = UnitSale.fromMap(unitSnapshot.id, unitSnapshot.data());
    final paymentsSnapshot = await _firestore
        .collection(FirestorePaths.payments)
        .where('unitId', isEqualTo: unitId)
        .where('workspaceId', isEqualTo: unit.workspaceId)
        .get();
    final installmentsSnapshot = await _firestore
        .collection(FirestorePaths.installments)
        .where('unitId', isEqualTo: unitId)
        .where('workspaceId', isEqualTo: unit.workspaceId)
        .get();

    final payments = paymentsSnapshot.docs
        .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
        .toList(growable: false);
    final installments =
        installmentsSnapshot.docs
            .map((doc) => Installment.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final trackedPaymentsTotal = payments
        .where((payment) => !payment.isDownPayment)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final totalPaidSoFar = unit.downPayment + trackedPaymentsTotal;
    final remainingAmount = (unit.contractAmount - totalPaidSoFar)
        .clamp(0, unit.contractAmount)
        .toDouble();

    await unitRef.update({
      'remainingAmount': remainingAmount,
      'projectedCompletionDate': _resolveProjectedCompletionDate(
        installments: installments,
        payments: payments,
        fallback: unit.projectedCompletionDate,
      ),
      'updatedAt': DateTime.now(),
    });
  }

  DateTime? _resolveProjectedCompletionDate({
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required DateTime? fallback,
  }) {
    if (installments.isEmpty) {
      return fallback;
    }

    final paidAmountsByInstallmentId = <String, double>{};
    for (final payment in payments) {
      final installmentId = payment.installmentId?.trim();
      if (installmentId == null || installmentId.isEmpty) {
        continue;
      }
      paidAmountsByInstallmentId.update(
        installmentId,
        (value) => value + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }

    final unpaidInstallments = installments
        .where((installment) {
          final paidAmount =
              paidAmountsByInstallmentId[installment.id] ??
              installment.paidAmount;
          return paidAmount + 0.01 < installment.amount;
        })
        .toList(growable: false);

    if (unpaidInstallments.isEmpty) {
      return installments.last.dueDate;
    }
    return unpaidInstallments.last.dueDate;
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializePayment(PaymentRecord payment) {
  return {...payment.toMap(), 'id': payment.id};
}

PaymentRecord _deserializePayment(Map<String, dynamic> map) {
  return PaymentRecord.fromMap(map['id'] as String? ?? '', map);
}
