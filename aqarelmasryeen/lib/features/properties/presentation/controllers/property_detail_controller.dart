import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final propertyDetailsProvider = StreamProvider.autoDispose
    .family<PropertyProject?, String>(
      (ref, propertyId) =>
          ref.watch(propertyRepositoryProvider).watchProperty(propertyId),
    );

final propertyUnitsProvider = StreamProvider.autoDispose
    .family<List<UnitSale>, String>(
      (ref, propertyId) =>
          ref.watch(salesRepositoryProvider).watchByProperty(propertyId),
    );

final propertyInstallmentsProvider = StreamProvider.autoDispose
    .family<List<Installment>, String>(
      (ref, propertyId) => ref
          .watch(installmentRepositoryProvider)
          .watchInstallmentsByProperty(propertyId),
    );

final propertyPaymentsProvider = StreamProvider.autoDispose
    .family<List<PaymentRecord>, String>(
      (ref, propertyId) =>
          ref.watch(paymentRepositoryProvider).watchByProperty(propertyId),
    );

final propertyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseRecord>, String>(
      (ref, propertyId) =>
          ref.watch(expenseRepositoryProvider).watchByProperty(propertyId),
    );

final propertyMaterialsProvider = StreamProvider.autoDispose
    .family<List<MaterialExpenseEntry>, String>(
      (ref, propertyId) => ref
          .watch(materialExpenseRepositoryProvider)
          .watchByProperty(propertyId),
    );

final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final propertyPartnerLedgerProvider =
    StreamProvider.autoDispose<List<PartnerLedgerEntry>>(
      (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
    );

final propertyProjectViewDataProvider = Provider.autoDispose
    .family<AsyncValue<PropertyProjectViewData?>, String>((ref, propertyId) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertyDetailsProvider(propertyId)),
        ref.watch(propertyUnitsProvider(propertyId)),
        ref.watch(propertyInstallmentsProvider(propertyId)),
        ref.watch(propertyPaymentsProvider(propertyId)),
        ref.watch(propertyExpensesProvider(propertyId)),
        ref.watch(propertyMaterialsProvider(propertyId)),
        ref.watch(propertyPartnersProvider),
        ref.watch(propertyPartnerLedgerProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final property = ref
          .watch(propertyDetailsProvider(propertyId))
          .valueOrNull;
      if (property == null) {
        return const AsyncData(null);
      }

      final session = ref.watch(authSessionProvider).valueOrNull;
      final composer = const PropertyDetailComposer();

      return AsyncData(
        composer.buildProjectViewData(
          property: property,
          currentUserId: session?.userId,
          units:
              ref.watch(propertyUnitsProvider(propertyId)).valueOrNull ??
              const [],
          installments:
              ref.watch(propertyInstallmentsProvider(propertyId)).valueOrNull ??
              const [],
          payments:
              ref.watch(propertyPaymentsProvider(propertyId)).valueOrNull ??
              const [],
          expenses:
              ref.watch(propertyExpensesProvider(propertyId)).valueOrNull ??
              const [],
          materials:
              ref.watch(propertyMaterialsProvider(propertyId)).valueOrNull ??
              const [],
          partners: ref.watch(propertyPartnersProvider).valueOrNull ?? const [],
          partnerLedgers:
              ref.watch(propertyPartnerLedgerProvider).valueOrNull ?? const [],
        ),
      );
    });

final propertyUnitViewDataProvider = Provider.autoDispose
    .family<AsyncValue<PropertyUnitViewData?>, PropertyUnitRequest>((
      ref,
      request,
    ) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertyDetailsProvider(request.propertyId)),
        ref.watch(propertyUnitsProvider(request.propertyId)),
        ref.watch(propertyInstallmentsProvider(request.propertyId)),
        ref.watch(propertyPaymentsProvider(request.propertyId)),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final property = ref
          .watch(propertyDetailsProvider(request.propertyId))
          .valueOrNull;
      if (property == null) {
        return const AsyncData(null);
      }

      final composer = const PropertyDetailComposer();
      return AsyncData(
        composer.buildUnitViewData(
          property: property,
          unitId: request.unitId,
          units:
              ref
                  .watch(propertyUnitsProvider(request.propertyId))
                  .valueOrNull ??
              const [],
          installments:
              ref
                  .watch(propertyInstallmentsProvider(request.propertyId))
                  .valueOrNull ??
              const [],
          payments:
              ref
                  .watch(propertyPaymentsProvider(request.propertyId))
                  .valueOrNull ??
              const [],
        ),
      );
    });

class PropertyUnitRequest {
  const PropertyUnitRequest({required this.propertyId, required this.unitId});

  final String propertyId;
  final String unitId;

  @override
  bool operator ==(Object other) {
    return other is PropertyUnitRequest &&
        other.propertyId == propertyId &&
        other.unitId == unitId;
  }

  @override
  int get hashCode => Object.hash(propertyId, unitId);
}

class PropertyProjectViewData {
  const PropertyProjectViewData({
    required this.property,
    required this.currentUserId,
    required this.currentPartner,
    required this.normalizedCurrentShare,
    required this.partners,
    required this.unitSummaries,
    required this.installments,
    required this.payments,
    required this.directExpenses,
    required this.expenseLedgerRows,
    required this.dailyExpenseRows,
    required this.materials,
    required this.materialsSnapshot,
    required this.featuredMaterialCategories,
    required this.featuredMaterialTotals,
    required this.materialRowsByCategory,
    required this.partnerSummaries,
    required this.partnerHistory,
    required this.partnerEntriesByPartner,
    required this.totalSalesValue,
    required this.totalPaidInstallments,
    required this.totalRemainingInstallments,
    required this.overdueInstallments,
    required this.totalDirectExpenses,
    required this.totalProjectExpenses,
    required this.todayDirectExpenses,
    required this.myTodayExpenseShare,
    required this.counterpartTodayExpenseShare,
  });

  final PropertyProject property;
  final String? currentUserId;
  final Partner? currentPartner;
  final double normalizedCurrentShare;
  final List<Partner> partners;
  final List<UnitSaleComputedSummary> unitSummaries;
  final List<Installment> installments;
  final List<PaymentRecord> payments;
  final List<ExpenseRecord> directExpenses;
  final List<PropertyExpenseLedgerRow> expenseLedgerRows;
  final List<PropertyExpenseDayRow> dailyExpenseRows;
  final List<MaterialExpenseEntry> materials;
  final MaterialsLedgerSnapshot materialsSnapshot;
  final List<MaterialCategory> featuredMaterialCategories;
  final List<MaterialCategoryTotal> featuredMaterialTotals;
  final Map<MaterialCategory, List<MaterialExpenseEntry>>
  materialRowsByCategory;
  final List<PartnerLedgerSummaryRow> partnerSummaries;
  final List<PartnerLedgerEntry> partnerHistory;
  final Map<String, List<PartnerLedgerEntry>> partnerEntriesByPartner;
  final double totalSalesValue;
  final double totalPaidInstallments;
  final double totalRemainingInstallments;
  final int overdueInstallments;
  final double totalDirectExpenses;
  final double totalProjectExpenses;
  final double todayDirectExpenses;
  final double myTodayExpenseShare;
  final double counterpartTodayExpenseShare;

  String get myLabel => currentPartner?.name ?? 'حصتي';

  List<Partner> get counterpartPartners {
    if (currentPartner == null) {
      return partners;
    }
    return partners
        .where((partner) => partner.id != currentPartner!.id)
        .toList();
  }

  String get counterpartLabel {
    if (counterpartPartners.length == 1) {
      return counterpartPartners.first.name;
    }
    return counterpartPartners.isEmpty ? 'الشريك' : 'الشركاء';
  }
}

class PropertyUnitViewData {
  const PropertyUnitViewData({
    required this.property,
    required this.summary,
    required this.payments,
    required this.planId,
  });

  final PropertyProject property;
  final UnitSaleComputedSummary summary;
  final List<PaymentRecord> payments;
  final String planId;
}

class PropertyExpenseLedgerRow {
  const PropertyExpenseLedgerRow({
    required this.expense,
    required this.payer,
    required this.myShare,
    required this.counterpartShare,
  });

  final ExpenseRecord expense;
  final Partner? payer;
  final double myShare;
  final double counterpartShare;
}

class PropertyExpenseDayRow {
  const PropertyExpenseDayRow({
    required this.day,
    required this.entriesCount,
    required this.total,
    required this.myShare,
    required this.counterpartShare,
  });

  final DateTime day;
  final int entriesCount;
  final double total;
  final double myShare;
  final double counterpartShare;
}

class PropertyDetailComposer {
  const PropertyDetailComposer();

  PropertyProjectViewData buildProjectViewData({
    required PropertyProject property,
    required String? currentUserId,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required List<ExpenseRecord> expenses,
    required List<MaterialExpenseEntry> materials,
    required List<Partner> partners,
    required List<PartnerLedgerEntry> partnerLedgers,
  }) {
    final activeExpenses =
        expenses.where((expense) => !expense.archived).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final activeMaterials = materials.where((entry) => !entry.archived).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final propertyPartnerHistory = partnerLedgers
        .where((entry) => !entry.archived && entry.propertyId == property.id)
        .sorted((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final unitSummaries = const UnitSalesCalculator().build(
      units: units,
      installments: installments,
      payments: payments,
    );
    final materialsSnapshot = const MaterialsLedgerCalculator().build(
      activeMaterials,
    );
    final partnerSummaries = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: activeExpenses,
      materialExpenses: activeMaterials,
      ledgerEntries: propertyPartnerHistory,
    );

    final currentPartner = partners.firstWhereOrNull(
      (partner) => partner.userId == currentUserId,
    );
    final normalizedCurrentShare = _normalizedShare(
      partners: partners,
      currentPartner: currentPartner,
    );

    final expenseLedgerRows = activeExpenses.map((expense) {
      final payer = partners.firstWhereOrNull(
        (partner) => partner.id == expense.paidByPartnerId,
      );
      final myShare = expense.amount * normalizedCurrentShare;
      return PropertyExpenseLedgerRow(
        expense: expense,
        payer: payer,
        myShare: myShare,
        counterpartShare: expense.amount - myShare,
      );
    }).toList()..sort((a, b) => b.expense.date.compareTo(a.expense.date));

    final dailyExpenseRows = expenseLedgerRows
        .groupListsBy((row) => _dateOnly(row.expense.date))
        .entries
        .map((entry) {
          final rows = entry.value;
          return PropertyExpenseDayRow(
            day: entry.key,
            entriesCount: rows.length,
            total: rows.fold<double>(0, (sum, row) => sum + row.expense.amount),
            myShare: rows.fold<double>(0, (sum, row) => sum + row.myShare),
            counterpartShare: rows.fold<double>(
              0,
              (sum, row) => sum + row.counterpartShare,
            ),
          );
        })
        .sorted((a, b) => b.day.compareTo(a.day));

    final today = _dateOnly(DateTime.now());
    final todayRows = expenseLedgerRows
        .where((row) => _dateOnly(row.expense.date) == today)
        .toList();

    final materialRowsByCategory =
        <MaterialCategory, List<MaterialExpenseEntry>>{
          for (final category in MaterialCategory.values)
            category: activeMaterials
                .where((entry) => entry.materialCategory == category)
                .sorted((a, b) => b.date.compareTo(a.date)),
        };

    final featuredMaterialCategories = [
      MaterialCategory.cement,
      MaterialCategory.brick,
      MaterialCategory.steel,
    ];

    final featuredMaterialTotals = featuredMaterialCategories.map((category) {
      final rows = materialRowsByCategory[category] ?? const [];
      return MaterialCategoryTotal(
        categoryLabel: category.label,
        totalQuantity: rows.fold<double>(0, (sum, item) => sum + item.quantity),
        totalSpending: rows.fold<double>(
          0,
          (sum, item) => sum + item.totalPrice,
        ),
      );
    }).toList();

    final partnerEntriesByPartner = <String, List<PartnerLedgerEntry>>{
      for (final partner in partners)
        partner.id: propertyPartnerHistory
            .where((entry) => entry.partnerId == partner.id)
            .toList(),
    };

    final totalSalesValue = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalContractAmount,
    );
    final totalPaidInstallments = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalPaidInstallmentsAmount,
    );
    final totalRemainingInstallments = unitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalRemainingInstallmentsAmount,
    );
    final overdueInstallments = unitSummaries.fold<int>(
      0,
      (sum, item) => sum + item.overdueInstallmentsCount,
    );
    final totalDirectExpenses = activeExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return PropertyProjectViewData(
      property: property,
      currentUserId: currentUserId,
      currentPartner: currentPartner,
      normalizedCurrentShare: normalizedCurrentShare,
      partners: partners,
      unitSummaries: unitSummaries,
      installments: installments,
      payments: payments,
      directExpenses: activeExpenses,
      expenseLedgerRows: expenseLedgerRows,
      dailyExpenseRows: dailyExpenseRows,
      materials: activeMaterials,
      materialsSnapshot: materialsSnapshot,
      featuredMaterialCategories: featuredMaterialCategories,
      featuredMaterialTotals: featuredMaterialTotals,
      materialRowsByCategory: materialRowsByCategory,
      partnerSummaries: partnerSummaries,
      partnerHistory: propertyPartnerHistory,
      partnerEntriesByPartner: partnerEntriesByPartner,
      totalSalesValue: totalSalesValue,
      totalPaidInstallments: totalPaidInstallments,
      totalRemainingInstallments: totalRemainingInstallments,
      overdueInstallments: overdueInstallments,
      totalDirectExpenses: totalDirectExpenses,
      totalProjectExpenses:
          totalDirectExpenses + materialsSnapshot.overallTotal,
      todayDirectExpenses: todayRows.fold<double>(
        0,
        (sum, row) => sum + row.expense.amount,
      ),
      myTodayExpenseShare: todayRows.fold<double>(
        0,
        (sum, row) => sum + row.myShare,
      ),
      counterpartTodayExpenseShare: todayRows.fold<double>(
        0,
        (sum, row) => sum + row.counterpartShare,
      ),
    );
  }

  PropertyUnitViewData? buildUnitViewData({
    required PropertyProject property,
    required String unitId,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
  }) {
    final summaries = const UnitSalesCalculator().build(
      units: units,
      installments: installments,
      payments: payments,
    );
    final summary = summaries.firstWhereOrNull(
      (item) => item.unit.id == unitId,
    );
    if (summary == null) {
      return null;
    }

    final planId =
        installments
            .firstWhereOrNull((installment) => installment.unitId == unitId)
            ?.planId ??
        '';
    final unitPayments = payments
        .where((payment) => payment.unitId == unitId)
        .sorted((a, b) => b.receivedAt.compareTo(a.receivedAt));

    return PropertyUnitViewData(
      property: property,
      summary: summary,
      payments: unitPayments,
      planId: planId,
    );
  }

  double _normalizedShare({
    required List<Partner> partners,
    required Partner? currentPartner,
  }) {
    if (currentPartner == null) {
      return partners.length == 1 ? 1 : 0;
    }
    final totalRatio = partners.fold<double>(
      0,
      (sum, partner) => sum + partner.shareRatio,
    );
    if (totalRatio <= 0) {
      return 1 / partners.length.clamp(1, partners.length);
    }
    return currentPartner.shareRatio / totalRatio;
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
