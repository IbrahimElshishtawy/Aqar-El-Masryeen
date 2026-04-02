import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PaymentRepository {
  PaymentRepository(this._firestore, this._uuid, this._installmentRepository);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final InstallmentRepository _installmentRepository;

  Stream<List<PaymentRecord>> watchAll() {
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

  Future<void> record(PaymentRecord payment) async {
    final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
    await _firestore.collection(FirestorePaths.payments).doc(id).set(
          payment.toMap()..['updatedAt'] = DateTime.now(),
          SetOptions(merge: true),
        );

    if (payment.installmentId != null && payment.installmentId!.isNotEmpty) {
      await _installmentRepository.updateInstallmentPayment(
        installmentId: payment.installmentId!,
        paidAmount: payment.amount,
      );
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(installmentRepositoryProvider),
  );
});
