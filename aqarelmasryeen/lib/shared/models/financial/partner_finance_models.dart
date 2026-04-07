import 'package:aqarelmasryeen/core/utils/firestore_parser.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';

class PartnerLedgerEntry {
  const PartnerLedgerEntry({
    required this.id,
    required this.partnerId,
    required this.propertyId,
    required this.entryType,
    required this.amount,
    required this.notes,
    required this.authorizedBy,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.archived,
  });

  final String id;
  final String partnerId;
  final String propertyId;
  final PartnerLedgerEntryType entryType;
  final double amount;
  final String notes;
  final String authorizedBy;
  final String createdBy;
  final String updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;

  Map<String, dynamic> toMap() {
    return {
      'partnerId': partnerId,
      'propertyId': propertyId,
      'entryType': entryType.name,
      'amount': amount,
      'notes': notes,
      'authorizedBy': authorizedBy,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'archived': archived,
    };
  }

  factory PartnerLedgerEntry.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return PartnerLedgerEntry(
      id: id,
      partnerId: data['partnerId'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      entryType: PartnerLedgerEntryType.values.firstWhere(
        (value) => value.name == data['entryType'],
        orElse: () => PartnerLedgerEntryType.contribution,
      ),
      amount: parseDouble(data['amount']),
      notes: data['notes'] as String? ?? '',
      authorizedBy: data['authorizedBy'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      updatedBy: data['updatedBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      archived: data['archived'] as bool? ?? false,
    );
  }

  PartnerLedgerEntry copyWith({
    String? id,
    String? partnerId,
    String? propertyId,
    PartnerLedgerEntryType? entryType,
    double? amount,
    String? notes,
    String? authorizedBy,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return PartnerLedgerEntry(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      propertyId: propertyId ?? this.propertyId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalProperties,
    required this.totalExpenses,
    required this.totalSalesValue,
    required this.totalCollected,
    required this.totalRemaining,
    required this.overdueInstallmentsCount,
    required this.recentActivityCount,
  });

  final int totalProperties;
  final double totalExpenses;
  final double totalSalesValue;
  final double totalCollected;
  final double totalRemaining;
  final int overdueInstallmentsCount;
  final int recentActivityCount;
}

class PartnerSettlement {
  const PartnerSettlement({
    required this.partnerId,
    required this.partnerName,
    required this.contributedAmount,
    required this.shareRatio,
    required this.expectedContribution,
    required this.balanceDelta,
  });

  final String partnerId;
  final String partnerName;
  final double contributedAmount;
  final double shareRatio;
  final double expectedContribution;
  final double balanceDelta;
}
