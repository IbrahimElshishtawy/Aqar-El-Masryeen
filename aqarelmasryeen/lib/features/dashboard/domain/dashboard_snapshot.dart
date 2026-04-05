import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
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
    required this.totalExpenses,
    required this.totalPayments,
    required this.netBalance,
    required this.chart,
    required this.recentRecords,
  });

  final int propertyCount;
  final double totalExpenses;
  final double totalPayments;
  final double netBalance;
  final List<DashboardChartBucket> chart;
  final List<DashboardRecentRecord> recentRecords;
}

class DashboardSnapshotBuilder {
  const DashboardSnapshotBuilder();

  DashboardSnapshot build({
    required List<PropertyProject> properties,
    required List<ExpenseRecord> expenses,
    required List<PaymentRecord> payments,
  }) {
    final propertyNames = {
      for (final property in properties) property.id: property.name,
    };
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );
    final totalPayments = payments.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );

    final recentRecords = <DashboardRecentRecord>[
      ...expenses.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName: propertyNames[record.propertyId] ?? 'Unknown property',
          title: record.description,
          subtitle: record.category.label,
          amount: record.amount,
          date: record.date,
          type: DashboardRecordType.expense,
        ),
      ),
      ...payments.map(
        (record) => DashboardRecentRecord(
          id: record.id,
          propertyName: propertyNames[record.propertyId] ?? 'Unknown property',
          title: record.customerName.trim().isNotEmpty
              ? record.customerName
              : record.unitId.trim().isNotEmpty
              ? record.unitId
              : 'Direct payment',
          subtitle: record.paymentMethod.label,
          amount: record.amount,
          date: record.receivedAt,
          type: DashboardRecordType.payment,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSnapshot(
      propertyCount: properties.length,
      totalExpenses: totalExpenses,
      totalPayments: totalPayments,
      netBalance: totalPayments - totalExpenses,
      chart: _buildChart(expenses: expenses, payments: payments),
      recentRecords: recentRecords.take(6).toList(),
    );
  }

  List<DashboardChartBucket> _buildChart({
    required List<ExpenseRecord> expenses,
    required List<PaymentRecord> payments,
  }) {
    final now = DateTime.now();
    final formatter = DateFormat('MMM');
    final buckets = <DashboardChartBucket>[];

    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(month.year, month.month + 1);
      final expenseValue = expenses
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
          expenses: expenseValue,
          payments: paymentValue,
        ),
      );
    }

    return buckets;
  }
}
