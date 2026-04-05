import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/features/installments/domain/installment_plan_generator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class InstallmentRepository {
  InstallmentRepository(this._firestore, this._uuid, this._generator);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final InstallmentPlanGenerator _generator;

  Stream<List<Installment>> watchAllInstallments() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.allInstallments,
      );
    }
    return _firestore
        .collection(FirestorePaths.installments)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Installment.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<InstallmentPlan>> watchPlansByProperty(String propertyId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () => MockWorkspaceStore.instance.plansByProperty(propertyId),
      );
    }
    return _firestore
        .collection(FirestorePaths.installmentPlans)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InstallmentPlan.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Installment>> watchInstallmentsByProperty(String propertyId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () => MockWorkspaceStore.instance.installmentsByProperty(propertyId),
      );
    }
    return _firestore
        .collection(FirestorePaths.installments)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Installment.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<Installment>> watchInstallmentsByUnit(String unitId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () => MockWorkspaceStore.instance.installmentsByUnit(unitId),
      );
    }
    return _firestore
        .collection(FirestorePaths.installments)
        .where('unitId', isEqualTo: unitId)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Installment.fromMap(doc.id, doc.data()))
              .toList(),
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

    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.savePlan(planWithId);
      if (generateInstallments) {
        final generated = _generator.generate(
          plan: planWithId,
          actorId: actorId,
        );
        for (final installment in generated) {
          await MockWorkspaceStore.instance.saveInstallment(
            Installment(
              id: _uuid.v4(),
              planId: planId,
              propertyId: installment.propertyId,
              unitId: installment.unitId,
              sequence: installment.sequence,
              amount: installment.amount,
              paidAmount: installment.paidAmount,
              dueDate: installment.dueDate,
              status: installment.status,
              createdAt: installment.createdAt,
              updatedAt: installment.updatedAt,
              createdBy: installment.createdBy,
              updatedBy: installment.updatedBy,
            ),
          );
        }
      }
      return;
    }

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
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.updateInstallmentPayment(
        installmentId: installmentId,
        paidAmount: paidAmount,
      );
    }
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
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.saveInstallment(
        Installment(
          id: id,
          planId: installment.planId,
          propertyId: installment.propertyId,
          unitId: installment.unitId,
          sequence: installment.sequence,
          amount: installment.amount,
          paidAmount: installment.paidAmount,
          dueDate: installment.dueDate,
          status: installment.status,
          notes: installment.notes,
          createdAt: installment.createdAt,
          updatedAt: DateTime.now(),
          createdBy: installment.createdBy,
          updatedBy: installment.updatedBy,
        ),
      );
    }
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
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.deleteInstallment(installmentId);
    }

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
  );
});
