import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';

class InstallmentPlanGenerator {
  const InstallmentPlanGenerator();

  List<Installment> generate({
    required InstallmentPlan plan,
    required String actorId,
  }) {
    return List<Installment>.generate(plan.installmentCount, (index) {
      final dueDate = plan.startDate.add(
        Duration(days: plan.intervalDays * index),
      );
      return Installment(
        id: '',
        planId: plan.id,
        propertyId: plan.propertyId,
        unitId: plan.unitId,
        sequence: index + 1,
        amount: plan.installmentAmount,
        paidAmount: 0,
        dueDate: dueDate,
        status: dueDate.isBefore(DateTime.now())
            ? InstallmentStatus.overdue
            : InstallmentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: actorId,
        updatedBy: actorId,
      );
    });
  }
}
