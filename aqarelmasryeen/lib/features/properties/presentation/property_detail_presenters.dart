import 'package:aqarelmasryeen/features/unit_sales/domain/unit_sales_calculator.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:flutter/material.dart';

int dueSoonInstallmentsCountForSummary(UnitSaleComputedSummary summary) {
  return summary.installmentRows.where((row) {
    if (row.status != InstallmentStatus.pending) {
      return false;
    }
    final daysUntilDue = row.installment.dueDate
        .difference(DateTime.now())
        .inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 7;
  }).length;
}

String unitAlertLabelForSummary(UnitSaleComputedSummary summary) {
  if (summary.overdueInstallmentsCount > 0) {
    return '${summary.overdueInstallmentsCount} متأخر';
  }
  final dueSoonCount = dueSoonInstallmentsCountForSummary(summary);
  if (dueSoonCount > 0) {
    return '$dueSoonCount قريب';
  }
  if (summary.isFullyPaid) {
    return 'مكتمل';
  }
  return 'مستقر';
}

Color unitAlertColorForSummary(UnitSaleComputedSummary summary) {
  if (summary.overdueInstallmentsCount > 0) {
    return Colors.redAccent;
  }
  if (dueSoonInstallmentsCountForSummary(summary) > 0) {
    return Colors.orange;
  }
  if (summary.isFullyPaid) {
    return Colors.green;
  }
  return Colors.blueGrey;
}

String installmentAlertLabelForRow(InstallmentComputedRow row) {
  if (row.status == InstallmentStatus.overdue) {
    return 'متأخر';
  }
  if (row.status == InstallmentStatus.paid) {
    return 'تم السداد';
  }
  final daysUntilDue = row.installment.dueDate
      .difference(DateTime.now())
      .inDays;
  if (daysUntilDue >= 0 && daysUntilDue <= 7) {
    return 'قريب';
  }
  return 'متابعة';
}

Color installmentAlertColorForRow(InstallmentComputedRow row) {
  if (row.status == InstallmentStatus.overdue) {
    return Colors.redAccent;
  }
  if (row.status == InstallmentStatus.paid) {
    return Colors.green;
  }
  final daysUntilDue = row.installment.dueDate
      .difference(DateTime.now())
      .inDays;
  if (daysUntilDue >= 0 && daysUntilDue <= 7) {
    return Colors.orange;
  }
  return Colors.blueGrey;
}

String formatUnitArea(double area) {
  final hasFraction = area.truncateToDouble() != area;
  return area.toStringAsFixed(hasFraction ? 1 : 0);
}

Color unitStatusColor(UnitStatus status) {
  switch (status) {
    case UnitStatus.available:
      return Colors.blueGrey;
    case UnitStatus.reserved:
      return Colors.orange;
    case UnitStatus.sold:
      return Colors.green;
    case UnitStatus.cancelled:
      return Colors.redAccent;
  }
}

Color supplierInvoiceStatusColor(SupplierInvoiceStatus status) {
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

String payerNamesSummary(UnitSaleComputedSummary summary) {
  final names = summary.installmentRows
      .map((row) => row.payerSummary)
      .where((name) => name != '-')
      .toSet()
      .toList();
  if (names.isEmpty) {
    return '-';
  }
  return names.join('، ');
}
