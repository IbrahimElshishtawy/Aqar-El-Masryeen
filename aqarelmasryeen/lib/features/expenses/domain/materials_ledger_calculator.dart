import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:collection/collection.dart';

class MaterialCategoryTotal {
  const MaterialCategoryTotal({
    required this.categoryLabel,
    required this.totalQuantity,
    required this.totalSpending,
  });

  final String categoryLabel;
  final double totalQuantity;
  final double totalSpending;
}

class SupplierLedgerSummary {
  const SupplierLedgerSummary({
    required this.supplierName,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalRemaining,
    required this.invoiceCount,
  });

  final String supplierName;
  final double totalPurchased;
  final double totalPaid;
  final double totalRemaining;
  final int invoiceCount;
}

class MaterialsLedgerSnapshot {
  const MaterialsLedgerSnapshot({
    required this.entries,
    required this.supplierSummaries,
    required this.categoryTotals,
    required this.overallTotal,
    required this.overallPaid,
    required this.overallRemaining,
  });

  final List<MaterialExpenseEntry> entries;
  final List<SupplierLedgerSummary> supplierSummaries;
  final List<MaterialCategoryTotal> categoryTotals;
  final double overallTotal;
  final double overallPaid;
  final double overallRemaining;
}

class MaterialsLedgerCalculator {
  const MaterialsLedgerCalculator();

  MaterialsLedgerSnapshot build(List<MaterialExpenseEntry> entries) {
    final activeEntries = entries.where((entry) => !entry.archived).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final overallTotal = activeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalPrice,
    );
    final overallPaid = activeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amountPaid,
    );
    final overallRemaining = activeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amountRemaining,
    );

    final supplierSummaries = activeEntries
        .groupListsBy((entry) => entry.supplierName.trim())
        .entries
        .map((entry) {
          final supplierEntries = entry.value;
          return SupplierLedgerSummary(
            supplierName: entry.key.isEmpty ? 'مورد غير محدد' : entry.key,
            totalPurchased: supplierEntries.fold<double>(
              0,
              (sum, item) => sum + item.totalPrice,
            ),
            totalPaid: supplierEntries.fold<double>(
              0,
              (sum, item) => sum + item.amountPaid,
            ),
            totalRemaining: supplierEntries.fold<double>(
              0,
              (sum, item) => sum + item.amountRemaining,
            ),
            invoiceCount: supplierEntries.length,
          );
        })
        .sorted((a, b) => b.totalRemaining.compareTo(a.totalRemaining));

    final categoryTotals = activeEntries
        .groupListsBy((entry) => entry.materialCategory.label)
        .entries
        .map((entry) {
          final categoryEntries = entry.value;
          return MaterialCategoryTotal(
            categoryLabel: entry.key,
            totalQuantity: categoryEntries.fold<double>(
              0,
              (sum, item) => sum + item.quantity,
            ),
            totalSpending: categoryEntries.fold<double>(
              0,
              (sum, item) => sum + item.totalPrice,
            ),
          );
        })
        .sorted((a, b) => b.totalSpending.compareTo(a.totalSpending));

    return MaterialsLedgerSnapshot(
      entries: activeEntries,
      supplierSummaries: supplierSummaries,
      categoryTotals: categoryTotals,
      overallTotal: overallTotal,
      overallPaid: overallPaid,
      overallRemaining: overallRemaining,
    );
  }
}
