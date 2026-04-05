import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/features/notifications/data/notification_repository.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinancialNotificationCoordinator {
  const FinancialNotificationCoordinator(this._notifications);

  final NotificationRepository _notifications;

  Future<void> syncPropertyAlerts({
    required String userId,
    required String propertyId,
    required List<UnitSaleComputedSummary> unitSummaries,
    required List<MaterialExpenseEntry> materials,
  }) async {
    for (final summary in unitSummaries) {
      for (final row in summary.installmentRows) {
        final daysUntilDue = row.installment.dueDate.difference(DateTime.now()).inDays;
        if (row.status == InstallmentStatus.pending && daysUntilDue >= 0 && daysUntilDue <= 7) {
          await _notifications.create(
            userId: userId,
            title: 'Installment due soon',
            body: 'Unit ${summary.unit.unitNumber} installment ${row.installment.sequence} is due on ${row.installment.dueDate.toString().split(' ').first}.',
            type: NotificationType.installmentDue,
            route: AppRoutes.propertyDetails(propertyId),
            referenceKey: 'due-soon-${row.installment.id}',
          );
        }
        if (row.status == InstallmentStatus.overdue) {
          await _notifications.create(
            userId: userId,
            title: 'Installment overdue',
            body: 'Unit ${summary.unit.unitNumber} installment ${row.installment.sequence} is overdue.',
            type: NotificationType.overdueInstallment,
            route: AppRoutes.propertyDetails(propertyId),
            referenceKey: 'overdue-${row.installment.id}',
          );
        }
      }

      if (summary.isFullyPaid) {
        await _notifications.create(
          userId: userId,
          title: 'Installment plan completed',
          body: 'Unit ${summary.unit.unitNumber} is now fully paid.',
          type: NotificationType.installmentCompleted,
          route: AppRoutes.propertyDetails(propertyId),
          referenceKey: 'completed-${summary.unit.id}',
        );
      }
    }

    for (final material in materials) {
      if (material.amountRemaining > 0 && material.dueDate != null) {
        final isDue = !material.dueDate!.isAfter(DateTime.now().add(const Duration(days: 7)));
        if (isDue) {
          await _notifications.create(
            userId: userId,
            title: 'Supplier payment due',
            body: '${material.supplierName} still has ${material.amountRemaining.toStringAsFixed(0)} due.',
            type: NotificationType.supplierPaymentDue,
            route: AppRoutes.expenses,
            referenceKey: 'supplier-due-${material.id}',
          );
        }
      }
    }
  }
}

final financialNotificationCoordinatorProvider = Provider<FinancialNotificationCoordinator>(
  (ref) => FinancialNotificationCoordinator(ref.watch(notificationRepositoryProvider)),
);
