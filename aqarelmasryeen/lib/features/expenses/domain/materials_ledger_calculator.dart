import 'dart:math' as math;

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

  MaterialsLedgerSnapshot build(
    List<MaterialExpenseEntry> entries, {
    List<SupplierPaymentRecord> supplierPayments = const [],
  }) {
    final activeEntries = entries.where((entry) => !entry.archived).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final activeSupplierPayments = supplierPayments
        .where((payment) => !payment.archived)
        .toList(growable: false);
    final entriesBySupplierKey = activeEntries.groupListsBy(
      (entry) => _supplierLedgerKey(
        propertyId: entry.propertyId,
        supplierName: entry.supplierName,
      ),
    );
    final paymentsBySupplierKey = activeSupplierPayments.groupListsBy(
      (payment) => _supplierLedgerKey(
        propertyId: payment.propertyId,
        supplierName: payment.supplierName,
      ),
    );
    final supplierKeys = {
      ...entriesBySupplierKey.keys,
      ...paymentsBySupplierKey.keys,
    };
    final supplierSummaries = supplierKeys
        .map(
          (supplierKey) => _buildSupplierSummary(
            entries: entriesBySupplierKey[supplierKey] ?? const [],
            supplierPayments: paymentsBySupplierKey[supplierKey] ?? const [],
          ),
        )
        .where(
          (summary) =>
              summary.totalPurchased > 0 ||
              summary.totalPaid > 0 ||
              summary.invoiceCount > 0,
        )
        .sorted((a, b) {
          final remainingCompare = b.totalRemaining.compareTo(a.totalRemaining);
          if (remainingCompare != 0) {
            return remainingCompare;
          }
          return b.totalPurchased.compareTo(a.totalPurchased);
        });
    final overallTotal = supplierSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalPurchased,
    );
    final overallPaid = supplierSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalPaid,
    );
    final overallRemaining = supplierSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalRemaining,
    );

    final categoryTotals = activeEntries
        .groupListsBy((entry) => entry.materialCategory.label)
        .entries
        .map((entry) {
          final categoryEntries = entry.value;
          return MaterialCategoryTotal(
            categoryLabel: entry.key,
            totalQuantity: categoryEntries.fold<double>(
              0,
              (sum, item) => sum + item.quantityValue,
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

  SupplierLedgerSummary _buildSupplierSummary({
    required List<MaterialExpenseEntry> entries,
    required List<SupplierPaymentRecord> supplierPayments,
  }) {
    final normalizedSupplierName = entries.isNotEmpty
        ? _normalizeSupplierName(entries.first.supplierName)
        : supplierPayments.isNotEmpty
        ? _normalizeSupplierName(supplierPayments.first.supplierName)
        : 'مورد غير محدد';
    final totalPurchased = entries.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final recordedPaidFromInvoices = entries.fold<double>(
      0,
      (sum, item) => sum + item.amountPaid,
    );
    final initialPaidAmount = entries.fold<double>(
      0,
      (sum, item) => sum + item.initialPaidAmount,
    );
    final recordedSupplierPayments = supplierPayments.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final resolvedPaid = math.max(
      recordedPaidFromInvoices,
      initialPaidAmount + recordedSupplierPayments,
    );
    final resolvedRemaining = totalPurchased <= 0
        ? 0.0
        : (totalPurchased - resolvedPaid).clamp(0, totalPurchased).toDouble();

    return SupplierLedgerSummary(
      supplierName: normalizedSupplierName,
      totalPurchased: totalPurchased,
      totalPaid: resolvedPaid,
      totalRemaining: resolvedRemaining,
      invoiceCount: entries.length,
    );
  }
}

String _supplierLedgerKey({
  required String propertyId,
  required String supplierName,
}) {
  return '${propertyId.trim()}::${_normalizeSupplierName(supplierName)}';
}

String _normalizeSupplierName(String supplierName) {
  final normalized = supplierName.trim();
  return normalized.isEmpty ? 'مورد غير محدد' : normalized;
}
