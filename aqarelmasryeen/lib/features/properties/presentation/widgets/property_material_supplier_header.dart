// ignore_for_file: unused_element

part of '../property_material_supplier_screen.dart';

class _SupplierTopBarAction extends StatelessWidget {
  const _SupplierTopBarAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Center(
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }
}

class _SupplierHeaderPanel extends StatelessWidget {
  const _SupplierHeaderPanel({
    required this.supplierName,
    required this.totalQuantity,
    required this.invoiceCount,
    required this.paymentCount,
    required this.totalRequired,
    required this.totalPaid,
    required this.totalRemaining,
    required this.nextDueDate,
    required this.onAddQuantity,
    this.onAddPayment,
  });

  final String supplierName;
  final double totalQuantity;
  final int invoiceCount;
  final int paymentCount;
  final double totalRequired;
  final double totalPaid;
  final double totalRemaining;
  final DateTime? nextDueDate;
  final VoidCallback onAddQuantity;
  final VoidCallback? onAddPayment;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: supplierName,
      subtitle: nextDueDate == null
          ? 'كشف موحد يوضح الإضافات والدفعات وحالة المتبقي على المورد.'
          : 'أقرب تاريخ استحقاق مفتوح: ${nextDueDate!.formatShort()}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SupplierMetricCard(
                label: 'إجمالي الكمية',
                value: _formatQuantity(totalQuantity),
              ),
              _SupplierMetricCard(
                label: 'إجمالي السعر',
                value: totalRequired.egp,
              ),
              _SupplierMetricCard(
                label: 'إجمالي المدفوع',
                value: totalPaid.egp,
              ),
              _SupplierMetricCard(
                label: 'إجمالي المتبقي',
                value: totalRemaining.egp,
              ),
              _SupplierMetricCard(
                label: 'عدد الإضافات',
                value: '$invoiceCount',
              ),
              _SupplierMetricCard(label: 'عدد الدفعات', value: '$paymentCount'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddQuantity,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('إضافة كمية'),
              ),
              FilledButton.icon(
                onPressed: onAddPayment,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('إضافة دفعة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierMetricCard extends StatelessWidget {
  const _SupplierMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
