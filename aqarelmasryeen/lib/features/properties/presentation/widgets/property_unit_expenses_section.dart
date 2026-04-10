import 'dart:math' as math;

import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/core/widgets/app_panel.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

import 'financial_ledger_table.dart';

class PropertyUnitExpensesSection extends StatelessWidget {
  const PropertyUnitExpensesSection({
    super.key,
    required this.data,
    required this.onAddExpense,
    required this.onEditExpense,
    required this.onDeleteExpense,
    this.onShowMore,
    this.previewLimit,
  });

  final PropertyUnitViewData data;
  final VoidCallback onAddExpense;
  final ValueChanged<UnitExpenseRecord> onEditExpense;
  final ValueChanged<UnitExpenseRecord> onDeleteExpense;
  final VoidCallback? onShowMore;
  final int? previewLimit;

  @override
  Widget build(BuildContext context) {
    final visibleExpenses = previewLimit == null
        ? data.unitExpenses
        : data.unitExpenses.take(previewLimit!).toList(growable: false);
    final rows = visibleExpenses
        .map(
          (expense) => _UnitExpenseTableRow(
            expense: expense,
            payerLabel: data.payerLabelForUnitExpense(expense),
          ),
        )
        .toList(growable: false);
    final hasMoreRows =
        previewLimit != null && data.unitExpenses.length > previewLimit!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPanel(
          title: 'ملخص مصروفات الوحدة',
          subtitle:
              'الإجماليات هنا محسوبة من كل المصروفات المسجلة على هذه الوحدة بين المستخدم والشريك.',
          child: _UnitExpenseMetricsGrid(
            children: [
              _UnitExpenseMetricCard(
                label: 'إجمالي ${data.currentColumnLabel}',
                value: data.currentUserUnitExpensesTotal.egp,
                helper:
                    'كل ما دفعه ${data.currentColumnLabel} داخل هذه الوحدة.',
                icon: Icons.person_outline,
                tint: const Color(0xFFEAF4EF),
                border: const Color(0xFFD2E3D7),
              ),
              _UnitExpenseMetricCard(
                label: 'إجمالي ${data.counterpartColumnLabel}',
                value: data.counterpartUnitExpensesTotal.egp,
                helper:
                    'كل ما دفعه ${data.counterpartColumnLabel} داخل هذه الوحدة.',
                icon: Icons.groups_2_outlined,
                tint: const Color(0xFFF6F4EF),
                border: const Color(0xFFE2DDD3),
              ),
              _UnitExpenseMetricCard(
                label: 'عدد المصروفات',
                value: '${data.unitExpensesCount}',
                helper: 'عدد السجلات المرتبطة بهذه الوحدة فقط.',
                icon: Icons.receipt_long_outlined,
                tint: const Color(0xFFF4F6F1),
                border: const Color(0xFFD8DED4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FinancialLedgerTable<_UnitExpenseTableRow>(
          title: previewLimit == null
              ? 'سجل مصروفات الوحدة'
              : 'آخر مصروفات الوحدة',
          subtitle: previewLimit == null
              ? 'يعرض كل العمليات المسجلة على الوحدة مع إمكانية الإضافة والتعديل والحذف.'
              : 'يعرض آخر ${previewLimit!} عمليات فقط. استخدم عرض المزيد لفتح السجل الكامل.',
          rows: rows,
          forceTableLayout: true,
          headerTrailing: hasMoreRows && onShowMore != null
              ? TextButton(
                  onPressed: onShowMore,
                  child: const Text('عرض المزيد'),
                )
              : null,
          onAdd: onAddExpense,
          addLabel: 'إضافة مصروف',
          onEdit: (row) => onEditExpense(row.expense),
          onDelete: (row) => onDeleteExpense(row.expense),
          sheetLabel: previewLimit == null
              ? 'سجل مصروفات الوحدة'
              : 'آخر ${rows.length} عمليات للوحدة',
          emptyTitle: 'لا توجد مصروفات مسجلة بعد',
          emptyMessage: previewLimit == null
              ? 'بمجرد إضافة أول مصروف لهذه الوحدة سيظهر هنا مع إمكانية التعديل والحذف.'
              : 'لا توجد عمليات حديثة لهذه الوحدة حتى الآن.',
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.expense.date.formatShort()),
              minWidth: 120,
            ),
            LedgerColumn(
              label: 'البيان / الوصف',
              valueBuilder: (row) => Text(
                row.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 220,
            ),
            LedgerColumn(
              label: 'المبلغ',
              valueBuilder: (row) => Text(row.expense.amount.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'من الذي دفع',
              valueBuilder: (row) => Text(row.payerLabel),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) => Text(
                row.notesLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              minWidth: 180,
            ),
          ],
        ),
      ],
    );
  }
}

class _UnitExpenseTableRow {
  const _UnitExpenseTableRow({required this.expense, required this.payerLabel});

  final UnitExpenseRecord expense;
  final String payerLabel;

  String get description {
    final description = expense.description.trim();
    if (description.isNotEmpty) {
      return description;
    }
    final notes = expense.notes.trim();
    return notes.isEmpty ? '-' : notes;
  }

  String get notesLabel {
    final notes = expense.notes.trim();
    return notes.isEmpty ? '-' : notes;
  }
}

class _UnitExpenseMetricsGrid extends StatelessWidget {
  const _UnitExpenseMetricsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 880
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        final spacing = 12.0;
        final totalSpacing = math.max(0, columns - 1) * spacing;
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth.clamp(0, constraints.maxWidth),
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _UnitExpenseMetricCard extends StatelessWidget {
  const _UnitExpenseMetricCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.tint,
    required this.border,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color tint;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF17352F)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF17352F),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
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
