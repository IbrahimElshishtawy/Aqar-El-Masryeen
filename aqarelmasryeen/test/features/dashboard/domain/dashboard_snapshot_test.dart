import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('expense totals do not include material or supplier payments', () async {
    await initializeDateFormatting('ar_EG');

    final now = DateTime.now();
    final snapshot = const DashboardSnapshotBuilder().build(
      properties: const [],
      units: const [],
      installments: const [],
      payments: const [],
      expenses: [_expense(amount: 100, date: now)],
      materials: [_material(totalPrice: 200, initialPaidAmount: 50, date: now)],
      supplierPayments: [_supplierPayment(amount: 25, paidAt: now)],
      partners: const [],
      recentActivity: const [],
      currentUserId: 'user-1',
      currentPartnerId: 'partner-1',
    );

    expect(snapshot.totalExpenses, 100);
    expect(snapshot.currentUserExpenses, 100);
    expect(snapshot.counterpartExpenses, 0);
    expect(
      snapshot.chart.fold<double>(0, (sum, bucket) => sum + bucket.expenses),
      100,
    );
    expect(snapshot.pendingSupplierDues, 125);
  });
}

ExpenseRecord _expense({required double amount, required DateTime date}) {
  return ExpenseRecord(
    id: 'expense-1',
    propertyId: 'property-1',
    amount: amount,
    category: ExpenseCategory.construction,
    description: 'Direct expense',
    paidByPartnerId: 'partner-1',
    paymentMethod: PaymentMethod.cash,
    date: date,
    attachmentUrl: null,
    notes: '',
    createdBy: 'user-1',
    updatedBy: 'user-1',
    createdAt: date,
    updatedAt: date,
    archived: false,
    workspaceId: 'workspace-1',
  );
}

MaterialExpenseEntry _material({
  required double totalPrice,
  required double initialPaidAmount,
  required DateTime date,
}) {
  return MaterialExpenseEntry(
    id: 'material-1',
    propertyId: 'property-1',
    date: date,
    materialCategory: MaterialCategory.cement,
    itemName: 'Cement',
    quantity: '1',
    unitPrice: totalPrice,
    totalPrice: totalPrice,
    supplierName: 'Supplier',
    initialPaidAmount: initialPaidAmount,
    initialPaidByPartnerId: 'partner-1',
    initialPaidByLabel: 'Partner',
    amountPaid: initialPaidAmount,
    amountRemaining: totalPrice - initialPaidAmount,
    notes: '',
    createdBy: 'user-1',
    updatedBy: 'user-1',
    createdAt: date,
    updatedAt: date,
    archived: false,
    workspaceId: 'workspace-1',
  );
}

SupplierPaymentRecord _supplierPayment({
  required double amount,
  required DateTime paidAt,
}) {
  return SupplierPaymentRecord(
    id: 'supplier-payment-1',
    propertyId: 'property-1',
    supplierName: 'Supplier',
    amount: amount,
    paidAt: paidAt,
    paidByPartnerId: 'partner-1',
    paidByLabel: 'Partner',
    notes: '',
    createdBy: 'user-1',
    updatedBy: 'user-1',
    createdAt: paidAt,
    updatedAt: paidAt,
    archived: false,
    workspaceId: 'workspace-1',
  );
}
