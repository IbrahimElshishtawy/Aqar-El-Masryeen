import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/core/widgets/app_shell_scaffold.dart';
import 'package:aqarelmasryeen/core/widgets/empty_state_view.dart';
import 'package:aqarelmasryeen/core/widgets/load_failure_view.dart';
import 'package:aqarelmasryeen/features/expenses/domain/materials_ledger_calculator.dart';
import 'package:aqarelmasryeen/features/expenses/presentation/material_expense_form_sheet.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PropertyMaterialsScreen extends ConsumerStatefulWidget {
  const PropertyMaterialsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyMaterialsScreen> createState() =>
      _PropertyMaterialsScreenState();
}

class _PropertyMaterialsScreenState
    extends ConsumerState<PropertyMaterialsScreen> {
  Future<void> _showMaterialSheet({
    required List<Partner> partners,
    MaterialExpenseEntry? entry,
    String? initialSupplierName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MaterialExpenseFormSheet(
        propertyId: widget.propertyId,
        partners: partners,
        entry: entry,
        initialSupplierName: initialSupplierName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(
      propertyProjectViewDataProvider(widget.propertyId),
    );

    return asyncData.when(
      loading: () => const AppShellScaffold(
        title: 'مواد البناء',
        subtitle: 'تحميل بيانات العقار',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => AppShellScaffold(
        title: 'مواد البناء',
        subtitle: 'تعذر تحميل البيانات',
        currentIndex: 1,
        child: LoadFailureView(
          title: 'تعذر تحميل مواد البناء',
          error: error,
          onRetry: () => ref.invalidate(
            propertyProjectViewDataProvider(widget.propertyId),
          ),
        ),
      ),
      data: (data) {
        if (data == null) {
          return const AppShellScaffold(
            title: 'مواد البناء',
            subtitle: 'العقار غير موجود',
            currentIndex: 1,
            child: EmptyStateView(
              title: 'العقار غير موجود',
              message: 'لم نتمكن من العثور على هذا العقار.',
            ),
          );
        }

        return AppShellScaffold(
          title: 'مواد البناء',
          subtitle: data.property.name,
          currentIndex: 1,
          actions: [
            _MaterialsTopBarAction(
              onPressed: () => _showMaterialSheet(partners: data.partners),
            ),
          ],
          child: ListView(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
            children: [
              _SupplierOverviewPanel(
                summaries: data.materialsSnapshot.supplierSummaries,
                onOpenSupplier: (supplierName) => context.push(
                  AppRoutes.propertyMaterialSupplier(
                    widget.propertyId,
                    supplierName,
                  ),
                ),
                onAddPayment: (supplierName) => context.push(
                  AppRoutes.propertyMaterialSupplier(
                    widget.propertyId,
                    supplierName,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaterialsTopBarAction extends StatelessWidget {
  const _MaterialsTopBarAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Center(
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('إضافة فاتورة'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          ),
        ),
      ),
    );
  }
}

class _SupplierOverviewPanel extends StatelessWidget {
  const _SupplierOverviewPanel({
    required this.summaries,
    required this.onOpenSupplier,
    required this.onAddPayment,
  });

  final List<SupplierLedgerSummary> summaries;
  final ValueChanged<String> onOpenSupplier;
  final ValueChanged<String> onAddPayment;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: 'الموردون',
      subtitle: summaries.isEmpty
          ? 'أضف أول مورد من البار العلوي لبدء تسجيل فواتير مواد البناء.'
          : 'اضغط على اسم المورد لفتح كشف الحساب، ويمكنك أيضًا الوصول سريعًا إلى إضافة دفعة للموردين الذين لديهم متبقي.',
      child: summaries.isEmpty
          ? const EmptyStateView(
              title: 'لا يوجد موردون بعد',
              message: 'بمجرد إضافة المورد وأول فاتورة مواد بناء سيظهر هنا.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                return GridView.builder(
                  itemCount: summaries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: columns == 1 ? 1.65 : 1.28,
                  ),
                  itemBuilder: (context, index) {
                    final supplier = summaries[index];
                    return _SupplierSummaryCard(
                      summary: supplier,
                      onTap: () => onOpenSupplier(supplier.supplierName),
                      onAddPayment: _summaryHasRemaining(supplier)
                          ? () => onAddPayment(supplier.supplierName)
                          : null,
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SupplierSummaryCard extends StatelessWidget {
  const _SupplierSummaryCard({
    required this.summary,
    required this.onTap,
    this.onAddPayment,
  });

  final SupplierLedgerSummary summary;
  final VoidCallback onTap;
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8D8D2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.supplierName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${summary.invoiceCount} فاتورة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _SupplierMetricPill(
                      label: 'المطلوب',
                      value: summary.totalPurchased.egp,
                    ),
                    _SupplierMetricPill(
                      label: 'المدفوع',
                      value: summary.totalPaid.egp,
                    ),
                    _SupplierMetricPill(
                      label: 'المتبقي',
                      value: summary.totalRemaining.egp,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                if (onAddPayment != null) ...[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddPayment,
                      icon: const Icon(Icons.add_card_rounded, size: 18),
                      label: const Text('إضافة دفعة'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onTap,
                    child: const Text('فتح كشف المورد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _summaryHasRemaining(SupplierLedgerSummary summary) {
  return summary.totalRemaining > 0;
}

class _SupplierMetricPill extends StatelessWidget {
  const _SupplierMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 60,
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
