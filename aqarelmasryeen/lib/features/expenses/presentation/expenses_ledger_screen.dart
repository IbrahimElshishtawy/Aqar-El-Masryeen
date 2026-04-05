import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/summary_card.dart';
import 'package:aqarelmasryeen/features/expenses/data/material_expense_repository.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_ledger_repository.dart';
import 'package:aqarelmasryeen/features/partners/data/partner_repository.dart';
import 'package:aqarelmasryeen/features/partners/domain/partner_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allMaterialsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(materialExpenseRepositoryProvider).watchAll(),
);
final allPartnersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerRepositoryProvider).watchPartners(),
);
final allPartnerLedgersProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(partnerLedgerRepositoryProvider).watchAll(),
);

class ExpensesLedgerScreen extends ConsumerWidget {
  const ExpensesLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(allMaterialsProvider);
    final partnersAsync = ref.watch(allPartnersProvider);
    final partnerLedgersAsync = ref.watch(allPartnerLedgersProvider);

    if (materialsAsync.hasError ||
        partnersAsync.hasError ||
        partnerLedgersAsync.hasError) {
      return AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'مواد البناء والموردون والشركاء',
        currentIndex: 1,
        child: EmptyStateView(
          title: 'تعذر تحميل جداول المصاريف',
          message:
              materialsAsync.error?.toString() ??
              partnersAsync.error?.toString() ??
              partnerLedgersAsync.error?.toString() ??
              'حدث خطأ غير متوقع',
        ),
      );
    }

    if (!materialsAsync.hasValue ||
        !partnersAsync.hasValue ||
        !partnerLedgersAsync.hasValue) {
      return const AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'مواد البناء والموردون والشركاء',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final materials = materialsAsync.value!;
    final partners = partnersAsync.value!;
    final partnerLedgers = partnerLedgersAsync.value!;
    final materialSnapshot = const MaterialsLedgerCalculator().build(materials);
    final partnerSnapshot = const PartnerLedgerCalculator().build(
      partners: partners,
      expenses: const <ExpenseRecord>[],
      materialExpenses: materials,
      ledgerEntries: partnerLedgers,
    );

    return DefaultTabController(
      length: 3,
      child: AppShellScaffold(
        title: 'المصاريف',
        subtitle: 'جداول عربية مناسبة للموبايل',
        currentIndex: 1,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ExpenseSummaryGrid(
                    cards: [
                      SummaryCard(
                        label: 'إجمالي مواد البناء',
                        value: materialSnapshot.overallTotal.egp,
                        subtitle: 'إجمالي قيمة الفواتير المسجلة',
                        icon: Icons.inventory_outlined,
                        emphasis: true,
                      ),
                      SummaryCard(
                        label: 'المدفوع للموردين',
                        value: materialSnapshot.overallPaid.egp,
                        subtitle: 'كل ما تم سداده من فواتير المواد',
                        icon: Icons.payments_outlined,
                      ),
                      SummaryCard(
                        label: 'المتبقي على الموردين',
                        value: materialSnapshot.overallRemaining.egp,
                        subtitle: 'إجمالي الأرصدة المفتوحة',
                        icon: Icons.pending_actions_outlined,
                      ),
                      SummaryCard(
                        label: 'عدد الموردين',
                        value: '${materialSnapshot.supplierSummaries.length}',
                        subtitle: 'تجار وموردون مسجلون',
                        icon: Icons.storefront_outlined,
                      ),
                      SummaryCard(
                        label: 'عدد الشركاء',
                        value: '${partnerSnapshot.length}',
                        subtitle: 'عرض فقط بدون تعديل مباشر',
                        icon: Icons.groups_outlined,
                      ),
                      SummaryCard(
                        label: 'فواتير المواد',
                        value: '${materialSnapshot.entries.length}',
                        subtitle: 'صفوف المواد المسجلة حتى الآن',
                        icon: Icons.table_chart_outlined,
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
                        Tab(text: 'مواد البناء'),
                        Tab(text: 'الموردون'),
                        Tab(text: 'الشركاء'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 900,
                    child: TabBarView(
                      children: [
                        _MaterialsTab(snapshot: materialSnapshot),
                        _SuppliersTab(snapshot: materialSnapshot),
                        _PartnersTab(rows: partnerSnapshot),
                      ],
                    ),
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

class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab({required this.snapshot});

  final MaterialsLedgerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FinancialLedgerTable<MaterialExpenseEntry>(
          title: 'ورقة مواد البناء',
          subtitle:
              '${snapshot.entries.length} صف - الإجمالي ${snapshot.overallTotal.egp}',
          rows: snapshot.entries,
          sheetLabel: 'ورقة إكسل مواد البناء',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.date.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'النوع / الصنف',
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
              label: 'سعر الوحدة',
              valueBuilder: (row) => Text(row.unitPrice.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الإجمالي',
              valueBuilder: (row) => Text(row.totalPrice.egp),
              minWidth: 124,
              numeric: true,
            ),
            LedgerColumn(
              label: 'التاجر / المورد',
              valueBuilder: (row) => Text(row.supplierName),
              minWidth: 170,
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
              label: 'الاستحقاق',
              valueBuilder: (row) =>
                  Text(row.dueDate == null ? '-' : row.dueDate!.formatShort()),
              minWidth: 116,
            ),
            LedgerColumn(
              label: 'الحالة',
              valueBuilder: (row) => FinancialStatusChip(
                label: row.status.label,
                color: _statusColor(row.status),
              ),
              minWidth: 116,
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
      ],
    );
  }
}

class _SuppliersTab extends StatelessWidget {
  const _SuppliersTab({required this.snapshot});

  final MaterialsLedgerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FinancialLedgerTable<MaterialCategoryTotal>(
          title: 'ورقة أنواع المواد',
          subtitle: 'تقسيم المواد حسب النوع مثل أسمنت وطوب وحديد',
          rows: snapshot.categoryTotals,
          sheetLabel: 'ورقة إكسل تصنيف مواد البناء',
          columns: [
            LedgerColumn(
              label: 'نوع المادة',
              valueBuilder: (row) => Text(row.categoryLabel),
              minWidth: 180,
            ),
            LedgerColumn(
              label: 'إجمالي الكمية',
              valueBuilder: (row) => Text('${row.totalQuantity}'),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'إجمالي المشتريات',
              valueBuilder: (row) => Text(row.totalSpending.egp),
              minWidth: 140,
              numeric: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<SupplierLedgerSummary>(
          title: 'ورقة الموردين',
          subtitle: 'كم دفعت لكل تاجر وكم متبقي عليه',
          rows: snapshot.supplierSummaries,
          sheetLabel: 'ورقة إكسل الموردين',
          columns: [
            LedgerColumn(
              label: 'اسم التاجر',
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
      ],
    );
  }
}

class _PartnersTab extends StatelessWidget {
  const _PartnersTab({required this.rows});

  final List<PartnerLedgerSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        FinancialLedgerTable<PartnerLedgerSummaryRow>(
          title: 'ورقة الشركاء',
          subtitle: 'عرض فقط: المدفوع والمستحق والرصيد لكل شريك',
          rows: rows,
          sheetLabel: 'ورقة إكسل الشركاء',
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
              minWidth: 200,
            ),
          ],
        ),
      ],
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
