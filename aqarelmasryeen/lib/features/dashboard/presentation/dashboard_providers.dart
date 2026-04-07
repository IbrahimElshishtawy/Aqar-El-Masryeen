import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/payments/data/payment_repository.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/sales/data/sales_repository.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);
final dashboardUnitsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(salesRepositoryProvider).watchAll(),
);
final dashboardPaymentsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);
final dashboardMaterialsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(materialExpenseRepositoryProvider).watchAll(),
);
final dashboardPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);

final dashboardViewDataProvider =
    Provider.autoDispose<AsyncValue<DashboardViewData>>((ref) {
      final values = <AsyncValue<dynamic>>[
        ref.watch(dashboardPropertiesProvider),
        ref.watch(dashboardUnitsProvider),
        ref.watch(dashboardPaymentsProvider),
        ref.watch(dashboardMaterialsProvider),
        ref.watch(dashboardPartnersProvider),
      ];

      final error = values.firstWhereOrNull((value) => value.hasError);
      if (error != null) {
        return AsyncError(error.error!, error.stackTrace ?? StackTrace.current);
      }
      if (values.any((value) => !value.hasValue)) {
        return const AsyncLoading();
      }

      final partners =
          ref.watch(dashboardPartnersProvider).valueOrNull ?? const [];
      final session = ref.watch(authSessionProvider).valueOrNull;
      final currentPartner = session == null
          ? null
          : partners.firstWhereOrNull(
              (partner) => partner.userId == session.userId,
            );
      final otherPartners = currentPartner == null
          ? partners
          : partners
                .where((partner) => partner.id != currentPartner.id)
                .toList();

      return AsyncData(
        DashboardViewData(
          snapshot: const DashboardSnapshotBuilder().build(
            properties:
                ref.watch(dashboardPropertiesProvider).valueOrNull ?? const [],
            units: ref.watch(dashboardUnitsProvider).valueOrNull ?? const [],
            payments:
                ref.watch(dashboardPaymentsProvider).valueOrNull ?? const [],
            materials:
                ref.watch(dashboardMaterialsProvider).valueOrNull ?? const [],
            partners: partners,
          ),
          partners: partners,
          currentPartner: currentPartner,
          otherPartners: otherPartners,
        ),
      );
    });

class DashboardViewData {
  const DashboardViewData({
    required this.snapshot,
    required this.partners,
    required this.currentPartner,
    required this.otherPartners,
  });

  final DashboardSnapshot snapshot;
  final List<Partner> partners;
  final Partner? currentPartner;
  final List<Partner> otherPartners;
}
