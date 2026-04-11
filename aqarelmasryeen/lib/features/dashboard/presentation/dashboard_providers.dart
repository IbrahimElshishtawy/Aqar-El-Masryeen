import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_scope.dart';
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
import 'package:aqarelmasryeen/features/settings/data/activity_repository.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardPropertiesProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  final workspaceId = session?.profile?.workspaceId.trim() ?? '';
  final scopedPartners =
      ref.watch(dashboardPartnersProvider).valueOrNull ?? const <Partner>[];
  final accountUserIds = {
    session?.userId ?? '',
    ...scopedPartners
        .map((partner) => partner.userId.trim())
        .where((userId) => userId.isNotEmpty),
  }..removeWhere((userId) => userId.trim().isEmpty);
  return ref
      .watch(propertyRepositoryProvider)
      .watchProperties(
        workspaceId: workspaceId,
        accountUserIds: accountUserIds,
      );
});
final dashboardUnitsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(salesRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardPaymentsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(paymentRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardInstallmentsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(installmentRepositoryProvider)
      .watchAllInstallments(
        workspaceId: session?.profile?.workspaceId.trim() ?? '',
      );
});
final dashboardExpensesProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(expenseRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardMaterialsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(materialExpenseRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardSupplierPaymentsProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(supplierPaymentRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardPartnersProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(partnerRepositoryProvider)
      .watchPartners(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardPartnerLedgerProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  return ref
      .watch(partnerLedgerRepositoryProvider)
      .watchAll(workspaceId: session?.profile?.workspaceId.trim() ?? '');
});
final dashboardActivityProvider = StreamProvider.autoDispose((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  final workspaceId = session?.profile?.workspaceId.trim() ?? '';
  return ref
      .watch(activityRepositoryProvider)
      .watchRecent(workspaceId: workspaceId);
});

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
        ref.watch(dashboardActivityProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final allPartners =
          ref.watch(dashboardPartnersProvider).valueOrNull ?? const [];
      final allProperties =
          ref.watch(dashboardPropertiesProvider).valueOrNull ?? const [];
      final allUnits =
          ref.watch(dashboardUnitsProvider).valueOrNull ?? const [];
      final allInstallments =
          ref.watch(dashboardInstallmentsProvider).valueOrNull ?? const [];
      final allPayments =
          ref.watch(dashboardPaymentsProvider).valueOrNull ?? const [];
      final allExpenses =
          ref.watch(dashboardExpensesProvider).valueOrNull ?? const [];
      final allMaterials =
          ref.watch(dashboardMaterialsProvider).valueOrNull ?? const [];
      final allSupplierPayments =
          ref.watch(dashboardSupplierPaymentsProvider).valueOrNull ?? const [];
      final partnerLedgerEntries =
          ref.watch(dashboardPartnerLedgerProvider).valueOrNull ?? const [];
      final recentActivity =
          ref.watch(dashboardActivityProvider).valueOrNull ?? const [];
      final session = ref.watch(authSessionProvider).valueOrNull;
      final currentUserId = session?.userId ?? '';

      final scopedData = const DashboardScopeResolver().resolve(
        profile: session?.profile,
        currentUserId: currentUserId,
        partners: allPartners,
        properties: allProperties,
        units: allUnits,
        installments: allInstallments,
        payments: allPayments,
        expenses: allExpenses,
        materials: allMaterials,
        supplierPayments: allSupplierPayments,
      );

      final currentPartner = session == null
          ? null
          : scopedData.partners.firstWhereOrNull(
              (partner) => partner.userId == session.userId,
            );
      final linkedPartnersCount = scopedData.partners
          .where((partner) => partner.userId.isNotEmpty)
          .length;
      final partnerSummaries = const PartnerLedgerCalculator().build(
        partners: scopedData.partners,
        expenses: scopedData.expenses,
        materialExpenses: scopedData.materials,
        supplierPayments: scopedData.supplierPayments,
        ledgerEntries: partnerLedgerEntries,
      );

      return AsyncData(
        DashboardViewData(
          snapshot: const DashboardSnapshotBuilder().build(
            properties: scopedData.properties,
            units: scopedData.units,
            installments: scopedData.installments,
            payments: scopedData.payments,
            expenses: scopedData.expenses,
            materials: scopedData.materials,
            supplierPayments: scopedData.supplierPayments,
            partners: scopedData.partners,
            currentUserId: currentUserId,
            currentPartnerId: currentPartner?.id,
            recentActivity: recentActivity,
          ),
          partners: scopedData.partners,
          currentPartner: currentPartner,
          currentUserId: currentUserId,
          linkedPartnersCount: linkedPartnersCount,
          partnerSummaries: partnerSummaries,
        ),
      );
    });

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
