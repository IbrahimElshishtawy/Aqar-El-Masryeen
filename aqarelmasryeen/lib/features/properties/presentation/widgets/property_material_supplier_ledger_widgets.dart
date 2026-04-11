// ignore_for_file: deprecated_member_use

part of '../property_material_supplier_screen.dart';

class _SupplierLedgerCompactCard extends StatelessWidget {
  const _SupplierLedgerCompactCard({
    required this.row,
    required this.rowNumber,
    this.onEditMaterial,
    this.onDeleteMaterial,
  });

  final _SupplierLedgerRow row;
  final int? rowNumber;
  final VoidCallback? onEditMaterial;
  final VoidCallback? onDeleteMaterial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPayment = row.isPayment;
    final accentColor = isPayment
        ? const Color(0xFF9A4F42)
        : const Color(0xFF2E6B3F);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E7DE)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _LedgerChip(
                          label: rowNumber == null
                              ? row.typeLabel
                              : '${row.typeLabel} #$rowNumber',
                          background: accentColor.withOpacity(0.12),
                          foreground: accentColor,
                        ),
                        _LedgerChip(label: row.displayDate.formatShort()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      row.description,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF17352F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'المتبقي',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      row.remainingAfter.egp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF17352F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerChip(label: 'المورد: ${row.supplierName}'),
              _LedgerChip(label: 'الكمية: ${row.quantityLabel}'),
              _LedgerChip(label: 'من دفع: ${row.paidByLabel}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LedgerValue(
                  label: isPayment ? 'قيمة الدفعة' : 'إجمالي الفاتورة',
                  value: row.priceLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LedgerValue(label: 'المدفوع', value: row.paidValue.egp),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LedgerValue(
                  label: 'المتبقي',
                  value: row.remainingAfter.egp,
                ),
              ),
            ],
          ),
          if (row.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              row.notes.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF40564F)),
            ),
          ],
          if (onEditMaterial != null || onDeleteMaterial != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                if (onEditMaterial != null)
                  OutlinedButton.icon(
                    onPressed: onEditMaterial,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('تعديل'),
                  ),
                if (onDeleteMaterial != null)
                  OutlinedButton.icon(
                    onPressed: onDeleteMaterial,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('حذف'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerChip extends StatelessWidget {
  const _LedgerChip({
    required this.label,
    this.background = const Color(0xFFF3F5F0),
    this.foreground = const Color(0xFF465145),
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 72;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth < 120 ? 120 : maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _LedgerValue extends StatelessWidget {
  const _LedgerValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E9DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF17352F),
            ),
          ),
        ],
      ),
    );
  }
}
