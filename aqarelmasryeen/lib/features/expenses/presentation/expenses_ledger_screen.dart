import 'dart:math' as math;

import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/auth/presentation/auth_providers.dart';
import 'package:aqarelmasryeen/features/expenses/data/expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/presentation/partner_ledger_entry_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/data/property_repository.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final allExpensesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(expenseRepositoryProvider).watchAll(),
);
final allMaterialsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(materialExpenseRepositoryProvider).watchAll(),
);
final allPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);
final allPartnerLedgersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
);
final allPropertiesProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(propertyRepositoryProvider).watchProperties(),
);

class ExpensesLedgerScreen extends ConsumerWidget {
  const ExpensesLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final expensesAsync = ref.watch(allExpensesProvider);
    final materialsAsync = ref.watch(allMaterialsProvider);
    final partnersAsync = ref.watch(allPartnersProvider);
    final partnerLedgersAsync = ref.watch(allPartnerLedgersProvider);
    final propertiesAsync = ref.watch(allPropertiesProvider);

    if (expensesAsync.hasError ||
        materialsAsync.hasError ||
        partnersAsync.hasError ||
        partnerLedgersAsync.hasError ||
        propertiesAsync.hasError) {
      return AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'الجداول المالية والموارد والموردون',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل شاشة المصاريف',
          message:
              expensesAsync.error?.toString() ??
              materialsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              partnerLedgersAsync.error?.toString() ??
              propertiesAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    if (!expensesAsync.hasValue ||
        !materialsAsync.hasValue ||
        !partnersAsync.hasValue ||
        !partnerLedgersAsync.hasValue ||
        !propertiesAsync.hasValue) {
      return const AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'الجداول المالية والموارد والموردون',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final expenses = expensesAsync.value!;
    final materials = materialsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerLedgers = partnerLedgersAsync.value!;
    final properties = propertiesAsync.value!;

    final propertyNames = {
      for (final property in properties) property.id: property.name,
    };
    final partnerNames = {
      for (final partner in partners) partner.id: partner.name,
    };
    final materialSnapshot = const MaterialsLedgerCalculator().build(materials);
    final partnerSnapshot = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: expenses,
      materialExpenses: materials,
      ledgerEntries: partnerLedgers,
    );

    final currentPartner =
        partners.firstWhereOrNull(
          (partner) => partner.userId == session?.userId,
        ) ??
        partners.firstOrNull;
    final otherPartners = currentPartner == null
        ? <Partner>[]
        : partners.where((partner) => partner.id != currentPartner.id).toList();

    final mineSnapshot = _buildPartyFinanceSnapshot(
      title: currentPartner == null
          ? 'مصروفاتي'
          : 'أنا - ${currentPartner.name}',
      fallbackSubtitle: 'كل الحركات المالية الخاصة بحسابك',
      partners: currentPartner == null ? const <Partner>[] : [currentPartner],
      expenses: expenses,
      ledgerEntries: partnerLedgers,
      propertyNames: propertyNames,
      partnerNames: partnerNames,
      totalExposure:
          expenses.fold<double>(0, (sum, item) => sum + item.amount) +
          materials.fold<double>(0, (sum, item) => sum + item.totalPrice),
    );
    final partnerFinanceSnapshot = _buildPartyFinanceSnapshot(
      title: otherPartners.length == 1
          ? 'الشريك - ${otherPartners.first.name}'
          : 'الشركاء',
      fallbackSubtitle: 'كل الحركات المالية الخاصة بالطرف الآخر',
      partners: otherPartners,
      expenses: expenses,
      ledgerEntries: partnerLedgers,
      propertyNames: propertyNames,
      partnerNames: partnerNames,
      totalExposure:
          expenses.fold<double>(0, (sum, item) => sum + item.amount) +
          materials.fold<double>(0, (sum, item) => sum + item.totalPrice),
    );

    final totalDirectExpenses = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalFinancialExposure =
        totalDirectExpenses + materialSnapshot.overallTotal;
    final initialTabIndex = _resolveInitialTabIndex(context);
    final tabViewHeight = math.max(
      MediaQuery.sizeOf(context).height - 260,
      820.0,
    );

    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex,
      child: AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'جداول عربية شبيهة بالإكسل لكل البيانات المالية',
        currentIndex: 1,
        automaticallyImplyLeading: false,
        titleActions: [
          _ExpensesTopBarActions(properties: properties, partners: partners),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ExpenseSummaryGrid(
              cards: [
                SummaryCard(
                  label: 'إجمالي المصروفات المباشرة',
                  value: totalDirectExpenses.egp,
                  subtitle: 'كل المصروفات المسجلة على المشروعات',
                  icon: Icons.receipt_long_outlined,
                  emphasis: true,
                ),
                SummaryCard(
                  label: 'إجمالي الموارد',
                  value: materialSnapshot.overallTotal.egp,
                  subtitle: 'فواتير مواد البناء والموردين',
                  icon: Icons.inventory_2_outlined,
                ),
                SummaryCard(
                  label: 'إجمالي الالتزام المالي',
                  value: totalFinancialExposure.egp,
                  subtitle: 'المصروفات المباشرة + الموارد',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                SummaryCard(
                  label: mineSnapshot.title,
                  value: mineSnapshot.totalPaid.egp,
                  subtitle: 'المدفوع فعليًا من جهتك',
                  icon: Icons.person_outline_rounded,
                ),
                SummaryCard(
                  label: partnerFinanceSnapshot.title,
                  value: partnerFinanceSnapshot.totalPaid.egp,
                  subtitle: 'المدفوع فعليًا من جهة الشريك',
                  icon: Icons.groups_outlined,
                ),
                SummaryCard(
                  label: 'الموردون المفتوحون',
                  value: '${materialSnapshot.supplierSummaries.length}',
                  subtitle: 'عدد الموردين الذين لديهم حركة مالية',
                  icon: Icons.storefront_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD8D8D2)),
              ),
              child: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'سجل المصروفات'),
                  Tab(text: 'أنا / الشريك'),
                  Tab(text: 'الموارد'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: tabViewHeight,
              child: TabBarView(
                children: [
                  _ExpensesRegisterTab(
                    expenses: expenses,
                    propertyNames: propertyNames,
                    partnerNames: partnerNames,
                  ),
                  _OwnershipTablesTab(
                    mineSnapshot: mineSnapshot,
                    partnerSnapshot: partnerFinanceSnapshot,
                  ),
                  _ResourcesTab(
                    snapshot: materialSnapshot,
                    rows: partnerSnapshot,
                    propertyNames: propertyNames,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTopBarActions extends StatelessWidget {
  const _ExpensesTopBarActions({
    required this.properties,
    required this.partners,
  });

  final List<PropertyProject> properties;
  final List<Partner> partners;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.maybeOf(context);
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tabIndex = controller.index;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TopBarIconButton(
              icon: Icons.add_rounded,
              tooltip: _tooltipForTab(tabIndex),
              onPressed: () => _handleAddPressed(context, tabIndex),
            ),
            _TopBarIconButton(
              icon: Icons.arrow_forward_rounded,
              tooltip: 'رجوع',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go(AppRoutes.properties);
              },
            ),
          ],
        );
      },
    );
  }

  String _tooltipForTab(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return 'إضافة حركة شريك';
      case 2:
        return 'إضافة مورد';
      default:
        return 'إضافة مصروف';
    }
  }

  Future<void> _handleAddPressed(BuildContext context, int tabIndex) async {
    switch (tabIndex) {
      case 1:
        final partner = await _pickPartner(context);
        if (partner == null || !context.mounted) return;
        final property = await _pickProperty(
          context,
          title: 'اختاري المشروع المرتبط بالحركة',
          emptyMessage: 'لا توجد مشروعات متاحة لإضافة حركة شريك.',
        );
        if (property == null || !context.mounted) return;
        await _openFormSheet(
          context,
          PartnerLedgerEntryFormSheet(
            partner: partner,
            propertyId: property.id,
          ),
        );
        return;
      case 2:
        final property = await _pickProperty(
          context,
          title: 'اختاري المشروع لإضافة مورد',
          emptyMessage: 'لا توجد مشروعات متاحة لإضافة مورد.',
        );
        if (property == null || !context.mounted) return;
        await _openFormSheet(
          context,
          MaterialExpenseFormSheet(propertyId: property.id),
        );
        return;
      default:
        final property = await _pickProperty(
          context,
          title: 'اختاري المشروع لإضافة مصروف',
          emptyMessage: 'لا توجد مشروعات متاحة لإضافة مصروف.',
        );
        if (property == null || !context.mounted) return;
        await _openFormSheet(
          context,
          ExpenseFormSheet(propertyId: property.id, partners: partners),
        );
    }
  }

  Future<PropertyProject?> _pickProperty(
    BuildContext context, {
    required String title,
    required String emptyMessage,
  }) async {
    if (properties.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emptyMessage)));
      return null;
    }
    if (properties.length == 1) {
      return properties.first;
    }

    return showModalBottomSheet<PropertyProject>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => _SelectionSheet<PropertyProject>(
        title: title,
        items: properties,
        labelBuilder: (item) => item.name,
        onSelected: (item) => Navigator.of(sheetContext).pop(item),
      ),
    );
  }

  Future<Partner?> _pickPartner(BuildContext context) async {
    if (partners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد شركاء متاحون لإضافة حركة.')),
      );
      return null;
    }
    if (partners.length == 1) {
      return partners.first;
    }

    return showModalBottomSheet<Partner>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => _SelectionSheet<Partner>(
        title: 'اختاري الشريك',
        items: partners,
        labelBuilder: (item) => item.name,
        onSelected: (item) => Navigator.of(sheetContext).pop(item),
      ),
    );
  }

  Future<void> _openFormSheet(BuildContext context, Widget child) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => child,
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: const BorderSide(color: Color(0xFFD8D8D2)),
      ),
      icon: Icon(icon),
    );
  }
}

class _SelectionSheet<T> extends StatelessWidget {
  const _SelectionSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(labelBuilder(item)),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesRegisterTab extends StatelessWidget {
  const _ExpensesRegisterTab({
    required this.expenses,
    required this.propertyNames,
    required this.partnerNames,
  });

  final List<ExpenseRecord> expenses;
  final Map<String, String> propertyNames;
  final Map<String, String> partnerNames;

  @override
  Widget build(BuildContext context) {
    final rows = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final totalAmount = rows.fold<double>(0, (sum, item) => sum + item.amount);

    return ListView(
      children: [
        FinancialLedgerTable<ExpenseRecord>(
          title: 'سجل المصروفات',
          subtitle: '${rows.length} حركة - الإجمالي ${totalAmount.egp}',
          rows: rows,
          sheetLabel: 'ورقة المصروفات المباشرة',
          forceTableLayout: true,
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.date.formatShort()),
              minWidth: 118,
            ),
            LedgerColumn(
              label: 'المشروع',
              valueBuilder: (row) =>
                  Text(propertyNames[row.propertyId] ?? 'بدون مشروع'),
              minWidth: 170,
            ),
            LedgerColumn(
              label: 'الفئة',
              valueBuilder: (row) => Text(row.category.label),
              minWidth: 120,
            ),
            LedgerColumn(
              label: 'البيان',
              valueBuilder: (row) => Text(row.description),
              minWidth: 180,
            ),
            LedgerColumn(
              label: 'الدافع',
              valueBuilder: (row) =>
                  Text(partnerNames[row.paidByPartnerId] ?? 'غير محدد'),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'طريقة الدفع',
              valueBuilder: (row) => Text(row.paymentMethod.label),
              minWidth: 130,
            ),
            LedgerColumn(
              label: 'القيمة',
              valueBuilder: (row) => Text(row.amount.egp),
              minWidth: 130,
              numeric: true,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(row.notes.isEmpty ? '-' : row.notes),
              minWidth: 200,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'إجمالي المصروفات',
                value: totalAmount.egp,
              ),
              LedgerFooterValue(label: 'عدد السجلات', value: '${rows.length}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnershipTablesTab extends StatelessWidget {
  const _OwnershipTablesTab({
    required this.mineSnapshot,
    required this.partnerSnapshot,
  });

  final _PartyFinanceSnapshot mineSnapshot;
  final _PartyFinanceSnapshot partnerSnapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final useSideBySide = constraints.maxWidth >= 1100;
            if (useSideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PartyFinanceTable(snapshot: mineSnapshot)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PartyFinanceTable(snapshot: partnerSnapshot),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _PartyFinanceTable(snapshot: mineSnapshot),
                const SizedBox(height: 16),
                _PartyFinanceTable(snapshot: partnerSnapshot),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({
    required this.snapshot,
    required this.rows,
    required this.propertyNames,
  });

  final MaterialsLedgerSnapshot snapshot;
  final List<PartnerLedgerSummaryRow> rows;
  final Map<String, String> propertyNames;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FinancialLedgerTable<MaterialExpenseEntry>(
          title: 'جدول الموارد',
          subtitle:
              '${snapshot.entries.length} صف - إجمالي الموارد ${snapshot.overallTotal.egp}',
          rows: snapshot.entries,
          sheetLabel: 'ورقة الموارد والموردين',
          forceTableLayout: true,
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.date.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'المشروع',
              valueBuilder: (row) =>
                  Text(propertyNames[row.propertyId] ?? 'بدون مشروع'),
              minWidth: 160,
            ),
            LedgerColumn(
              label: 'المورد',
              valueBuilder: (row) => Text(row.supplierName),
              minWidth: 160,
            ),
            LedgerColumn(
              label: 'الصنف',
              valueBuilder: (row) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    row.materialCategory.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    row.itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              minWidth: 180,
            ),
            LedgerColumn(
              label: 'الكمية',
              valueBuilder: (row) => Text('${row.quantity}'),
              minWidth: 90,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المدفوع',
              valueBuilder: (row) => Text(row.amountPaid.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'المتبقي',
              valueBuilder: (row) => Text(row.amountRemaining.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.totalPrice.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الحالة',
              valueBuilder: (row) => FinancialStatusChip(
                label: row.status.label,
                color: _statusColor(row.status),
              ),
              minWidth: 120,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'إجمالي الفواتير',
                value: snapshot.overallTotal.egp,
              ),
              LedgerFooterValue(
                label: 'إجمالي المدفوع',
                value: snapshot.overallPaid.egp,
              ),
              LedgerFooterValue(
                label: 'إجمالي المتبقي',
                value: snapshot.overallRemaining.egp,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<SupplierLedgerSummary>(
          title: 'ملخص الموردين',
          subtitle: 'كم دفعت لكل مورد وكم تبقى عليه',
          rows: snapshot.supplierSummaries,
          sheetLabel: 'ورقة ملخص الموردين',
          columns: [
            LedgerColumn(
              label: 'اسم المورد',
              valueBuilder: (row) => Text(row.supplierName),
              minWidth: 180,
            ),
            LedgerColumn(
              label: 'عدد الفواتير',
              valueBuilder: (row) => Text('${row.invoiceCount}'),
              minWidth: 110,
              numeric: true,
            ),
            LedgerColumn(
              label: 'إجمالي المشتريات',
              valueBuilder: (row) => Text(row.totalPurchased.egp),
              minWidth: 140,
              numeric: true,
            ),
            LedgerColumn(
              label: 'إجمالي المدفوع',
              valueBuilder: (row) => Text(row.totalPaid.egp),
              minWidth: 140,
              numeric: true,
            ),
            LedgerColumn(
              label: 'إجمالي المتبقي',
              valueBuilder: (row) => Text(row.totalRemaining.egp),
              minWidth: 140,
              numeric: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<PartnerLedgerSummaryRow>(
          title: 'ملخص التزامات الشركاء',
          subtitle: 'رؤية سريعة لرصيد كل شريك مقارنة بالمصروفات الكلية',
          rows: rows,
          sheetLabel: 'ورقة ملخص الشركاء',
          columns: [
            LedgerColumn(
              label: 'الشريك',
              valueBuilder: (row) => Text(row.partner.name),
              minWidth: 170,
            ),
            LedgerColumn(
              label: 'إجمالي المدفوع',
              valueBuilder: (row) => Text(row.totalPaid.egp),
              minWidth: 140,
              numeric: true,
            ),
            LedgerColumn(
              label: 'إجمالي المستحق',
              valueBuilder: (row) => Text(row.totalOwed.egp),
              minWidth: 140,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الرصيد',
              valueBuilder: (row) => Text(row.balance.egp),
              minWidth: 130,
              numeric: true,
            ),
            LedgerColumn(
              label: 'آخر تحديث',
              valueBuilder: (row) => Text(row.lastUpdated.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(row.notes.isEmpty ? '-' : row.notes),
              minWidth: 190,
            ),
          ],
        ),
      ],
    );
  }
}

class _PartyFinanceTable extends StatelessWidget {
  const _PartyFinanceTable({required this.snapshot});

  final _PartyFinanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return FinancialLedgerTable<_PartyFinanceRow>(
      title: snapshot.title,
      subtitle: snapshot.subtitle,
      rows: snapshot.rows,
      sheetLabel: 'ورقة ${snapshot.title}',
      forceTableLayout: true,
      columns: [
        LedgerColumn(
          label: 'التاريخ',
          valueBuilder: (row) => Text(row.date.formatShort()),
          minWidth: 116,
        ),
        LedgerColumn(
          label: 'الطرف',
          valueBuilder: (row) => Text(row.partyName),
          minWidth: 140,
        ),
        LedgerColumn(
          label: 'المشروع',
          valueBuilder: (row) => Text(row.projectName),
          minWidth: 160,
        ),
        LedgerColumn(
          label: 'نوع الحركة',
          valueBuilder: (row) => Text(row.entryTypeLabel),
          minWidth: 130,
        ),
        LedgerColumn(
          label: 'التفصيل',
          valueBuilder: (row) => Text(row.description),
          minWidth: 180,
        ),
        LedgerColumn(
          label: 'طريقة الدفع',
          valueBuilder: (row) => Text(row.paymentMethodLabel),
          minWidth: 120,
        ),
        LedgerColumn(
          label: 'القيمة',
          valueBuilder: (row) => Text(row.amount.egp),
          minWidth: 130,
          numeric: true,
        ),
        LedgerColumn(
          label: 'ملاحظات',
          valueBuilder: (row) => Text(row.notes.isEmpty ? '-' : row.notes),
          minWidth: 180,
        ),
      ],
      totalsFooter: LedgerTotalsFooter(
        children: [
          LedgerFooterValue(
            label: 'مصروف مباشر',
            value: snapshot.directExpenses.egp,
          ),
          LedgerFooterValue(
            label: 'مساهمات وتسويات',
            value: snapshot.authorizedPaid.egp,
          ),
          LedgerFooterValue(
            label: 'الإجمالي المدفوع',
            value: snapshot.totalPaid.egp,
          ),
          LedgerFooterValue(
            label: 'المستحق المتوقع',
            value: snapshot.expectedShare.egp,
          ),
          LedgerFooterValue(
            label: 'المتبقي عليه',
            value: snapshot.totalOwed.egp,
          ),
          LedgerFooterValue(label: 'الرصيد', value: snapshot.balance.egp),
        ],
      ),
    );
  }
}

class _ExpenseSummaryGrid extends StatelessWidget {
  const _ExpenseSummaryGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: count == 1 ? 2.5 : 1.6,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _PartyFinanceRow {
  const _PartyFinanceRow({
    required this.date,
    required this.partyName,
    required this.projectName,
    required this.entryTypeLabel,
    required this.description,
    required this.paymentMethodLabel,
    required this.amount,
    required this.notes,
  });

  final DateTime date;
  final String partyName;
  final String projectName;
  final String entryTypeLabel;
  final String description;
  final String paymentMethodLabel;
  final double amount;
  final String notes;
}

class _PartyFinanceSnapshot {
  const _PartyFinanceSnapshot({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.directExpenses,
    required this.authorizedPaid,
    required this.totalPaid,
    required this.expectedShare,
    required this.totalOwed,
    required this.balance,
  });

  final String title;
  final String subtitle;
  final List<_PartyFinanceRow> rows;
  final double directExpenses;
  final double authorizedPaid;
  final double totalPaid;
  final double expectedShare;
  final double totalOwed;
  final double balance;
}

_PartyFinanceSnapshot _buildPartyFinanceSnapshot({
  required String title,
  required String fallbackSubtitle,
  required List<Partner> partners,
  required List<ExpenseRecord> expenses,
  required List<PartnerLedgerEntry> ledgerEntries,
  required Map<String, String> propertyNames,
  required Map<String, String> partnerNames,
  required double totalExposure,
}) {
  final partnerIds = partners.map((partner) => partner.id).toSet();
  final shareRatio = partners.fold<double>(
    0,
    (sum, partner) => sum + partner.shareRatio,
  );

  final directExpenses =
      expenses
          .where((expense) => partnerIds.contains(expense.paidByPartnerId))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  final partnerTransactions =
      ledgerEntries
          .where(
            (entry) => !entry.archived && partnerIds.contains(entry.partnerId),
          )
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final directExpenseTotal = directExpenses.fold<double>(
    0,
    (sum, expense) => sum + expense.amount,
  );
  final authorizedPaid = partnerTransactions
      .where(
        (entry) =>
            entry.entryType == PartnerLedgerEntryType.contribution ||
            entry.entryType == PartnerLedgerEntryType.settlement ||
            entry.entryType == PartnerLedgerEntryType.adjustment,
      )
      .fold<double>(0, (sum, entry) => sum + entry.amount);
  final totalPaid = directExpenseTotal + authorizedPaid;
  final expectedShare = totalExposure * shareRatio;
  final totalOwed = (expectedShare - totalPaid)
      .clamp(0, expectedShare)
      .toDouble();
  final balance = totalPaid - expectedShare;

  final rows = <_PartyFinanceRow>[
    for (final expense in directExpenses)
      _PartyFinanceRow(
        date: expense.date,
        partyName: partnerNames[expense.paidByPartnerId] ?? 'غير محدد',
        projectName: propertyNames[expense.propertyId] ?? 'بدون مشروع',
        entryTypeLabel: 'مصروف مباشر',
        description: '${expense.category.label} - ${expense.description}',
        paymentMethodLabel: expense.paymentMethod.label,
        amount: expense.amount,
        notes: expense.notes,
      ),
    for (final entry in partnerTransactions)
      _PartyFinanceRow(
        date: entry.updatedAt,
        partyName: partnerNames[entry.partnerId] ?? 'غير محدد',
        projectName: propertyNames[entry.propertyId] ?? 'بدون مشروع',
        entryTypeLabel: entry.entryType.label,
        description: _ledgerDescription(entry.entryType),
        paymentMethodLabel: 'قيد مالي',
        amount: entry.amount,
        notes: entry.notes,
      ),
  ]..sort((a, b) => b.date.compareTo(a.date));

  final subtitle = rows.isEmpty
      ? fallbackSubtitle
      : '${rows.length} حركة مالية - إجمالي المدفوع ${totalPaid.egp}';

  return _PartyFinanceSnapshot(
    title: title,
    subtitle: subtitle,
    rows: rows,
    directExpenses: directExpenseTotal,
    authorizedPaid: authorizedPaid,
    totalPaid: totalPaid,
    expectedShare: expectedShare,
    totalOwed: totalOwed,
    balance: balance,
  );
}

String _ledgerDescription(PartnerLedgerEntryType type) {
  switch (type) {
    case PartnerLedgerEntryType.contribution:
      return 'مساهمة رأسمالية';
    case PartnerLedgerEntryType.settlement:
      return 'تسوية مالية';
    case PartnerLedgerEntryType.obligation:
      return 'التزام على الشريك';
    case PartnerLedgerEntryType.adjustment:
      return 'تعديل رصيد';
  }
}

int _resolveInitialTabIndex(BuildContext context) {
  final tab = GoRouterState.of(context).uri.queryParameters['tab'];
  switch (tab) {
    case 'parties':
      return 1;
    case 'resources':
      return 2;
    default:
      return 0;
  }
}

Color _statusColor(SupplierInvoiceStatus status) {
  switch (status) {
    case SupplierInvoiceStatus.paid:
      return Colors.green;
    case SupplierInvoiceStatus.partiallyPaid:
      return Colors.orange;
    case SupplierInvoiceStatus.overdue:
      return Colors.redAccent;
    case SupplierInvoiceStatus.unpaid:
      return Colors.blueGrey;
  }
}
