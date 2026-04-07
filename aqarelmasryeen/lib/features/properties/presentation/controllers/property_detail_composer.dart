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

    final materialRowsByCategory = <MaterialCategory, List<MaterialExpenseEntry>>{
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
      totalProjectExpenses: totalDirectExpenses + materialsSnapshot.overallTotal,
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
    final summary = summaries.firstWhereOrNull((item) => item.unit.id == unitId);
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
