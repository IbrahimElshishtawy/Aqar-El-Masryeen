import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';

class PropertyFinancialSummary {
  const PropertyFinancialSummary({
    required this.property,
    required this.totalExpenses,
    required this.totalPayments,
  });

  final PropertyProject property;
  final double totalExpenses;
  final double totalPayments;

  double get balance => totalPayments - totalExpenses;
  double get totalMovement => totalExpenses + totalPayments;
}

class PropertyFinancialSummaryBuilder {
  const PropertyFinancialSummaryBuilder();

  List<PropertyFinancialSummary> build({
    required List<PropertyProject> properties,
    required List<ExpenseRecord> expenses,
    required List<PaymentRecord> payments,
  }) {
    return properties.map((property) {
        final propertyExpenses = expenses
            .where((record) => record.propertyId == property.id)
            .fold<double>(0, (sum, record) => sum + record.amount);
        final propertyPayments = payments
            .where((record) => record.propertyId == property.id)
            .fold<double>(0, (sum, record) => sum + record.amount);

        return PropertyFinancialSummary(
          property: property,
          totalExpenses: propertyExpenses,
          totalPayments: propertyPayments,
        );
      }).toList()
      ..sort((a, b) => b.property.updatedAt.compareTo(a.property.updatedAt));
  }
}
