import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';
import 'package:collection/collection.dart';

class InstallmentComputedRow {
  const InstallmentComputedRow({
    required this.installment,
    required this.payments,
    required this.amountPaid,
    required this.remainingAmount,
    required this.status,
  });

  final Installment installment;
  final List<PaymentRecord> payments;
  final double amountPaid;
  final double remainingAmount;
  final InstallmentStatus status;

  String get payerSummary {
    final names = payments
        .map((payment) => payment.effectivePayerName)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) {
      return '-';
    }
    return names.join(', ');
  }
}

class UnitSaleComputedSummary {
  const UnitSaleComputedSummary({
    required this.unit,
    required this.installmentRows,
    required this.totalContractAmount,
    required this.totalPaidSoFar,
    required this.totalRemaining,
    required this.totalInstallmentsCount,
    required this.installmentScheduleCount,
    required this.paidInstallmentsCount,
    required this.unpaidInstallmentsCount,
    required this.partiallyPaidInstallmentsCount,
    required this.overdueInstallmentsCount,
    required this.totalPaidInstallmentsAmount,
    required this.totalRemainingInstallmentsAmount,
    required this.projectedCompletionDate,
    required this.remainingDuration,
  });

  final UnitSale unit;
  final List<InstallmentComputedRow> installmentRows;
  final double totalContractAmount;
  final double totalPaidSoFar;
  final double totalRemaining;
  final int totalInstallmentsCount;
  final int installmentScheduleCount;
  final int paidInstallmentsCount;
  final int unpaidInstallmentsCount;
  final int partiallyPaidInstallmentsCount;
  final int overdueInstallmentsCount;
  final double totalPaidInstallmentsAmount;
  final double totalRemainingInstallmentsAmount;
  final DateTime? projectedCompletionDate;
  final Duration remainingDuration;

  bool get isFullyPaid => totalRemaining <= 0;
}

class UnitSalesCalculator {
  const UnitSalesCalculator();

  List<UnitSaleComputedSummary> build({
    required List<UnitSale> units,
    required List<Installment> installments,
    required List<PaymentRecord> payments,
  }) {
    return units.map((unit) {
      final unitInstallments = installments
          .where((installment) => installment.unitId == unit.id)
          .sorted((a, b) => a.sequence.compareTo(b.sequence));
      final unitPayments = payments
          .where((payment) => payment.unitId == unit.id)
          .sorted((a, b) => a.receivedAt.compareTo(b.receivedAt));

      final rows = unitInstallments.map((installment) {
        final rowPayments = unitPayments
            .where((payment) => payment.installmentId == installment.id)
            .toList();
        final paidAmount = rowPayments.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
        final remainingAmount = (installment.amount - paidAmount)
            .clamp(0, installment.amount)
            .toDouble();
        final status = _statusFor(
          amountDue: installment.amount,
          amountPaid: paidAmount,
          dueDate: installment.dueDate,
        );

        return InstallmentComputedRow(
          installment: installment,
          payments: rowPayments,
          amountPaid: paidAmount,
          remainingAmount: remainingAmount,
          status: status,
        );
      }).toList();

      final paidInstallmentsCount = rows
          .where((row) => row.status == InstallmentStatus.paid)
          .length;
      final partiallyPaidInstallmentsCount = rows
          .where((row) => row.status == InstallmentStatus.partiallyPaid)
          .length;
      final overdueInstallmentsCount = rows
          .where((row) => row.status == InstallmentStatus.overdue)
          .length;
      final unpaidInstallmentsCount = rows
          .where((row) => row.status == InstallmentStatus.pending)
          .length;
      final totalPaidInstallmentsAmount = rows.fold<double>(
        0,
        (sum, row) => sum + row.amountPaid,
      );
      final totalRemainingInstallmentsAmount = rows.fold<double>(
        0,
        (sum, row) => sum + row.remainingAmount,
      );
      final totalPaidSoFar = unit.downPayment + totalPaidInstallmentsAmount;
      final totalContractAmount = unit.contractAmount;
      final totalRemaining = (totalContractAmount - totalPaidSoFar)
          .clamp(0, totalContractAmount)
          .toDouble();
      final projectedCompletionDate = _projectedCompletionDate(rows, unit);
      final remainingDuration = projectedCompletionDate == null
          ? Duration.zero
          : projectedCompletionDate.difference(DateTime.now());

      return UnitSaleComputedSummary(
        unit: unit,
        installmentRows: rows,
        totalContractAmount: totalContractAmount,
        totalPaidSoFar: totalPaidSoFar,
        totalRemaining: totalRemaining,
        totalInstallmentsCount: rows.length,
        installmentScheduleCount: unit.installmentScheduleCount == 0
            ? rows.length
            : unit.installmentScheduleCount,
        paidInstallmentsCount: paidInstallmentsCount,
        unpaidInstallmentsCount: unpaidInstallmentsCount,
        partiallyPaidInstallmentsCount: partiallyPaidInstallmentsCount,
        overdueInstallmentsCount: overdueInstallmentsCount,
        totalPaidInstallmentsAmount: totalPaidInstallmentsAmount,
        totalRemainingInstallmentsAmount: totalRemainingInstallmentsAmount,
        projectedCompletionDate: projectedCompletionDate,
        remainingDuration: remainingDuration.isNegative
            ? Duration.zero
            : remainingDuration,
      );
    }).toList();
  }

  InstallmentStatus _statusFor({
    required double amountDue,
    required double amountPaid,
    required DateTime dueDate,
  }) {
    if (amountPaid >= amountDue) {
      return InstallmentStatus.paid;
    }
    if (amountPaid > 0) {
      return InstallmentStatus.partiallyPaid;
    }
    if (dueDate.isBefore(DateTime.now())) {
      return InstallmentStatus.overdue;
    }
    return InstallmentStatus.pending;
  }

  DateTime? _projectedCompletionDate(
    List<InstallmentComputedRow> rows,
    UnitSale unit,
  ) {
    if (rows.isEmpty) {
      return unit.projectedCompletionDate;
    }

    final unpaidRows = rows.where((row) => row.remainingAmount > 0).toList();
    if (unpaidRows.isEmpty) {
      return rows.last.installment.dueDate;
    }

    final futureDueDate = unpaidRows
        .map((row) => row.installment.dueDate)
        .sorted((a, b) => a.compareTo(b))
        .lastOrNull;
    return futureDueDate ?? unit.projectedCompletionDate;
  }
}
