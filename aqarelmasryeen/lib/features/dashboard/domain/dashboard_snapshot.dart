import 'package:aqarelmasryeen/core/utils/ui_labels.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:intl/intl.dart';

enum DashboardRecordType { expense, payment, activity }

class DashboardChartBucket {
  const DashboardChartBucket({
    required this.label,
    required this.expenses,
    required this.payments,
  });

  final String label;
  final double expenses;
  final double payments;
}

class DashboardRecentRecord {
  const DashboardRecentRecord({
    required this.id,
    required this.propertyName,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.showAmount = true,
  });

  final String id;
  final String propertyName;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final DashboardRecordType type;
  final bool showAmount;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.propertyCount,
    required this.totalSalesValue,
    required this.totalExpenses,
    required this.currentUserExpenses,
    required this.counterpartExpenses,
    required this.totalPaidInstallments,
    required this.totalRemainingInstallments,
    required this.pendingSupplierDues,
    required this.partnerContributionTotal,
    required this.chart,
    required this.recentRecords,
  });

  final int propertyCount;
  final double totalSalesValue;
  final double totalExpenses;
  final double currentUserExpenses;
  final double counterpartExpenses;
  final double totalPaidInstallments;
  final double totalRemainingInstallments;
  final double pendingSupplierDues;
  final double partnerContributionTotal;
  final List<DashboardChartBucket> chart;
  final List<DashboardRecentRecord> recentRecords;
}

class DashboardSnapshotBuilder {
  const DashboardSnapshotBuilder();

  DashboardSnapshot build({
    required List<PropertyProject> properties,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required List<ExpenseRecord> expenses,
    required List<MaterialExpenseEntry> materials,
    required List<SupplierPaymentRecord> supplierPayments,
    required List<Partner> partners,
    required List<ActivityLogEntry> recentActivity,
    String? currentUserId,
    String? currentPartnerId,
  }) {
    final propertyNames = {
      for (final property in properties) property.id: property.name,
    };
    final materialsSnapshot = const MaterialsLedgerCalculator().build(
      materials,
      supplierPayments: supplierPayments,
    );
    final unitSummaries = const UnitSalesCalculator().build(
      units: units,
      installments: installments,
      payments: payments,
    );
    final trackedSummaries = unitSummaries
        .where((summary) => summary.unit.hasRecordedSale)
        .toList(growable: false);
    final totalSalesValue = trackedSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalContractAmount,
    );
    final totalDirectExpenses = expenses.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );
    final totalExpenses = totalDirectExpenses;
    final currentDirectExpenses = expenses
        .where(
          (record) => _belongsToCurrentSide(
            actorUserId: record.createdBy,
            payerPartnerId: record.paidByPartnerId,
            currentUserId: currentUserId,
            currentPartnerId: currentPartnerId,
          ),
        )
        .fold<double>(0, (sum, record) => sum + record.amount);
    final currentUserExpenses = currentDirectExpenses;
    final counterpartExpenses = (totalExpenses - currentUserExpenses) < 0
        ? 0.0
        : (totalExpenses - currentUserExpenses);
    final totalPaidInstallments = trackedSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalPaidSoFar,
    );
    final totalRemainingInstallments = trackedSummaries.fold<double>(
      0,
      (sum, summary) => sum + summary.totalRemaining,
    );
    final pendingSupplierDues = materialsSnapshot.overallRemaining;
    final partnerContributionTotal = partners.fold<double>(
      0,
      (sum, partner) => sum + partner.contributionTotal,
    );

    final financialRecentRecords = <DashboardRecentRecord>[
      ...expenses.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName:
              propertyNames[record.propertyId] ??
              '\u0645\u0634\u0631\u0648\u0639 \u063a\u064a\u0631 \u0645\u0639\u0631\u0648\u0641',
          title: record.description.isEmpty
              ? record.category.label
              : record.description,
          subtitle: record.paymentMethod.label,
          amount: record.amount,
          date: record.date,
          type: DashboardRecordType.expense,
        ),
      ),
      ...materials.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName:
              propertyNames[record.propertyId] ??
              '\u0645\u0634\u0631\u0648\u0639 \u063a\u064a\u0631 \u0645\u0639\u0631\u0648\u0641',
          title: record.itemName,
          subtitle: record.supplierName,
          amount: record.totalPrice,
          date: record.date,
          type: DashboardRecordType.expense,
        ),
      ),
      ...supplierPayments.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName:
              propertyNames[record.propertyId] ??
              '\u0645\u0634\u0631\u0648\u0639 \u063a\u064a\u0631 \u0645\u0639\u0631\u0648\u0641',
          title: 'دفعة مورد',
          subtitle: record.supplierName,
          amount: record.amount,
          date: record.paidAt,
          type: DashboardRecordType.expense,
        ),
      ),
      ...payments.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName:
              propertyNames[record.propertyId] ??
              '\u0645\u0634\u0631\u0648\u0639 \u063a\u064a\u0631 \u0645\u0639\u0631\u0648\u0641',
          title: record.effectivePayerName.isEmpty
              ? '\u062f\u0641\u0639\u0629 \u0645\u062d\u0635\u0644\u0629'
              : record.effectivePayerName,
          subtitle: record.paymentSource.isEmpty
              ? record.paymentMethod.label
              : record.paymentSource,
          amount: record.amount,
          date: record.receivedAt,
          type: DashboardRecordType.payment,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final activityRecentRecords =
        recentActivity.map(_activityToRecentRecord).toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
    final recentRecords = activityRecentRecords.isNotEmpty
        ? activityRecentRecords
        : financialRecentRecords;

    return DashboardSnapshot(
      propertyCount: properties.length,
      totalSalesValue: totalSalesValue,
      totalExpenses: totalExpenses,
      currentUserExpenses: currentUserExpenses,
      counterpartExpenses: counterpartExpenses,
      totalPaidInstallments: totalPaidInstallments,
      totalRemainingInstallments: totalRemainingInstallments,
      pendingSupplierDues: pendingSupplierDues,
      partnerContributionTotal: partnerContributionTotal,
      chart: _buildChart(expenses: expenses, payments: payments),
      recentRecords: recentRecords.take(6).toList(),
    );
  }

  List<DashboardChartBucket> _buildChart({
    required List<ExpenseRecord> expenses,
    required List<PaymentRecord> payments,
  }) {
    final now = DateTime.now();
    final formatter = DateFormat('MMM', 'ar_EG');
    final buckets = <DashboardChartBucket>[];

    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(month.year, month.month + 1);
      final directExpenseValue = expenses
          .where(
            (item) =>
                !item.date.isBefore(month) && item.date.isBefore(nextMonth),
          )
          .fold<double>(0, (sum, item) => sum + item.amount);
      final paymentValue = payments
          .where(
            (item) =>
                !item.receivedAt.isBefore(month) &&
                item.receivedAt.isBefore(nextMonth),
          )
          .fold<double>(0, (sum, item) => sum + item.amount);

      buckets.add(
        DashboardChartBucket(
          label: formatter.format(month),
          expenses: directExpenseValue,
          payments: paymentValue,
        ),
      );
    }

    return buckets;
  }
}

DashboardRecentRecord _activityToRecentRecord(ActivityLogEntry entry) {
  final metadata = entry.metadata;
  final amount = _metadataNumber(metadata, 'amount');
  final entityLabel = entityTypeLabel(entry.entityType);
  final actorName = entry.actorName.trim().isEmpty ? 'شريك' : entry.actorName;
  final subtitleParts = [
    entityLabel,
    _metadataString(metadata, 'supplierName'),
    _metadataString(metadata, 'unitId'),
  ].where((item) => item.trim().isNotEmpty).toList(growable: false);

  return DashboardRecentRecord(
    id: entry.id,
    propertyName: actorName,
    title: activityActionLabel(entry.action),
    subtitle: subtitleParts.isEmpty ? entityLabel : subtitleParts.join(' - '),
    amount: amount,
    date: entry.createdAt,
    type: _activityRecordType(entry.action),
    showAmount: amount > 0,
  );
}

DashboardRecordType _activityRecordType(String action) {
  if (action.contains('payment')) {
    return DashboardRecordType.payment;
  }
  if (action.contains('expense') || action.contains('supplier')) {
    return DashboardRecordType.expense;
  }
  return DashboardRecordType.activity;
}

double _metadataNumber(Map<String, dynamic> metadata, String key) {
  final value = metadata[key];
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _metadataString(Map<String, dynamic> metadata, String key) {
  return (metadata[key] as String? ?? '').trim();
}

bool _belongsToCurrentSide({
  required String actorUserId,
  required String payerPartnerId,
  required String? currentUserId,
  required String? currentPartnerId,
}) {
  final normalizedCurrentPartnerId = currentPartnerId?.trim() ?? '';
  if (normalizedCurrentPartnerId.isNotEmpty &&
      payerPartnerId.trim() == normalizedCurrentPartnerId) {
    return true;
  }

  final normalizedCurrentUserId = currentUserId?.trim() ?? '';
  return normalizedCurrentUserId.isNotEmpty &&
      actorUserId.trim() == normalizedCurrentUserId;
}
