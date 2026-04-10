import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_view_data.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';

class PropertyDetailComposer {
  const PropertyDetailComposer();

  PropertyProjectViewData buildProjectViewData({
    required PropertyProject property,
    required String? currentUserId,
    required String currentUserDisplayName,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required List<ExpenseRecord> expenses,
    required List<MaterialExpenseEntry> materials,
    required List<SupplierPaymentRecord> supplierPayments,
    required List<Partner> partners,
    required List<PartnerLedgerEntry> partnerLedgers,
  }) {
    final activeExpenses =
        expenses.where((expense) => !expense.archived).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final activeMaterials = materials.where((entry) => !entry.archived).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final activeSupplierPayments =
        supplierPayments.where((payment) => !payment.archived).toList()
          ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
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
      supplierPayments: activeSupplierPayments,
    );
    final partnerSummaries = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: activeExpenses,
      materialExpenses: activeMaterials,
      supplierPayments: activeSupplierPayments,
      ledgerEntries: propertyPartnerHistory,
    );

    final currentPartner = partners.firstWhereOrNull(
      (partner) => partner.userId == currentUserId,
    );

    final expenseLedgerRows = activeExpenses.map((expense) {
      final payer = partners.firstWhereOrNull(
        (partner) => partner.id == expense.paidByPartnerId,
      );
      return PropertyExpenseLedgerRow(expense: expense, payer: payer);
    }).toList()..sort((a, b) => b.expense.date.compareTo(a.expense.date));

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

    final trackedUnitSummaries = unitSummaries
        .where((summary) => summary.unit.hasRecordedSale)
        .toList(growable: false);

    final totalSalesValue = trackedUnitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalContractAmount,
    );
    final totalPaidInstallments = trackedUnitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalPaidSoFar,
    );
    final totalRemainingInstallments = trackedUnitSummaries.fold<double>(
      0,
      (sum, item) => sum + item.totalRemaining,
    );
    final overdueInstallments = trackedUnitSummaries.fold<int>(
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
      currentUserDisplayName: currentUserDisplayName,
      currentPartner: currentPartner,
      partners: partners,
      unitSummaries: unitSummaries,
      installments: installments,
      payments: payments,
      directExpenses: activeExpenses,
      expenseLedgerRows: expenseLedgerRows,
      materials: activeMaterials,
      supplierPayments: activeSupplierPayments,
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
    );
  }

  PropertyUnitViewData? buildUnitViewData({
    required PropertyProject property,
    required String unitId,
    required String? currentUserId,
    required String currentUserDisplayName,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required List<UnitExpenseRecord> unitExpenses,
    required List<Partner> partners,
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
    final activeUnitExpenses = unitExpenses
        .where((expense) => !expense.archived && expense.unitId == unitId)
        .sorted((a, b) => b.date.compareTo(a.date));
    final currentPartner = partners.firstWhereOrNull(
      (partner) => partner.userId == currentUserId,
    );

    return PropertyUnitViewData(
      property: property,
      summary: summary,
      payments: unitPayments,
      unitExpenses: activeUnitExpenses,
      planId: planId,
      currentUserId: currentUserId,
      currentUserDisplayName: currentUserDisplayName,
      currentPartner: currentPartner,
      partners: partners,
    );
  }
}
