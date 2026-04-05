import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:intl/intl.dart';

enum DashboardRecordType { expense, payment }

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
  });

  final String id;
  final String propertyName;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final DashboardRecordType type;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.propertyCount,
    required this.totalSalesValue,
    required this.totalExpenses,
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
    required List<PaymentRecord> payments,
    required List<MaterialExpenseEntry> materials,
    required List<Partner> partners,
  }) {
    final propertyNames = {
      for (final property in properties) property.id: property.name,
    };
    final totalSalesValue = units.fold<double>(
      0,
      (sum, record) => sum + record.contractAmount,
    );
    final totalExpenses = materials.fold<double>(
      0,
      (sum, record) => sum + record.totalPrice,
    );
    final totalPaidInstallments = payments.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );
    final totalRemainingInstallments = units.fold<double>(
      0,
      (sum, record) => sum + record.remainingAmount,
    );
    final pendingSupplierDues = materials.fold<double>(
      0,
      (sum, record) => sum + record.amountRemaining,
    );
    final partnerContributionTotal = partners.fold<double>(
      0,
      (sum, partner) => sum + partner.contributionTotal,
    );

    final recentRecords = <DashboardRecentRecord>[
      ...materials.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName: propertyNames[record.propertyId] ?? 'Unknown property',
          title: record.itemName,
          subtitle: record.supplierName,
          amount: record.totalPrice,
          date: record.date,
          type: DashboardRecordType.expense,
        ),
      ),
      ...payments.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName: propertyNames[record.propertyId] ?? 'Unknown property',
          title: record.effectivePayerName.isEmpty
              ? 'Payment received'
              : record.effectivePayerName,
          subtitle: record.paymentSource.isEmpty ? record.paymentMethod.label : record.paymentSource,
          amount: record.amount,
          date: record.receivedAt,
          type: DashboardRecordType.payment,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSnapshot(
      propertyCount: properties.length,
      totalSalesValue: totalSalesValue,
      totalExpenses: totalExpenses,
      totalPaidInstallments: totalPaidInstallments,
      totalRemainingInstallments: totalRemainingInstallments,
      pendingSupplierDues: pendingSupplierDues,
      partnerContributionTotal: partnerContributionTotal,
      chart: _buildChart(materials: materials, payments: payments),
      recentRecords: recentRecords.take(6).toList(),
    );
  }

  List<DashboardChartBucket> _buildChart({
    required List<MaterialExpenseEntry> materials,
    required List<PaymentRecord> payments,
  }) {
    final now = DateTime.now();
    final formatter = DateFormat('MMM');
    final buckets = <DashboardChartBucket>[];

    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(month.year, month.month + 1);
      final expenseValue = materials
          .where((item) => !item.date.isBefore(month) && item.date.isBefore(nextMonth))
          .fold<double>(0, (sum, item) => sum + item.totalPrice);
      final paymentValue = payments
          .where((item) => !item.receivedAt.isBefore(month) && item.receivedAt.isBefore(nextMonth))
          .fold<double>(0, (sum, item) => sum + item.amount);

      buckets.add(
        DashboardChartBucket(
          label: formatter.format(month),
          expenses: expenseValue,
          payments: paymentValue,
        ),
      );
    }

    return buckets;
  }
}
