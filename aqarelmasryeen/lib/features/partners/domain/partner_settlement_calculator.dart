import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';

class PartnerSettlementCalculator {
  const PartnerSettlementCalculator();

  List<PartnerSettlement> build({
    required List<Partner> partners,
    required List<ExpenseRecord> expenses,
  }) {
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return partners.map((partner) {
      final contributed = expenses
          .where((expense) => expense.paidByPartnerId == partner.id)
          .fold<double>(0, (sum, item) => sum + item.amount);
      final expected = totalExpenses * partner.shareRatio;
      return PartnerSettlement(
        partnerId: partner.id,
        partnerName: partner.name,
        contributedAmount: contributed,
        shareRatio: partner.shareRatio,
        expectedContribution: expected,
        balanceDelta: contributed - expected,
      );
    }).toList();
  }
}
