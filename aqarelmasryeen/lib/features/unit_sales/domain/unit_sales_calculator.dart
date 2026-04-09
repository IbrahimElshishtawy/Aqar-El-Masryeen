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
    required this.actualInstallmentsCount,
    required this.installmentScheduleCount,
    required this.missingInstallmentsCount,
    required this.duplicateInstallmentsCount,
    required this.extraInstallmentsCount,
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
  final int actualInstallmentsCount;
  final int installmentScheduleCount;
  final int missingInstallmentsCount;
  final int duplicateInstallmentsCount;
  final int extraInstallmentsCount;
  final int paidInstallmentsCount;
  final int unpaidInstallmentsCount;
  final int partiallyPaidInstallmentsCount;
  final int overdueInstallmentsCount;
  final double totalPaidInstallmentsAmount;
  final double totalRemainingInstallmentsAmount;
  final DateTime? projectedCompletionDate;
  final Duration remainingDuration;

  bool get isFullyPaid => totalRemaining <= 0;

  bool get hasInstallmentScheduleIssues =>
      missingInstallmentsCount > 0 ||
      duplicateInstallmentsCount > 0 ||
      extraInstallmentsCount > 0;
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
          .sorted((a, b) {
            final sequenceCompare = a.sequence.compareTo(b.sequence);
            if (sequenceCompare != 0) {
              return sequenceCompare;
            }
            final createdCompare = a.createdAt.compareTo(b.createdAt);
            if (createdCompare != 0) {
              return createdCompare;
            }
            return a.id.compareTo(b.id);
          });
      final unitPayments = payments
          .where((payment) => payment.unitId == unit.id)
          .sorted((a, b) => a.receivedAt.compareTo(b.receivedAt));

      final paymentsByInstallmentId = <String, List<PaymentRecord>>{};
      for (final payment in unitPayments) {
        final installmentId = payment.installmentId?.trim();
        if (installmentId == null || installmentId.isEmpty) {
          continue;
        }
        paymentsByInstallmentId.putIfAbsent(installmentId, () => []).add(payment);
      }

      final installmentsBySequence = <int, List<Installment>>{};
      for (final installment in unitInstallments) {
        installmentsBySequence.putIfAbsent(installment.sequence, () => []).add(
          installment,
        );
      }

      final configuredScheduleCount = unit.installmentScheduleCount > 0
          ? unit.installmentScheduleCount
          : installmentsBySequence.length;
      final visibleSequenceLimit = configuredScheduleCount > 0
          ? configuredScheduleCount
          : installmentsBySequence.length;
      final displaySequences = installmentsBySequence.keys
          .where((sequence) => visibleSequenceLimit == 0 || sequence <= visibleSequenceLimit)
          .sorted((a, b) => a.compareTo(b));

      final rows = displaySequences.map((sequence) {
        final groupedInstallments =
            installmentsBySequence[sequence] ?? const <Installment>[];
        final primaryInstallment = groupedInstallments.first;
        final rowPayments = groupedInstallments
            .expand(
              (installment) =>
                  paymentsByInstallmentId[installment.id] ?? const <PaymentRecord>[],
            )
            .sorted((a, b) => a.receivedAt.compareTo(b.receivedAt))
            .toList();
        final paidAmount = rowPayments.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
        final remainingAmount = (primaryInstallment.amount - paidAmount)
            .clamp(0, primaryInstallment.amount)
            .toDouble();
        final status = _statusFor(
          amountDue: primaryInstallment.amount,
          amountPaid: paidAmount,
          dueDate: primaryInstallment.dueDate,
        );

        return InstallmentComputedRow(
          installment: primaryInstallment.copyWith(
            paidAmount: paidAmount,
            status: status,
          ),
          payments: rowPayments,
          amountPaid: paidAmount,
          remainingAmount: remainingAmount,
          status: status,
        );
      }).toList();

      final duplicateInstallmentsCount = unitInstallments.length -
          installmentsBySequence.length;
      final extraInstallmentsCount = configuredScheduleCount > 0
          ? installmentsBySequence.keys
              .where((sequence) => sequence > configuredScheduleCount)
              .length
          : 0;
      final missingInstallmentsCount = configuredScheduleCount > rows.length
          ? configuredScheduleCount - rows.length
          : 0;
      final financedAmount = (unit.contractAmount - unit.downPayment)
          .clamp(0, unit.contractAmount)
          .toDouble();
      final estimatedInstallmentAmount = configuredScheduleCount <= 0
          ? 0.0
          : financedAmount / configuredScheduleCount;

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
          .length +
          missingInstallmentsCount;
      final totalPaidInstallmentsAmount = rows.fold<double>(
        0,
        (sum, row) => sum + row.amountPaid,
      );
      final totalRemainingInstallmentsAmount = rows.fold<double>(
        0,
        (sum, row) => sum + row.remainingAmount,
      ) +
      (missingInstallmentsCount * estimatedInstallmentAmount);
      final trackedUnitPayments = unitPayments.where((payment) {
        return !payment.isDownPayment;
      }).fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );
      final totalPaidSoFar = unit.downPayment + trackedUnitPayments;
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
        totalInstallmentsCount:
            configuredScheduleCount == 0 ? rows.length : configuredScheduleCount,
        actualInstallmentsCount: unitInstallments.length,
        installmentScheduleCount: configuredScheduleCount,
        missingInstallmentsCount: missingInstallmentsCount,
        duplicateInstallmentsCount: duplicateInstallmentsCount,
        extraInstallmentsCount: extraInstallmentsCount,
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
