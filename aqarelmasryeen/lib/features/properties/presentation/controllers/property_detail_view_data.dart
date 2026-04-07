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
    required this.myTotalExpenseShare,
    required this.counterpartTotalExpenseShare,
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
  final double myTotalExpenseShare;
  final double counterpartTotalExpenseShare;

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
