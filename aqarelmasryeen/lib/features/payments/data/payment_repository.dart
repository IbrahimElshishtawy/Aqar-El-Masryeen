import 'package:aqarelmasryeen/app/providers.dart';
import 'package:aqarelmasryeen/core/constants/firestore_paths.dart';
import 'package:aqarelmasryeen/core/storage/cache_keys.dart';
import 'package:aqarelmasryeen/core/storage/cache_policy.dart';
import 'package:aqarelmasryeen/core/storage/local_cache_service.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class PaymentRepository {
  PaymentRepository(this._firestore, this._uuid, this._cache);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final LocalCacheService _cache;

  Stream<List<PaymentRecord>> watchAll() {
    final source = _firestore
        .collection(FirestorePaths.payments)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PaymentRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );

    return CachePolicy.watchList(
      cache: _cache,
      cacheKey: CacheKeys.payments,
      source: source,
      encode: _serializePayment,
      decode: _deserializePayment,
    );
  }

  Stream<List<PaymentRecord>> watchByProperty(String propertyId) {
    final source = _firestore
        .collection(FirestorePaths.payments)
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
      cacheKey: CacheKeys.paymentsByProperty(propertyId),
      source: source,
      encode: _serializePayment,
      decode: _deserializePayment,
    );
  }

  Stream<List<PaymentRecord>> watchByUnit(String unitId) {
    final source = _firestore
        .collection(FirestorePaths.payments)
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
      cacheKey: CacheKeys.paymentsByUnit(unitId),
      source: source,
      encode: _serializePayment,
      decode: _deserializePayment,
    );
  }

  Future<String> save(PaymentRecord payment) async {
    final id = payment.id.isEmpty ? _uuid.v4() : payment.id;
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
    ref.watch(localCacheServiceProvider),
  );
});

Map<String, dynamic> _serializePayment(PaymentRecord payment) {
  return {...payment.toMap(), 'id': payment.id};
}

PaymentRecord _deserializePayment(Map<String, dynamic> map) {
  return PaymentRecord.fromMap(map['id'] as String? ?? '', map);
}
