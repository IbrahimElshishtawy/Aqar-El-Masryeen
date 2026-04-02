import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';

class DashboardAssembler {
  const DashboardAssembler();

  DashboardSummary build({
    required List<PropertyProject> properties,
    required List<ExpenseRecord> expenses,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required List<ActivityLogEntry> recentActivity,
  }) {
    final totalExpenses = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final totalSalesValue = units.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final totalCollected = payments.fold<double>(0, (sum, item) => sum + item.amount);

    return DashboardSummary(
      totalProperties: properties.length,
      totalExpenses: totalExpenses,
      totalSalesValue: totalSalesValue,
      totalCollected: totalCollected,
      totalRemaining: totalSalesValue - totalCollected,
      overdueInstallmentsCount: installments.where((item) => item.isOverdue).length,
      recentActivityCount: recentActivity.length,
    );
  }
}
