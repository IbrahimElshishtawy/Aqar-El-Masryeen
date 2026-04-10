import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class SupplierPaymentRepository {
  SupplierPaymentRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<SupplierPaymentRecord>> watchAll() {
    final source = _firestore
        .collection(FirestorePaths.supplierPayments)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupplierPaymentRecord.fromMap(doc.id, doc.data()))
              .where((entry) => !entry.archived)
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.supplierPayments,
      source: source,
      encode: _serializeSupplierPayment,
      decode: _deserializeSupplierPayment,
    );
  }

  Stream<List<SupplierPaymentRecord>> watchByProperty(String propertyId) {
    final source = _firestore
        .collection(FirestorePaths.supplierPayments)
        .orderBy('paidAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SupplierPaymentRecord.fromMap(doc.id, doc.data()))
              .where(
                (entry) => entry.propertyId == propertyId && !entry.archived,
              )
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.supplierPaymentsByProperty(propertyId),
      source: source,
      encode: _serializeSupplierPayment,
      decode: _deserializeSupplierPayment,
    );
  }

  Future<String> save(SupplierPaymentRecord payment) async {
    final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
    await _firestore
        .collection(FirestorePaths.supplierPayments)
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

  Future<void> softDelete(String paymentId) {
    return _firestore
        .collection(FirestorePaths.supplierPayments)
        .doc(paymentId)
        .update({'archived': true, 'updatedAt': DateTime.now()});
  }
}

final supplierPaymentRepositoryProvider = Provider<SupplierPaymentRepository>((
  ref,
) {
  return SupplierPaymentRepository(
    ref.watch(firestoreProvider),
    ref.watch(uuidProvider),
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializeSupplierPayment(SupplierPaymentRecord payment) {
  return {...payment.toMap(), 'id': payment.id};
}

SupplierPaymentRecord _deserializeSupplierPayment(Map<String, dynamic> map) {
  return SupplierPaymentRecord.fromMap(map['id'] as String? ?? '', map);
}
