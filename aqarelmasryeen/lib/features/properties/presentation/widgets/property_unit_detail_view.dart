import 'package:aqarelmasryeen/core/extensions/date_extensions.dart';
import 'package:aqarelmasryeen/core/extensions/number_extensions.dart';
import 'package:aqarelmasryeen/features/properties/presentation/controllers/property_detail_controller.dart';
import 'package:aqarelmasryeen/features/properties/presentation/property_detail_presenters.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/financial_ledger_table.dart';
import 'package:aqarelmasryeen/features/properties/presentation/widgets/property_unit_expenses_section.dart';
import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:flutter/material.dart';

class PropertyUnitDetailView extends StatelessWidget {
  const PropertyUnitDetailView({
    super.key,
    required this.data,
    required this.onEditUnit,
    required this.onDeleteUnit,
    required this.onAddInstallment,
    required this.onEditInstallment,
    required this.onDeleteInstallment,
    required this.onViewInstallmentPayments,
    required this.onAddPayment,
    required this.onAddUnitExpense,
    required this.onEditUnitExpense,
    required this.onDeleteUnitExpense,
    required this.onOpenUnitExpenses,
    required this.onEditPayment,
    required this.onDeletePayment,
  });

  final PropertyUnitViewData data;
  final VoidCallback onEditUnit;
  final VoidCallback onDeleteUnit;
  final VoidCallback onAddInstallment;
  final ValueChanged<Installment> onEditInstallment;
  final ValueChanged<Installment> onDeleteInstallment;
  final ValueChanged<InstallmentComputedRow> onViewInstallmentPayments;
  final ValueChanged<String> onAddPayment;
  final VoidCallback onAddUnitExpense;
  final ValueChanged<UnitExpenseRecord> onEditUnitExpense;
  final ValueChanged<UnitExpenseRecord> onDeleteUnitExpense;
  final VoidCallback onOpenUnitExpenses;
  final ValueChanged<PaymentRecord> onEditPayment;
  final ValueChanged<PaymentRecord> onDeletePayment;

  @override
  Widget build(BuildContext context) {
    final summary = data.summary;
    final projectedCompletion = summary.projectedCompletionDate == null
        ? 'غير محدد'
        : summary.projectedCompletionDate!.formatShort();
    final installmentLabels = {
      for (final row in summary.installmentRows)
        row.installment.id: 'قسط ${row.installment.sequence}',
    };
    final userNamesById = <String, String>{
      for (final partner in data.partners)
        if (partner.userId.trim().isNotEmpty) partner.userId: partner.name,
      if (data.currentUserId != null && data.currentUserId!.trim().isNotEmpty)
        data.currentUserId!: data.currentUserDisplayName,
    };
    final recordedPaymentsTotal = data.payments.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionHeading(
          title: 'بيانات الوحدة',
          subtitle: 'تفاصيل الوحدة الأساسية وبيانات العميل.',
        ),
        const SizedBox(height: 10),
        _UnitHeroCard(
          data: data,
          onEditUnit: onEditUnit,
          onDeleteUnit: onDeleteUnit,
        ),
        const SizedBox(height: 18),
        const _SectionHeading(
          title: 'الملخص المالي',
          subtitle:
              'بطاقات شبكية صغيرة توضح التعاقد والمدفوع والمتبقي بوضوح على كل الشاشات.',
        ),
        const SizedBox(height: 10),
        _ResponsiveMetricGrid(
          children: [
            _FinancialMiniCard(
              label: 'قيمة التعاقد النهائية',
              value: summary.totalContractAmount.egp,
              subtitle: 'سعر الشقة المعتمد',
              icon: Icons.description_outlined,
              highlight: true,
            ),
            _FinancialMiniCard(
              label: 'المقدم',
              value: summary.unit.downPayment.egp,
              subtitle: 'المسجل على الوحدة',
              icon: Icons.account_balance_wallet_outlined,
            ),
            _FinancialMiniCard(
              label: 'إجمالي المدفوع',
              value: summary.totalPaidSoFar.egp,
              subtitle: 'المقدم + الدفعات المسجلة',
              icon: Icons.payments_outlined,
            ),
            _FinancialMiniCard(
              label: 'المتبقي',
              value: summary.totalRemaining.egp,
              subtitle: '${summary.unpaidInstallmentsCount} قسطًا غير مسدد',
              icon: Icons.schedule_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SupplementaryInfoCard(
              label: 'إنهاء الأقساط',
              value: projectedCompletion,
              subtitle: summary.remainingDuration.inDays <= 0
                  ? 'مستحق الآن أو مكتمل'
                  : '${summary.remainingDuration.inDays} يومًا متبقيًا',
              icon: Icons.event_available_outlined,
            ),
            _SupplementaryInfoCard(
              label: 'حالة الوحدة',
              value: unitAlertLabelForSummary(summary),
              subtitle:
                  '${summary.paidInstallmentsCount}/${summary.totalInstallmentsCount} أقساط مدفوعة',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
        if (summary.unit.downPayment > 0 && data.payments.isEmpty) ...[
          const SizedBox(height: 12),
          const _InlineNoticeCard(
            message:
                'المقدم مسجل على الوحدة، لكن لم يتم تسجيل أي دفعات إضافية أو أقساط حتى الآن.',
          ),
        ],
        if (summary.missingInstallmentsCount > 0) ...[
          const SizedBox(height: 12),
          _InlineNoticeCard(
            message:
                'متبقي تسجيل ${summary.missingInstallmentsCount} أقساط يدويًا مع تاريخ الاستحقاق لكل قسط.',
          ),
        ],
        if (summary.hasInstallmentScheduleIssues) ...[
          const SizedBox(height: 12),
          _InlineNoticeCard(
            tone: _NoticeTone.warning,
            message:
                'تم اكتشاف تكرار أو صفوف أقساط إضافية داخل الشيت الحالي. راجع الصفوف الحالية وتأكد من بقاء كل قسط مرة واحدة فقط.',
          ),
        ],
        const SizedBox(height: 18),
        const _SectionHeading(
          title: 'مصاريف الوحدة',
          subtitle:
              'جزء مستقل لتسجيل ومراجعة كل المصروفات الخاصة بهذه الوحدة فقط بين المستخدم والشريك.',
        ),
        const SizedBox(height: 10),
        PropertyUnitExpensesSection(
          data: data,
          previewLimit: 5,
          onShowMore: onOpenUnitExpenses,
          onAddExpense: onAddUnitExpense,
          onEditExpense: onEditUnitExpense,
          onDeleteExpense: onDeleteUnitExpense,
        ),
        const SizedBox(height: 18),
        const _SectionHeading(
          title: 'سجل الدفعات',
          subtitle: 'كل دفعة محفوظة تظهر هنا فورًا وتؤثر على المدفوع والمتبقي.',
        ),
        const SizedBox(height: 10),
        FinancialLedgerTable<PaymentRecord>(
          title: 'سجل الدفعات',
          subtitle:
              '${data.payments.length} دفعة مسجلة - الإجمالي ${recordedPaymentsTotal.egp}',
          rows: data.payments,
          forceTableLayout: true,
          sheetLabel: 'سجل الدفعات',
          emptyTitle: 'لم يتم تسجيل أي دفعات حتى الآن',
          emptyMessage:
              'بمجرد إضافة أول دفعة ستظهر هنا مباشرة مع القسط المرتبط والمستخدم الذي قام بالتسجيل.',
          onEdit: onEditPayment,
          onDelete: onDeletePayment,
          onAdd: () => onAddPayment(''),
          addLabel: 'إضافة دفعة',
          compactCardBuilder: (context, row, rowNumber, actions) {
            return _PaymentCompactCard(
              row: row,
              rowNumber: rowNumber,
              installmentLabel: row.installmentId == null
                  ? 'بدون ربط'
                  : (installmentLabels[row.installmentId!] ?? 'دفعة خاصة'),
              createdByLabel:
                  userNamesById[row.createdBy] ??
                  (row.createdBy == data.currentUserId
                      ? data.currentUserDisplayName
                      : 'مستخدم غير محدد'),
              actions: actions,
            );
          },
          columns: [
            LedgerColumn(
              label: 'التاريخ',
              valueBuilder: (row) => Text(row.receivedAt.formatShort()),
              minWidth: 118,
            ),
            LedgerColumn(
              label: 'المبلغ',
              valueBuilder: (row) => Text(row.amount.egp),
              minWidth: 128,
              numeric: true,
            ),
            LedgerColumn(
              label: 'نوع الدفعة',
              valueBuilder: (row) => Text(row.paymentTypeLabel),
              minWidth: 128,
            ),
            LedgerColumn(
              label: 'القسط المرتبط',
              valueBuilder: (row) => Text(
                row.installmentId == null
                    ? 'بدون ربط'
                    : (installmentLabels[row.installmentId!] ?? 'دفعة خاصة'),
              ),
              minWidth: 132,
            ),
            LedgerColumn(
              label: 'أضافها',
              valueBuilder: (row) => Text(
                userNamesById[row.createdBy] ??
                    (row.createdBy == data.currentUserId
                        ? data.currentUserDisplayName
                        : 'مستخدم غير محدد'),
              ),
              minWidth: 150,
            ),
            LedgerColumn(
              label: 'ملاحظات',
              valueBuilder: (row) =>
                  Text(row.notes.trim().isEmpty ? '-' : row.notes.trim()),
              minWidth: 180,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionHeading(
          title: 'شيت الأقساط',
          subtitle:
              'كل قسط يضاف بتاريخ استحقاق يدوي يحدده المستخدم ويرتبط بالدفعات المسجلة.',
        ),
        const SizedBox(height: 10),
        FinancialLedgerTable<InstallmentComputedRow>(
          title: 'شيت أقساط الوحدة',
          subtitle:
              '${summary.installmentRows.length} صف مسجل من ${summary.installmentScheduleCount} - المتبقي الكلي ${summary.totalRemaining.egp}',
          rows: summary.installmentRows,
          forceTableLayout: true,
          emptyTitle: 'لا توجد أقساط جاهزة بعد',
          emptyMessage: summary.installmentScheduleCount > 0
              ? 'أضف الأقساط يدويًا وحدد تاريخ كل قسط من زر "إضافة قسط".'
              : 'أدخل عدد الأقساط أولًا أو أضف قسطًا يدويًا إذا كانت الوحدة تعمل بنظام مخصص.',
          onAdd: onAddInstallment,
          addLabel: 'إضافة قسط',
          onView: onViewInstallmentPayments,
          onEdit: (row) => onEditInstallment(row.installment),
          onDelete: (row) => onDeleteInstallment(row.installment),
          sheetLabel: 'شيت أقساط الوحدة',
          compactCardBuilder: (context, row, rowNumber, actions) {
            return _InstallmentCompactCard(
              row: row,
              rowNumber: rowNumber,
              actions: actions,
            );
          },
          columns: [
            LedgerColumn(
              label: 'رقم القسط',
              valueBuilder: (row) => Text('${row.installment.sequence}'),
              minWidth: 86,
              numeric: true,
            ),
            LedgerColumn(
              label: 'تاريخ الاستحقاق',
              valueBuilder: (row) =>
                  Text(row.installment.dueDate.formatShort()),
              minWidth: 122,
            ),
            LedgerColumn(
              label: 'قيمة القسط',
              valueBuilder: (row) => Text(row.installment.amount.egp),
              minWidth: 126,
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
              valueBuilder: (row) => Text(row.remainingAmount.egp),
              minWidth: 120,
              numeric: true,
            ),
            LedgerColumn(
              label: 'الحالة',
              valueBuilder: (row) => FinancialStatusChip(
                label: row.status.label,
                color: row.status == InstallmentStatus.paid
                    ? Colors.green
                    : row.status == InstallmentStatus.partiallyPaid
                    ? Colors.orange
                    : row.status == InstallmentStatus.overdue
                    ? Colors.redAccent
                    : Colors.blueGrey,
              ),
              minWidth: 128,
            ),
          ],
          totalsFooter: LedgerTotalsFooter(
            children: [
              LedgerFooterValue(
                label: 'الأقساط المخططة',
                value: '${summary.installmentScheduleCount}',
              ),
              LedgerFooterValue(
                label: 'الأقساط المسجلة',
                value: '${summary.installmentRows.length}',
              ),
              LedgerFooterValue(
                label: 'مدفوع بالكامل',
                value: '${summary.paidInstallmentsCount}',
              ),
              LedgerFooterValue(
                label: 'متأخر',
                value: '${summary.overdueInstallmentsCount}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF17352F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}

enum _NoticeTone { neutral, warning }

class _InlineNoticeCard extends StatelessWidget {
  const _InlineNoticeCard({
    required this.message,
    this.tone = _NoticeTone.neutral,
  });

  final String message;
  final _NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final background = tone == _NoticeTone.warning
        ? const Color(0xFFFFF5E8)
        : const Color(0xFFF7F8F4);
    final border = tone == _NoticeTone.warning
        ? const Color(0xFFE7C88A)
        : const Color(0xFFD8D8D2);
    final iconColor = tone == _NoticeTone.warning
        ? const Color(0xFF8B5E00)
        : const Color(0xFF2E6B3F);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF24413A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialMiniCard extends StatelessWidget {
  const _FinancialMiniCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final isTight = constraints.maxWidth < 145;
        final padding = isCompact ? 12.0 : 14.0;
        final iconPadding = isTight ? 6.0 : 7.0;
        final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w700,
          height: 1.2,
          fontSize: isTight ? 11 : null,
        );
        final valueStyle =
            (isCompact
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17352F),
                  height: 1.05,
                );

        return Container(
          decoration: BoxDecoration(
            color: highlight
                ? const Color(0xFFEFF6EE)
                : const Color(0xFFFDFDF9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? const Color(0xFFCFE2CD)
                  : const Color(0xFFD8D8D2),
            ),
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EFE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isTight ? 16 : 17,
                  color: const Color(0xFF2E6B3F),
                ),
              ),
              SizedBox(height: isCompact ? 10 : 12),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              const Spacer(),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF55655F),
                  height: 1.2,
                  fontSize: isTight ? 11 : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SupplementaryInfoCard extends StatelessWidget {
  const _SupplementaryInfoCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190, maxWidth: 360),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EFE3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2E6B3F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF17352F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF55655F),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : constraints.maxWidth >= 300
            ? 2
            : 1;
        final ratio = count == 1
            ? 1.2
            : constraints.maxWidth < 360
            ? 0.72
            : constraints.maxWidth < 420
            ? 0.82
            : constraints.maxWidth < 760
            ? 0.94
            : 1.08;
        return GridView.count(
          crossAxisCount: count,
          childAspectRatio: ratio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: children,
        );
      },
    );
  }
}

class _PaymentCompactCard extends StatelessWidget {
  const _PaymentCompactCard({
    required this.row,
    required this.rowNumber,
    required this.installmentLabel,
    required this.createdByLabel,
    required this.actions,
  });

  final PaymentRecord row;
  final int? rowNumber;
  final String installmentLabel;
  final String createdByLabel;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rowNumber != null)
                Text(
                  'دفعة #$rowNumber',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E6B3F),
                  ),
                ),
              const Spacer(),
              Text(
                row.amount.egp,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17352F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniChip(label: row.paymentTypeLabel),
              _MiniChip(label: installmentLabel),
              _MiniChip(label: row.receivedAt.formatShort()),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(label: 'أضافها', value: createdByLabel),
          _InfoLine(
            label: 'ملاحظات',
            value: row.notes.trim().isEmpty ? 'بدون ملاحظات' : row.notes.trim(),
          ),
          if (actions != null) ...[const SizedBox(height: 8), actions!],
        ],
      ),
    );
  }
}

class _InstallmentCompactCard extends StatelessWidget {
  const _InstallmentCompactCard({
    required this.row,
    required this.rowNumber,
    required this.actions,
  });

  final InstallmentComputedRow row;
  final int? rowNumber;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final statusColor = row.status == InstallmentStatus.paid
        ? Colors.green
        : row.status == InstallmentStatus.partiallyPaid
        ? Colors.orange
        : row.status == InstallmentStatus.overdue
        ? Colors.redAccent
        : Colors.blueGrey;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'قسط ${row.installment.sequence}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF17352F),
                ),
              ),
              const Spacer(),
              FinancialStatusChip(label: row.status.label, color: statusColor),
            ],
          ),
          if (rowNumber != null) ...[
            const SizedBox(height: 6),
            Text(
              'صف $rowNumber',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MiniStat(
                label: 'الاستحقاق',
                value: row.installment.dueDate.formatShort(),
              ),
              _MiniStat(label: 'قيمة القسط', value: row.installment.amount.egp),
              _MiniStat(label: 'المدفوع', value: row.amountPaid.egp),
              _MiniStat(label: 'المتبقي', value: row.remainingAmount.egp),
            ],
          ),
          if (actions != null) ...[const SizedBox(height: 8), actions!],
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF465145),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
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
            maxLines: 2,
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF40564F)),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _UnitHeroCard extends StatelessWidget {
  const _UnitHeroCard({
    required this.data,
    required this.onEditUnit,
    required this.onDeleteUnit,
  });

  final PropertyUnitViewData data;
  final VoidCallback onEditUnit;
  final VoidCallback onDeleteUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = data.summary.unit;
    final customerName = unit.customerName.trim().isEmpty
        ? 'عميل غير محدد'
        : unit.customerName;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD8D8D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوحدة ${unit.unitNumber}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${data.property.name} • ${data.property.location}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      customerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<VoidCallback>(
                iconColor: theme.colorScheme.onSurface,
                onSelected: (callback) => callback(),
                itemBuilder: (_) => [
                  PopupMenuItem<VoidCallback>(
                    value: onEditUnit,
                    child: const Text('تعديل الوحدة'),
                  ),
                  PopupMenuItem<VoidCallback>(
                    value: onDeleteUnit,
                    child: const Text('حذف الوحدة'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _UnitInfoTable(
            rows: [
              MapEntry(
                'الهاتف',
                unit.customerPhone.trim().isEmpty ? '-' : unit.customerPhone,
              ),
              MapEntry('النوع', unit.unitType.label),
              MapEntry('الدور', '${unit.floor}'),
              MapEntry('المساحة', '${formatUnitArea(unit.area)} م²'),
              MapEntry('نظام السداد', unit.paymentPlanType.label),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FinancialStatusChip(
                label: unit.status.label,
                color: unitStatusColor(unit.status),
              ),
              FinancialStatusChip(
                label: unitAlertLabelForSummary(data.summary),
                color: unitAlertColorForSummary(data.summary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitInfoTable extends StatelessWidget {
  const _UnitInfoTable({required this.rows});

  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8D8D2)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.15),
          1: FlexColumnWidth(1.85),
        },
        children: [
          for (var index = 0; index < rows.length; index++)
            TableRow(
              decoration: BoxDecoration(
                border: index == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFD8D8D2)),
                      ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    rows[index].key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Text(
                    rows[index].value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
