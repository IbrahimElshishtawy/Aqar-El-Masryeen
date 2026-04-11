import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/supplier_payment_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/unit_expense_repository.dart';
import 'package:aqarelmasryeen/features/installments/data/installment_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_composer.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_view_data.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_composer.dart';
export 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_view_data.dart';

final _allPropertiesProvider =
    StreamProvider.autoDispose<List<PropertyProject>>((ref) {
      return ref
          .watch(propertyRepositoryProvider)
          .watchProperties(workspaceId: ref.watch(currentWorkspaceIdProvider));
    });

final _allUnitsProvider = StreamProvider.autoDispose<List<UnitSale>>((ref) {
  return ref
      .watch(salesRepositoryProvider)
      .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final _allInstallmentsProvider = StreamProvider.autoDispose<List<Installment>>((
  ref,
) {
  return ref
      .watch(installmentRepositoryProvider)
      .watchAllInstallments(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final _allPaymentsProvider = StreamProvider.autoDispose<List<PaymentRecord>>((
  ref,
) {
  return ref
      .watch(paymentRepositoryProvider)
      .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final _allExpensesProvider = StreamProvider.autoDispose<List<ExpenseRecord>>((
  ref,
) {
  return ref
      .watch(expenseRepositoryProvider)
      .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final _allMaterialsProvider =
    StreamProvider.autoDispose<List<MaterialExpenseEntry>>((ref) {
      return ref
          .watch(materialExpenseRepositoryProvider)
          .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
    });

final _allSupplierPaymentsProvider =
    StreamProvider.autoDispose<List<SupplierPaymentRecord>>((ref) {
      return ref
          .watch(supplierPaymentRepositoryProvider)
          .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
    });

final propertyDetailsProvider = Provider.autoDispose
    .family<AsyncValue<PropertyProject?>, String>((ref, propertyId) {
      final properties = ref.watch(_allPropertiesProvider);
      if (properties.hasError) {
        return AsyncError(
          properties.error!,
          properties.stackTrace ?? StackTrace.current,
        );
      }
      if (!properties.hasValue) {
        return const AsyncLoading();
      }

      return AsyncData(
        properties.valueOrNull?.firstWhereOrNull(
          (property) => property.id == propertyId,
        ),
      );
    });

final propertyUnitsProvider = Provider.autoDispose
    .family<AsyncValue<List<UnitSale>>, String>((ref, propertyId) {
      final units = ref.watch(_allUnitsProvider);
      return _filterByProperty(units, propertyId, (unit) => unit.propertyId);
    });

final propertyInstallmentsProvider = Provider.autoDispose
    .family<AsyncValue<List<Installment>>, String>((ref, propertyId) {
      final installments = ref.watch(_allInstallmentsProvider);
      return _filterByProperty(
        installments,
        propertyId,
        (installment) => installment.propertyId,
      );
    });

final propertyPaymentsProvider = Provider.autoDispose
    .family<AsyncValue<List<PaymentRecord>>, String>((ref, propertyId) {
      final payments = ref.watch(_allPaymentsProvider);
      return _filterByProperty(
        payments,
        propertyId,
        (payment) => payment.propertyId,
      );
    });

final propertyExpensesProvider = Provider.autoDispose
    .family<AsyncValue<List<ExpenseRecord>>, String>((ref, propertyId) {
      final expenses = ref.watch(_allExpensesProvider);
      return _filterByProperty(
        expenses,
        propertyId,
        (expense) => expense.propertyId,
      );
    });

final propertyMaterialsProvider = Provider.autoDispose
    .family<AsyncValue<List<MaterialExpenseEntry>>, String>((ref, propertyId) {
      final materials = ref.watch(_allMaterialsProvider);
      return _filterByProperty(
        materials,
        propertyId,
        (material) => material.propertyId,
      );
    });

final propertySupplierPaymentsProvider = Provider.autoDispose
    .family<AsyncValue<List<SupplierPaymentRecord>>, String>((ref, propertyId) {
      final supplierPayments = ref.watch(_allSupplierPaymentsProvider);
      return _filterByProperty(
        supplierPayments,
        propertyId,
        (payment) => payment.propertyId,
      );
    });

final propertyPartnersProvider = StreamProvider.autoDispose<List<Partner>>((
  ref,
) {
  return ref
      .watch(partnerRepositoryProvider)
      .watchPartners(workspaceId: ref.watch(currentWorkspaceIdProvider));
});

final unitExpensesByUnitProvider = StreamProvider.autoDispose
    .family<List<UnitExpenseRecord>, UnitExpensesByUnitRequest>(
      (ref, request) => ref
          .watch(unitExpenseRepositoryProvider)
          .watchByUnit(
            unitId: request.unitId,
            workspaceId: request.workspaceId,
          ),
    );

final propertyPartnerLedgerProvider =
    StreamProvider.autoDispose<List<PartnerLedgerEntry>>((ref) {
      return ref
          .watch(partnerLedgerRepositoryProvider)
          .watchAll(workspaceId: ref.watch(currentWorkspaceIdProvider));
    });

final propertyProjectViewDataProvider = Provider.autoDispose
    .family<AsyncValue<PropertyProjectViewData?>, String>((ref, propertyId) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertyDetailsProvider(propertyId)),
        ref.watch(propertyUnitsProvider(propertyId)),
        ref.watch(propertyInstallmentsProvider(propertyId)),
        ref.watch(propertyPaymentsProvider(propertyId)),
        ref.watch(propertyExpensesProvider(propertyId)),
        ref.watch(propertyMaterialsProvider(propertyId)),
        ref.watch(propertySupplierPaymentsProvider(propertyId)),
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

      final property =
          ref.watch(propertyDetailsProvider(propertyId)).valueOrNull ??
          _buildFallbackProperty(propertyId);

      final session = ref.watch(authSessionProvider).valueOrNull;
      final composer = const PropertyDetailComposer();

      return AsyncData(
        composer.buildProjectViewData(
          property: property,
          currentUserId: session?.userId,
          currentUserDisplayName:
              session?.profile?.name ??
              session?.displayName?.trim() ??
              'المستخدم الحالي',
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
          supplierPayments:
              ref
                  .watch(propertySupplierPaymentsProvider(propertyId))
                  .valueOrNull ??
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
      final session = ref.watch(authSessionProvider).valueOrNull;
      final workspaceId = ref.watch(currentWorkspaceIdProvider);
      final unitExpensesRequest = UnitExpensesByUnitRequest(
        unitId: request.unitId,
        workspaceId: workspaceId,
      );
      final values = <AsyncValue<dynamic>>[
        ref.watch(propertyDetailsProvider(request.propertyId)),
        ref.watch(propertyUnitsProvider(request.propertyId)),
        ref.watch(propertyInstallmentsProvider(request.propertyId)),
        ref.watch(propertyPaymentsProvider(request.propertyId)),
        ref.watch(unitExpensesByUnitProvider(unitExpensesRequest)),
        ref.watch(propertyPartnersProvider),
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
          currentUserId: session?.userId,
          currentUserDisplayName:
              session?.profile?.name ??
              session?.displayName?.trim() ??
              'المستخدم الحالي',
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
          unitExpenses:
              ref
                  .watch(unitExpensesByUnitProvider(unitExpensesRequest))
                  .valueOrNull ??
              const [],
          partners: ref.watch(propertyPartnersProvider).valueOrNull ?? const [],
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

class UnitExpensesByUnitRequest {
  const UnitExpensesByUnitRequest({
    required this.unitId,
    required this.workspaceId,
  });

  final String unitId;
  final String workspaceId;

  @override
  bool operator ==(Object other) {
    return other is UnitExpensesByUnitRequest &&
        other.unitId == unitId &&
        other.workspaceId == workspaceId;
  }

  @override
  int get hashCode => Object.hash(unitId, workspaceId);
}

AsyncValue<List<T>> _filterByProperty<T>(
  AsyncValue<List<T>> source,
  String propertyId,
  String Function(T item) propertyIdSelector,
) {
  if (source.hasError) {
    return AsyncError(source.error!, source.stackTrace ?? StackTrace.current);
  }
  if (!source.hasValue) {
    return const AsyncLoading();
  }

  return AsyncData(
    (source.valueOrNull ?? <T>[])
        .where((item) => propertyIdSelector(item) == propertyId)
        .toList(growable: false),
  );
}

PropertyProject _buildFallbackProperty(String propertyId) {
  final now = DateTime.now();
  return PropertyProject(
    id: propertyId,
    name: 'العقار',
    location: 'بيانات محلية أو قيم افتراضية',
    apartmentCount: 0,
    description: '',
    status: PropertyStatus.active,
    totalBudget: 0,
    totalSalesTarget: 0,
    createdAt: now,
    updatedAt: now,
    createdBy: '',
    updatedBy: '',
    workspaceId: '',
    archived: false,
  );
}
