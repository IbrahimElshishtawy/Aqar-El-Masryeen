import 'package:aqarelmasryeen/core/utils/partner_display_labels.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';

class PropertyProjectViewData {
  const PropertyProjectViewData({
    required this.property,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.currentPartner,
    required this.partners,
    required this.unitSummaries,
    required this.installments,
    required this.payments,
    required this.directExpenses,
    required this.expenseLedgerRows,
    required this.materials,
    required this.supplierPayments,
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
  });

  final PropertyProject property;
  final String? currentUserId;
  final String currentUserDisplayName;
  final Partner? currentPartner;
  final List<Partner> partners;
  final List<UnitSaleComputedSummary> unitSummaries;
  final List<Installment> installments;
  final List<PaymentRecord> payments;
  final List<ExpenseRecord> directExpenses;
  final List<PropertyExpenseLedgerRow> expenseLedgerRows;
  final List<MaterialExpenseEntry> materials;
  final List<SupplierPaymentRecord> supplierPayments;
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

  int get totalUnitsCount => property.apartmentCount > 0
      ? property.apartmentCount
      : unitSummaries.length;

  int get soldUnitsCount =>
      unitSummaries.where((summary) => summary.unit.hasRecordedSale).length;

  String get currentColumnLabel => 'المستخدم';

  List<Partner> get counterpartPartners {
    if (currentPartner == null) {
      return partners;
    }
    return partners
        .where((partner) => partner.id != currentPartner!.id)
        .toList();
  }

  String get counterpartLabel => counterpartColumnLabel;

  String get counterpartColumnLabel => resolveCounterpartPartyLabel(
    partners: partners,
    currentPartner: currentPartner,
    fallback: 'الشريك',
    maxVisibleNames: 1,
  );

  bool get hasLinkedPartner => counterpartPartners.isNotEmpty;

  String? get linkedPartnerName {
    if (!hasLinkedPartner) {
      return null;
    }
    return summarizePartnerNames(
      counterpartPartners,
      fallback: 'الشريك المرتبط',
      maxVisibleNames: 1,
    );
  }
}

class PropertyUnitViewData {
  const PropertyUnitViewData({
    required this.property,
    required this.summary,
    required this.payments,
    required this.unitExpenses,
    required this.planId,
    required this.currentUserId,
    required this.currentUserDisplayName,
    required this.currentPartner,
    required this.partners,
  });

  final PropertyProject property;
  final UnitSaleComputedSummary summary;
  final List<PaymentRecord> payments;
  final List<UnitExpenseRecord> unitExpenses;
  final String planId;
  final String? currentUserId;
  final String currentUserDisplayName;
  final Partner? currentPartner;
  final List<Partner> partners;

  String get currentColumnLabel =>
      resolveCurrentPartyLabel(currentPartner, fallback: 'المستخدم');

  List<Partner> get counterpartPartners {
    if (currentPartner == null) {
      return partners;
    }
    return partners
        .where((partner) => partner.id != currentPartner!.id)
        .toList(growable: false);
  }

  String get counterpartColumnLabel => resolveCounterpartPartyLabel(
    partners: partners,
    currentPartner: currentPartner,
    fallback: 'الشريك',
    maxVisibleNames: 1,
  );

  bool isCurrentUserUnitExpense(UnitExpenseRecord expense) {
    if (currentPartner != null &&
        expense.paidByPartnerId == currentPartner!.id) {
      return true;
    }
    return expense.paidByPartnerId.trim().isEmpty &&
        currentUserId != null &&
        expense.createdBy == currentUserId;
  }

  double get currentUserUnitExpensesTotal => unitExpenses.fold<double>(
    0,
    (sum, expense) =>
        sum + (isCurrentUserUnitExpense(expense) ? expense.amount : 0),
  );

  double get counterpartUnitExpensesTotal => unitExpenses.fold<double>(
    0,
    (sum, expense) =>
        sum + (isCurrentUserUnitExpense(expense) ? 0 : expense.amount),
  );

  int get unitExpensesCount => unitExpenses.length;

  String payerLabelForUnitExpense(UnitExpenseRecord expense) {
    if (isCurrentUserUnitExpense(expense)) {
      return currentColumnLabel;
    }

    for (final partner in counterpartPartners) {
      if (partner.id == expense.paidByPartnerId) {
        final name = partner.name.trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return counterpartColumnLabel;
  }
}

class PropertyExpenseLedgerRow {
  const PropertyExpenseLedgerRow({required this.expense, required this.payer});

  final ExpenseRecord expense;
  final Partner? payer;
}
