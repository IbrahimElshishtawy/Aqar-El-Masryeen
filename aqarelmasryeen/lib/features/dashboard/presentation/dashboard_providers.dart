import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/supplier_payment_repository.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardPropertiesProvider = StreamProvider.autoDispose(
  (ref) =>
      _fallbackToEmpty(ref.watch(propertyRepositoryProvider).watchProperties()),
);
final dashboardUnitsProvider = StreamProvider.autoDispose(
  (ref) => _fallbackToEmpty(ref.watch(salesRepositoryProvider).watchAll()),
);
final dashboardPaymentsProvider = StreamProvider.autoDispose(
  (ref) => _fallbackToEmpty(ref.watch(paymentRepositoryProvider).watchAll()),
);
final dashboardInstallmentsProvider = StreamProvider.autoDispose(
  (ref) => _fallbackToEmpty(
    ref.watch(installmentRepositoryProvider).watchAllInstallments(),
  ),
);
final dashboardExpensesProvider = StreamProvider.autoDispose(
  (ref) => _fallbackToEmpty(ref.watch(expenseRepositoryProvider).watchAll()),
);
final dashboardMaterialsProvider = StreamProvider.autoDispose(
  (ref) =>
      _fallbackToEmpty(ref.watch(materialExpenseRepositoryProvider).watchAll()),
);
final dashboardSupplierPaymentsProvider = StreamProvider.autoDispose(
  (ref) =>
      _fallbackToEmpty(ref.watch(supplierPaymentRepositoryProvider).watchAll()),
);
final dashboardPartnersProvider = StreamProvider.autoDispose(
  (ref) =>
      _fallbackToEmpty(ref.watch(partnerRepositoryProvider).watchPartners()),
);
final dashboardPartnerLedgerProvider = StreamProvider.autoDispose(
  (ref) =>
      _fallbackToEmpty(ref.watch(partnerLedgerRepositoryProvider).watchAll()),
);

final dashboardViewDataProvider =
    Provider.autoDispose<AsyncValue<DashboardViewData>>((ref) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(dashboardPropertiesProvider),
        ref.watch(dashboardUnitsProvider),
        ref.watch(dashboardPaymentsProvider),
        ref.watch(dashboardInstallmentsProvider),
        ref.watch(dashboardExpensesProvider),
        ref.watch(dashboardMaterialsProvider),
        ref.watch(dashboardSupplierPaymentsProvider),
        ref.watch(dashboardPartnersProvider),
        ref.watch(dashboardPartnerLedgerProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        final currentError = error.error;
        if (currentError is FirebaseException &&
            _shouldShowEmptyState(currentError)) {
          return AsyncData(_buildEmptyDashboardViewData(ref));
        }
        return AsyncError(
          currentError!,
          error.stackTrace ?? StackTrace.current,
        );
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final partners =
          ref.watch(dashboardPartnersProvider).valueOrNull ?? const [];
      final expenses =
          ref.watch(dashboardExpensesProvider).valueOrNull ?? const [];
      final materials =
          ref.watch(dashboardMaterialsProvider).valueOrNull ?? const [];
      final supplierPayments =
          ref.watch(dashboardSupplierPaymentsProvider).valueOrNull ?? const [];
      final partnerLedgerEntries =
          ref.watch(dashboardPartnerLedgerProvider).valueOrNull ?? const [];
      final session = ref.watch(authSessionProvider).valueOrNull;
      final currentUserId = session?.userId ?? '';
      final currentPartner = session == null
          ? null
          : partners.firstWhereOrNull(
              (partner) => partner.userId == session.userId,
            );
      final linkedPartnersCount = partners
          .where((partner) => partner.userId.isNotEmpty)
          .length;
      final partnerSummaries = const PartnerLedgerCalculator().build(
        partners: partners,
        expenses: expenses,
        materialExpenses: materials,
        supplierPayments: supplierPayments,
        ledgerEntries: partnerLedgerEntries,
      );

      return AsyncData(
        DashboardViewData(
          snapshot: const DashboardSnapshotBuilder().build(
            properties:
                ref.watch(dashboardPropertiesProvider).valueOrNull ?? const [],
            units: ref.watch(dashboardUnitsProvider).valueOrNull ?? const [],
            installments:
                ref.watch(dashboardInstallmentsProvider).valueOrNull ??
                const [],
            payments:
                ref.watch(dashboardPaymentsProvider).valueOrNull ?? const [],
            expenses:
                ref.watch(dashboardExpensesProvider).valueOrNull ?? const [],
            materials: materials,
            supplierPayments: supplierPayments,
            partners: partners,
          ),
          partners: partners,
          currentPartner: currentPartner,
          currentUserId: currentUserId,
          linkedPartnersCount: linkedPartnersCount,
          partnerSummaries: partnerSummaries,
        ),
      );
    });

DashboardViewData _buildEmptyDashboardViewData(Ref ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;

  return DashboardViewData(
    snapshot: const DashboardSnapshotBuilder().build(
      properties: const [],
      units: const [],
      installments: const [],
    payments: const [],
    expenses: const [],
    materials: const [],
    supplierPayments: const [],
    partners: const [],
  ),
    partners: const [],
    currentPartner: null,
    currentUserId: session?.userId ?? '',
    linkedPartnersCount: 0,
    partnerSummaries: const [],
  );
}

class DashboardViewData {
  const DashboardViewData({
    required this.snapshot,
    required this.partners,
    required this.currentPartner,
    required this.currentUserId,
    required this.linkedPartnersCount,
    required this.partnerSummaries,
  });

  final DashboardSnapshot snapshot;
  final List<Partner> partners;
  final Partner? currentPartner;
  final String currentUserId;
  final int linkedPartnersCount;
  final List<PartnerLedgerSummaryRow> partnerSummaries;
}

Stream<List<T>> _fallbackToEmpty<T>(Stream<List<T>> source) async* {
  try {
    yield* source;
  } on FirebaseException catch (error) {
    if (_shouldShowEmptyState(error)) {
      yield const [];
      return;
    }
    rethrow;
  }
}

bool _shouldShowEmptyState(FirebaseException error) {
  return error.plugin == 'cloud_firestore' &&
      (error.code == 'permission-denied' || error.code == 'unauthenticated');
}
