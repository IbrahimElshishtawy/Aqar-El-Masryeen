import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_composer.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_view_data.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_composer.dart';
export 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_view_data.dart';

final propertyDetailsProvider = StreamProvider.autoDispose
    .family<PropertyProject?, String>(
      (ref, propertyId) =>
          ref.watch(propertyRepositoryProvider).watchProperty(propertyId),
    );

final propertyUnitsProvider = StreamProvider.autoDispose
    .family<List<UnitSale>, String>(
      (ref, propertyId) =>
          ref.watch(salesRepositoryProvider).watchByProperty(propertyId),
    );

final propertyInstallmentsProvider = StreamProvider.autoDispose
    .family<List<Installment>, String>(
      (ref, propertyId) => ref
          .watch(installmentRepositoryProvider)
          .watchInstallmentsByProperty(propertyId),
    );

final propertyPaymentsProvider = StreamProvider.autoDispose
    .family<List<PaymentRecord>, String>(
      (ref, propertyId) =>
          ref.watch(paymentRepositoryProvider).watchByProperty(propertyId),
    );

final propertyExpensesProvider = StreamProvider.autoDispose
    .family<List<ExpenseRecord>, String>(
      (ref, propertyId) =>
          ref.watch(expenseRepositoryProvider).watchByProperty(propertyId),
    );

final propertyMaterialsProvider = StreamProvider.autoDispose
    .family<List<MaterialExpenseEntry>, String>(
      (ref, propertyId) => ref
          .watch(materialExpenseRepositoryProvider)
          .watchByProperty(propertyId),
    );

final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final propertyPartnerLedgerProvider =
    StreamProvider.autoDispose<List<PartnerLedgerEntry>>(
      (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
    );

final propertyProjectViewDataProvider = Provider.autoDispose
    .family<AsyncValue<PropertyProjectViewData?>, String>((ref, propertyId) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertyDetailsProvider(propertyId)),
        ref.watch(propertyUnitsProvider(propertyId)),
        ref.watch(propertyInstallmentsProvider(propertyId)),
        ref.watch(propertyPaymentsProvider(propertyId)),
        ref.watch(propertyExpensesProvider(propertyId)),
        ref.watch(propertyMaterialsProvider(propertyId)),
        ref.watch(propertyPartnersProvider),
        ref.watch(propertyPartnerLedgerProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final property = ref
          .watch(propertyDetailsProvider(propertyId))
          .valueOrNull;
      if (property == null) {
        return const AsyncData(null);
      }

      final session = ref.watch(authSessionProvider).valueOrNull;
      final composer = const PropertyDetailComposer();

      return AsyncData(
        composer.buildProjectViewData(
          property: property,
          currentUserId: session?.userId,
          units:
              ref.watch(propertyUnitsProvider(propertyId)).valueOrNull ??
              const [],
          installments:
              ref.watch(propertyInstallmentsProvider(propertyId)).valueOrNull ??
              const [],
          payments:
              ref.watch(propertyPaymentsProvider(propertyId)).valueOrNull ??
              const [],
          expenses:
              ref.watch(propertyExpensesProvider(propertyId)).valueOrNull ??
              const [],
          materials:
              ref.watch(propertyMaterialsProvider(propertyId)).valueOrNull ??
              const [],
          partners: ref.watch(propertyPartnersProvider).valueOrNull ?? const [],
          partnerLedgers:
              ref.watch(propertyPartnerLedgerProvider).valueOrNull ?? const [],
        ),
      );
    });

final propertyUnitViewDataProvider = Provider.autoDispose
    .family<AsyncValue<PropertyUnitViewData?>, PropertyUnitRequest>((
      ref,
      request,
    ) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertyDetailsProvider(request.propertyId)),
        ref.watch(propertyUnitsProvider(request.propertyId)),
        ref.watch(propertyInstallmentsProvider(request.propertyId)),
        ref.watch(propertyPaymentsProvider(request.propertyId)),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final property = ref
          .watch(propertyDetailsProvider(request.propertyId))
          .valueOrNull;
      if (property == null) {
        return const AsyncData(null);
      }

      final composer = const PropertyDetailComposer();
      return AsyncData(
        composer.buildUnitViewData(
          property: property,
          unitId: request.unitId,
          units:
              ref
                  .watch(propertyUnitsProvider(request.propertyId))
                  .valueOrNull ??
              const [],
          installments:
              ref
                  .watch(propertyInstallmentsProvider(request.propertyId))
                  .valueOrNull ??
              const [],
          payments:
              ref
                  .watch(propertyPaymentsProvider(request.propertyId))
                  .valueOrNull ??
              const [],
        ),
      );
    });

class PropertyUnitRequest {
  const PropertyUnitRequest({required this.propertyId, required this.unitId});

  final String propertyId;
  final String unitId;

  @override
  bool operator ==(Object other) {
    return other is PropertyUnitRequest &&
        other.propertyId == propertyId &&
        other.unitId == unitId;
  }

  @override
  int get hashCode => Object.hash(propertyId, unitId);
}
