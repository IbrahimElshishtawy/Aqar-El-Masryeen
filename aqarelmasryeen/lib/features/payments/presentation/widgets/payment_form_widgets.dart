part of '../payment_form_sheet.dart';

class _PaymentInfoBanner extends StatelessWidget {
  const _PaymentInfoBanner({
    required this.unitLabel,
    required this.customerName,
  });

  final String unitLabel;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final resolvedCustomerName = customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : customerName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الوحدة $unitLabel',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            resolvedCustomerName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يتم تسجيل كل مبلغ يدويًا، ولن يتم احتساب أي قسط أو دفعة تلقائيًا بدون إدخال صريح منك.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF55655F),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedInstallmentCard extends StatelessWidget {
  const _SelectedInstallmentCard({required this.row});

  final InstallmentComputedRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'القسط ${row.installment.sequence}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D5140),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'الاستحقاق ${row.installment.dueDate.formatShort()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'قيمة القسط ${row.installment.amount.egp} - المدفوع ${row.amountPaid.egp} - المتبقي ${row.remainingAmount.egp}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
