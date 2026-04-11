// ignore_for_file: unused_local_variable

import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';

class DashboardScopedData {
  const DashboardScopedData({
    required this.partners,
    required this.properties,
    required this.units,
    required this.installments,
    required this.payments,
    required this.expenses,
    required this.materials,
    required this.supplierPayments,
  });

  final List<Partner> partners;
  final List<PropertyProject> properties;
  final List<UnitSale> units;
  final List<Installment> installments;
  final List<PaymentRecord> payments;
  final List<ExpenseRecord> expenses;
  final List<MaterialExpenseEntry> materials;
  final List<SupplierPaymentRecord> supplierPayments;
}

class DashboardScopeResolver {
  const DashboardScopeResolver();

  DashboardScopedData resolve({
    required AppUser? profile,
    required String currentUserId,
    required String workspaceId,
    required List<Partner> partners,
    required List<PropertyProject> properties,
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
    required List<ExpenseRecord> expenses,
    required List<MaterialExpenseEntry> materials,
    required List<SupplierPaymentRecord> supplierPayments,
  }) {
    final visiblePartners = partners
        .where((partner) {
          if (workspaceId.isEmpty) {
            return partner.createdBy.trim() == currentUserId.trim() ||
                partner.userId.trim() == currentUserId.trim();
          }
          final partnerWorkspace = partner.workspaceId.trim();
          return workspaceId == partnerWorkspace;
        })
        .toList(growable: false);

    final linkedPartnerIds = visiblePartners
        .map((partner) => partner.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final accountUserIds = {
      currentUserId.trim(),
      ...visiblePartners
          .map((partner) => partner.userId.trim())
          .where((id) => id.isNotEmpty),
    }..removeWhere((id) => id.isEmpty);

    final visibleProperties = properties
        .where((property) {
          if (workspaceId.isNotEmpty &&
              property.workspaceId.trim() == workspaceId) {
            return true;
          }
          return accountUserIds.contains(property.createdBy.trim());
        })
        .toList(growable: false);
    final propertyIds = visibleProperties
        .map((property) => property.id)
        .toSet();

    final visibleUnits = units
        .where((unit) => propertyIds.contains(unit.propertyId))
        .toList(growable: false);
    final unitIds = visibleUnits.map((unit) => unit.id).toSet();

    final visibleInstallments = installments
        .where(
          (installment) =>
              unitIds.contains(installment.unitId) ||
              propertyIds.contains(installment.propertyId),
        )
        .toList(growable: false);
    final installmentIds = visibleInstallments
        .map((installment) => installment.id)
        .toSet();

    final visiblePayments = payments
        .where(
          (payment) =>
              propertyIds.contains(payment.propertyId) ||
              unitIds.contains(payment.unitId) ||
              installmentIds.contains(payment.installmentId?.trim()),
        )
        .toList(growable: false);

    final visibleExpenses = expenses
        .where((expense) => propertyIds.contains(expense.propertyId))
        .toList(growable: false);

    final visibleMaterials = materials
        .where((item) => propertyIds.contains(item.propertyId))
        .toList(growable: false);

    final visibleSupplierPayments = supplierPayments
        .where((payment) => propertyIds.contains(payment.propertyId))
        .toList(growable: false);

    return DashboardScopedData(
      partners: visiblePartners,
      properties: visibleProperties,
      units: visibleUnits,
      installments: visibleInstallments,
      payments: visiblePayments,
      expenses: visibleExpenses,
      materials: visibleMaterials,
      supplierPayments: visibleSupplierPayments,
    );
  }
}
