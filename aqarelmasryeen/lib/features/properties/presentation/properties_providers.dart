import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/domain/property_financial_summary.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

final propertiesStreamProvider =
    StreamProvider.autoDispose<List<PropertyProject>>((ref) {
      final session = ref.watch(authSessionProvider).valueOrNull;
      final workspaceId = ref.watch(currentWorkspaceIdProvider);
      final allPartners =
          ref.watch(partnersStreamProvider).valueOrNull ?? const [];
      final accountUserIds = {
        session?.userId ?? '',
        ...allPartners
            .map((partner) => partner.userId.trim())
            .where((userId) => userId.isNotEmpty),
      }..removeWhere((userId) => userId.trim().isEmpty);
      return ref
          .watch(propertyRepositoryProvider)
          .watchProperties(
            workspaceId: workspaceId,
            accountUserIds: accountUserIds,
          );
    });
final propertyExpensesStreamProvider =
    StreamProvider.autoDispose<List<ExpenseRecord>>((ref) {
      return ref
          .watch(expenseRepositoryProvider)
          .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
    });
final propertyPaymentsStreamProvider =
    StreamProvider.autoDispose<List<PaymentRecord>>((ref) {
      return ref
          .watch(paymentRepositoryProvider)
          .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
    });
final propertyUnitsStreamProvider = StreamProvider.autoDispose<List<UnitSale>>((
  ref,
) {
  return ref
      .watch(salesRepositoryProvider)
      .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
});
final partnersStreamProvider = StreamProvider.autoDispose<List<Partner>>((ref) {
  return ref
      .watch(partnerRepositoryProvider)
      .watchPartners(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final propertiesViewDataProvider =
    Provider.autoDispose<AsyncValue<PropertiesViewData>>((ref) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertiesStreamProvider),
        ref.watch(propertyExpensesStreamProvider),
        ref.watch(propertyPaymentsStreamProvider),
        ref.watch(propertyUnitsStreamProvider),
        ref.watch(partnersStreamProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final session = ref.watch(authSessionProvider).valueOrNull;
      final workspaceId = ref.watch(currentWorkspaceIdProvider);
      final allPartners =
          ref.watch(partnersStreamProvider).valueOrNull ?? const [];
      final scopedPartners = workspaceId.isEmpty
          ? allPartners
                .where((partner) => partner.createdBy.trim() == session?.userId)
                .toList(growable: false)
          : allPartners
                .where((partner) => partner.workspaceId.trim() == workspaceId)
                .toList(growable: false);
      final accountUserIds = {
        session?.userId ?? '',
        ...scopedPartners
            .map((partner) => partner.userId.trim())
            .where((userId) => userId.isNotEmpty),
      }..removeWhere((userId) => userId.trim().isEmpty);

      final scopedProperties =
          (ref.watch(propertiesStreamProvider).valueOrNull ??
                  const <PropertyProject>[])
              .where((property) {
                if (workspaceId.isNotEmpty &&
                    property.workspaceId.trim() == workspaceId) {
                  return true;
                }
                return accountUserIds.contains(property.createdBy.trim());
              })
              .toList(growable: false);
      final propertyIds = scopedProperties
          .map((property) => property.id)
          .toSet();
      final scopedUnits =
          (ref.watch(propertyUnitsStreamProvider).valueOrNull ??
                  const <UnitSale>[])
              .where((unit) => propertyIds.contains(unit.propertyId))
              .toList(growable: false);
      final summaries = const PropertyFinancialSummaryBuilder().build(
        properties: scopedProperties,
        expenses:
            (ref.watch(propertyExpensesStreamProvider).valueOrNull ??
                    const <ExpenseRecord>[])
                .where((expense) => propertyIds.contains(expense.propertyId))
                .toList(growable: false),
        payments:
            (ref.watch(propertyPaymentsStreamProvider).valueOrNull ??
                    const <PaymentRecord>[])
                .where((payment) => propertyIds.contains(payment.propertyId))
                .toList(growable: false),
        units: scopedUnits,
      );
      final totalExpenses = summaries.fold<double>(
        0,
        (total, summary) => total + summary.totalExpenses,
      );
      final totalPayments = summaries.fold<double>(
        0,
        (total, summary) => total + summary.totalPayments,
      );

      return AsyncData(
        PropertiesViewData(
          isWorkspaceLinked: workspaceId.isNotEmpty,
          summaries: summaries,
          totalExpenses: totalExpenses,
          totalPayments: totalPayments,
        ),
      );
    });

class PropertiesViewData {
  const PropertiesViewData({
    required this.isWorkspaceLinked,
    required this.summaries,
    required this.totalExpenses,
    required this.totalPayments,
  });

  final bool isWorkspaceLinked;
  final List<PropertyFinancialSummary> summaries;
  final double totalExpenses;
  final double totalPayments;
}
