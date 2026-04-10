import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';

class PartnerLedgerSummaryRow {
  const PartnerLedgerSummaryRow({
    required this.partner,
    required this.totalPaid,
    required this.totalOwed,
    required this.balance,
    required this.lastUpdated,
    required this.notes,
  });

  final Partner partner;
  final double totalPaid;
  final double totalOwed;
  final double balance;
  final DateTime lastUpdated;
  final String notes;
}

class PartnerLedgerCalculator {
  const PartnerLedgerCalculator();

  List<PartnerLedgerSummaryRow> build({
    required List<Partner> partners,
    required List<ExpenseRecord> expenses,
    required List<MaterialExpenseEntry> materialExpenses,
    required List<SupplierPaymentRecord> supplierPayments,
    required List<PartnerLedgerEntry> ledgerEntries,
  }) {
    final totalExpenseExposure =
        expenses.fold<double>(0, (sum, item) => sum + item.amount) +
        materialExpenses.fold<double>(0, (sum, item) => sum + item.totalPrice);

    return partners.map((partner) {
      final partnerEntries =
          ledgerEntries
              .where(
                (entry) => !entry.archived && entry.partnerId == partner.id,
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final authorizedPaid = partnerEntries
          .where(
            (entry) =>
                entry.entryType == PartnerLedgerEntryType.contribution ||
                entry.entryType == PartnerLedgerEntryType.settlement ||
                entry.entryType == PartnerLedgerEntryType.adjustment,
          )
          .fold<double>(0, (sum, entry) => sum + entry.amount);
      final directExpensePaid = expenses
          .where((expense) => expense.paidByPartnerId == partner.id)
          .fold<double>(0, (sum, expense) => sum + expense.amount);
      final initialMaterialPaid = materialExpenses
          .where((expense) => expense.initialPaidByPartnerId == partner.id)
          .fold<double>(0, (sum, expense) => sum + expense.initialPaidAmount);
      final supplierPaymentsPaid = supplierPayments
          .where((payment) => payment.paidByPartnerId == partner.id)
          .fold<double>(0, (sum, payment) => sum + payment.amount);
      final totalPaid =
          authorizedPaid +
          directExpensePaid +
          initialMaterialPaid +
          supplierPaymentsPaid;
      final safeShareRatio =
          partner.shareRatio.isFinite && partner.shareRatio > 0
          ? partner.shareRatio
          : 0.0;
      final expectedShare = totalExpenseExposure * safeShareRatio;
      final rawOutstanding = expectedShare - totalPaid;
      final totalOwed = rawOutstanding <= 0
          ? 0.0
          : rawOutstanding >= expectedShare
          ? expectedShare
          : rawOutstanding;
      final balance = totalPaid - expectedShare;
      final lastUpdated =
          partnerEntries.firstOrNull?.updatedAt ?? partner.updatedAt;
      final notes = partnerEntries.firstOrNull?.notes ?? '';

      return PartnerLedgerSummaryRow(
        partner: partner,
        totalPaid: totalPaid,
        totalOwed: totalOwed,
        balance: balance,
        lastUpdated: lastUpdated,
        notes: notes,
      );
    }).toList()..sort((a, b) => b.totalOwed.compareTo(a.totalOwed));
  }
}
