import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_presenters.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

class PropertyMaterialEntriesTable extends StatelessWidget {
  const PropertyMaterialEntriesTable({
    super.key,
    required this.title,
    required this.rows,
    required this.onEdit,
    required this.onDelete,
    this.onAdd,
    this.addLabel = 'إضافة فاتورة',
  });

  final String title;
  final List<MaterialExpenseEntry> rows;
  final VoidCallback? onAdd;
  final String addLabel;
  final ValueChanged<MaterialExpenseEntry> onEdit;
  final ValueChanged<MaterialExpenseEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final sortedRows = [...rows]..sort((a, b) => b.date.compareTo(a.date));
    final total = sortedRows.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final paid = sortedRows.fold<double>(
      0,
      (sum, item) => sum + item.amountPaid,
    );
    final remaining = sortedRows.fold<double>(
      0,
      (sum, item) => sum + item.amountRemaining,
    );

    return FinancialLedgerTable<MaterialExpenseEntry>(
      title: title,
      subtitle: '${sortedRows.length} صف - الإجمالي ${total.egp}',
      rows: sortedRows,
      onAdd: onAdd,
      addLabel: addLabel,
      onEdit: onEdit,
      onDelete: onDelete,
      sheetLabel: title,
      columns: [
        LedgerColumn(
          label: 'التاريخ',
          valueBuilder: (row) => Text(row.date.formatShort()),
          minWidth: 116,
        ),
        LedgerColumn(
          label: 'الصنف',
          valueBuilder: (row) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(row.itemName, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                row.materialCategory.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          minWidth: 180,
        ),
        LedgerColumn(
          label: 'الكمية',
          valueBuilder: (row) => Text(row.quantity.toStringAsFixed(0)),
          minWidth: 92,
          numeric: true,
        ),
        LedgerColumn(
          label: 'المورد',
          valueBuilder: (row) => Text(row.supplierName),
          minWidth: 170,
        ),
        LedgerColumn(
          label: 'سعر الوحدة',
          valueBuilder: (row) => Text(row.unitPrice.egp),
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
          label: 'المدفوع',
          valueBuilder: (row) => Text(row.amountPaid.egp),
          minWidth: 116,
          numeric: true,
        ),
        LedgerColumn(
          label: 'المتبقي',
          valueBuilder: (row) => Text(row.amountRemaining.egp),
          minWidth: 116,
          numeric: true,
        ),
        LedgerColumn(
          label: 'الحالة',
          valueBuilder: (row) => FinancialStatusChip(
            label: row.status.label,
            color: supplierInvoiceStatusColor(row.status),
          ),
          minWidth: 126,
        ),
      ],
      totalsFooter: LedgerTotalsFooter(
        children: [
          LedgerFooterValue(label: 'إجمالي المشتريات', value: total.egp),
          LedgerFooterValue(label: 'إجمالي المدفوع', value: paid.egp),
          LedgerFooterValue(label: 'إجمالي المتبقي', value: remaining.egp),
        ],
      ),
    );
  }
}
