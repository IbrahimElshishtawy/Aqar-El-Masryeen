import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/config/app_config.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/mock/mock_workspace_store.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PaymentRepository {
  PaymentRepository(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Stream<List<PaymentRecord>> watchAll() {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        MockWorkspaceStore.instance.allPayments,
      );
    }

    return _firestore
        .collection(FirestorePaths.payments)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PaymentRecord>> watchByProperty(String propertyId) {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.watch(
        () => MockWorkspaceStore.instance.paymentsByProperty(propertyId),
      );
    }

    return _firestore
        .collection(FirestorePaths.payments)
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> save(PaymentRecord payment) async {
    final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
    if (AppConfig.useMockData) {
      await MockWorkspaceStore.instance.recordPayment(
        PaymentRecord(
          id: id,
          propertyId: payment.propertyId,
          unitId: payment.unitId,
          customerName: payment.customerName,
          installmentId: payment.installmentId,
          amount: payment.amount,
          receivedAt: payment.receivedAt,
          paymentMethod: payment.paymentMethod,
          notes: payment.notes,
          createdAt: payment.createdAt,
          updatedAt: DateTime.now(),
          createdBy: payment.createdBy,
          updatedBy: payment.updatedBy,
        ),
      );
      return id;
    }

    await _firestore
        .collection(FirestorePaths.payments)
        .doc(id)
        .set(
          payment.toMap()
            ..['createdAt'] =
                payment.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
                ? DateTime.now()
                : payment.createdAt
            ..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );
    return id;
  }

  Future<void> delete(String paymentId) async {
    if (AppConfig.useMockData) {
      return MockWorkspaceStore.instance.deletePayment(paymentId);
    }

    return _firestore
        .collection(FirestorePaths.payments)
        .doc(paymentId)
        .delete();
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
  );
});
