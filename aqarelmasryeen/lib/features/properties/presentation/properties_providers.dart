import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/domain/property_financial_summary.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

final propertiesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final propertyExpensesStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final propertyPaymentsStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);
final propertyUnitsStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(salesRepositoryProvider).watchAll(),
);

final propertiesViewDataProvider =
    Provider.autoDispose<AsyncValue<PropertiesViewData>>((ref) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertiesStreamProvider),
        ref.watch(propertyExpensesStreamProvider),
        ref.watch(propertyPaymentsStreamProvider),
        ref.watch(propertyUnitsStreamProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final summaries = const PropertyFinancialSummaryBuilder().build(
        properties: ref.watch(propertiesStreamProvider).valueOrNull ?? const [],
        expenses:
            ref.watch(propertyExpensesStreamProvider).valueOrNull ?? const [],
        payments:
            ref.watch(propertyPaymentsStreamProvider).valueOrNull ?? const [],
        units: ref.watch(propertyUnitsStreamProvider).valueOrNull ?? const [],
      );
      final totalExpenses = summaries.fold<double>(
        0,
        (sum, summary) => sum + summary.totalExpenses,
      );
      final totalPayments = summaries.fold<double>(
        0,
        (sum, summary) => sum + summary.totalPayments,
      );

      return AsyncData(
        PropertiesViewData(
          summaries: summaries,
          totalExpenses: totalExpenses,
          totalPayments: totalPayments,
        ),
      );
    });

class PropertiesViewData {
  const PropertiesViewData({
    required this.summaries,
    required this.totalExpenses,
    required this.totalPayments,
  });

  final List<PropertyFinancialSummary> summaries;
  final double totalExpenses;
  final double totalPayments;
}
