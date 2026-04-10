import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar_EG');
  });

  test('dashboard snapshot uses actual payments and all expense sources', () {
    final now = DateTime.now();
    final snapshot = const DashboardSnapshotBuilder().build(
      properties: [
        PropertyProject(
          id: 'property-1',
          name: 'Project A',
          location: 'Cairo',
          apartmentCount: 10,
          description: '',
          status: PropertyStatus.active,
          totalBudget: 0,
          totalSalesTarget: 0,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
          updatedBy: 'user-1',
          archived: false,
        ),
      ],
      units: [
        UnitSale(
          id: 'unit-1',
          propertyId: 'property-1',
          unitNumber: '101',
          floor: 1,
          unitType: UnitType.apartment,
          area: 120,
          customerName: 'Ahmed',
          customerPhone: '0100',
          apartmentPrice: 1000000,
          downPayment: 100000,
          remainingAmount: 900000,
          installmentScheduleCount: 2,
          paymentPlanType: PaymentPlanType.installment,
          status: UnitStatus.sold,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
          updatedBy: 'user-1',
        ),
      ],
      installments: [
        Installment(
          id: 'inst-1',
          planId: 'plan-1',
          propertyId: 'property-1',
          unitId: 'unit-1',
          sequence: 1,
          amount: 300000,
          paidAmount: 0,
          dueDate: now.add(const Duration(days: 30)),
          status: InstallmentStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
          updatedBy: 'user-1',
        ),
        Installment(
          id: 'inst-2',
          planId: 'plan-1',
          propertyId: 'property-1',
          unitId: 'unit-1',
          sequence: 2,
          amount: 600000,
          paidAmount: 0,
          dueDate: now.add(const Duration(days: 60)),
          status: InstallmentStatus.pending,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
          updatedBy: 'user-1',
        ),
      ],
      payments: [
        PaymentRecord(
          id: 'payment-1',
          propertyId: 'property-1',
          unitId: 'unit-1',
          payerName: 'Ahmed',
          customerName: 'Ahmed',
          installmentId: 'inst-1',
          amount: 50000,
          receivedAt: now,
          paymentMethod: PaymentMethod.cash,
          paymentSource: 'Installment',
          notes: '',
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
          updatedBy: 'user-1',
        ),
        PaymentRecord(
          id: 'payment-2',
          propertyId: 'property-1',
          unitId: 'unit-1',
          payerName: 'Ahmed',
          customerName: 'Ahmed',
          installmentId: null,
          amount: 25000,
          receivedAt: now,
          paymentMethod: PaymentMethod.bankTransfer,
          paymentSource: 'Special payment',
          notes: '',
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
          updatedBy: 'user-1',
        ),
      ],
      expenses: [
        ExpenseRecord(
          id: 'expense-1',
          propertyId: 'property-1',
          amount: 12000,
          category: ExpenseCategory.other,
          description: 'Site expense',
          paidByPartnerId: '',
          paymentMethod: PaymentMethod.cash,
          date: now,
          attachmentUrl: null,
          notes: '',
          createdBy: 'user-1',
          updatedBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      ],
      materials: [
        MaterialExpenseEntry(
          id: 'material-1',
          propertyId: 'property-1',
          date: now,
          materialCategory: MaterialCategory.cement,
          itemName: 'Cement',
          quantity: 10,
          unitPrice: 1000,
          totalPrice: 10000,
          supplierName: 'Supplier',
          initialPaidAmount: 4000,
          initialPaidByPartnerId: 'partner-1',
          initialPaidByLabel: 'Partner',
          amountPaid: 4000,
          amountRemaining: 6000,
          notes: '',
          createdBy: 'user-1',
          updatedBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      ],
      supplierPayments: [
        SupplierPaymentRecord(
          id: 'supplier-payment-1',
          propertyId: 'property-1',
          supplierName: 'Supplier',
          amount: 3000,
          paidAt: now,
          paidByPartnerId: 'partner-1',
          paidByLabel: 'Partner',
          notes: '',
          createdBy: 'user-1',
          updatedBy: 'user-1',
          createdAt: now,
          updatedAt: now,
          archived: false,
        ),
      ],
      partners: const <Partner>[],
    );

    expect(snapshot.totalSalesValue, 1000000);
    expect(snapshot.totalExpenses, 19000);
    expect(snapshot.totalPaidInstallments, 175000);
    expect(snapshot.totalRemainingInstallments, 825000);
    expect(snapshot.chart.last.expenses, 19000);
    expect(snapshot.chart.last.payments, 75000);
  });
}
