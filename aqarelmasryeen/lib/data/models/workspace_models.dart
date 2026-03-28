import 'dart:convert';

enum PropertyStatus {
  active('active', 'property_status_active'),
  construction('construction', 'property_status_construction'),
  collection('collection', 'property_status_collection'),
  archived('archived', 'property_status_archived');

  const PropertyStatus(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static PropertyStatus fromKey(String? key) {
    return PropertyStatus.values.firstWhere(
      (item) => item.key == key,
      orElse: () => PropertyStatus.active,
    );
  }
}

enum UnitType {
  apartment('apartment', 'unit_type_apartment'),
  shop('shop', 'unit_type_shop'),
  office('office', 'unit_type_office'),
  floor('floor', 'unit_type_floor');

  const UnitType(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static UnitType fromKey(String? key) {
    return UnitType.values.firstWhere(
      (item) => item.key == key,
      orElse: () => UnitType.apartment,
    );
  }
}

enum UnitStatus {
  available('available', 'unit_status_available'),
  reserved('reserved', 'unit_status_reserved'),
  sold('sold', 'unit_status_sold'),
  installment('installment', 'unit_status_installment'),
  cancelled('cancelled', 'unit_status_cancelled');

  const UnitStatus(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static UnitStatus fromKey(String? key) {
    return UnitStatus.values.firstWhere(
      (item) => item.key == key,
      orElse: () => UnitStatus.available,
    );
  }
}

enum ExpenseCategory {
  construction('construction', 'expense_category_construction'),
  labor('labor', 'expense_category_labor'),
  electrical('electrical', 'expense_category_electrical'),
  plumbing('plumbing', 'expense_category_plumbing'),
  finishing('finishing', 'expense_category_finishing'),
  maintenance('maintenance', 'expense_category_maintenance'),
  transportation('transportation', 'expense_category_transportation'),
  admin('admin', 'expense_category_admin'),
  commission('commission', 'expense_category_commission'),
  other('other', 'expense_category_other');

  const ExpenseCategory(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static ExpenseCategory fromKey(String? key) {
    return ExpenseCategory.values.firstWhere(
      (item) => item.key == key,
      orElse: () => ExpenseCategory.other,
    );
  }
}

enum InstallmentStatus {
  unpaid('unpaid', 'installment_status_unpaid'),
  partiallyPaid('partially_paid', 'installment_status_partially_paid'),
  paid('paid', 'installment_status_paid'),
  overdue('overdue', 'installment_status_overdue');

  const InstallmentStatus(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static InstallmentStatus fromKey(String? key) {
    return InstallmentStatus.values.firstWhere(
      (item) => item.key == key,
      orElse: () => InstallmentStatus.unpaid,
    );
  }
}

enum NotificationCategory {
  installment('installment', 'notification_category_installment'),
  payment('payment', 'notification_category_payment'),
  expense('expense', 'notification_category_expense'),
  assignment('assignment', 'notification_category_assignment'),
  property('property', 'notification_category_property'),
  system('system', 'notification_category_system');

  const NotificationCategory(this.key, this.labelKey);

  final String key;
  final String labelKey;

  static NotificationCategory fromKey(String? key) {
    return NotificationCategory.values.firstWhere(
      (item) => item.key == key,
      orElse: () => NotificationCategory.system,
    );
  }
}

class PropertyRecord {
  const PropertyRecord({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.description,
    required this.floorsCount,
    required this.unitsCount,
    required this.status,
    required this.assignedUserIds,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String location;
  final String description;
  final int floorsCount;
  final int unitsCount;
  final PropertyStatus status;
  final List<String> assignedUserIds;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyRecord copyWith({
    String? id,
    String? name,
    String? code,
    String? location,
    String? description,
    int? floorsCount,
    int? unitsCount,
    PropertyStatus? status,
    List<String>? assignedUserIds,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      description: description ?? this.description,
      floorsCount: floorsCount ?? this.floorsCount,
      unitsCount: unitsCount ?? this.unitsCount,
      status: status ?? this.status,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'location': location,
      'description': description,
      'floorsCount': floorsCount,
      'unitsCount': unitsCount,
      'status': status.key,
      'assignedUserIds': assignedUserIds,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PropertyRecord.fromJsonMap(Map<String, dynamic> map) {
    return PropertyRecord(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      location: map['location'] as String? ?? '',
      description: map['description'] as String? ?? '',
      floorsCount: map['floorsCount'] as int? ?? 0,
      unitsCount: map['unitsCount'] as int? ?? 0,
      status: PropertyStatus.fromKey(map['status'] as String?),
      assignedUserIds: List<String>.from(
        map['assignedUserIds'] as List<dynamic>? ?? const <dynamic>[],
      ),
      attachments: List<String>.from(
        map['attachments'] as List<dynamic>? ?? const <dynamic>[],
      ),
      createdAt: _dateFromJson(map['createdAt']),
      updatedAt: _dateFromJson(map['updatedAt']),
    );
  }
}

class UnitRecord {
  const UnitRecord({
    required this.id,
    required this.propertyId,
    required this.unitNumber,
    required this.floorNumber,
    required this.type,
    required this.area,
    required this.price,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.saleContractId,
  });

  final String id;
  final String propertyId;
  final String unitNumber;
  final int floorNumber;
  final UnitType type;
  final double area;
  final double price;
  final UnitStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? saleContractId;

  UnitRecord copyWith({
    String? id,
    String? propertyId,
    String? unitNumber,
    int? floorNumber,
    UnitType? type,
    double? area,
    double? price,
    UnitStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? saleContractId,
    bool clearSaleContract = false,
  }) {
    return UnitRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      type: type ?? this.type,
      area: area ?? this.area,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      saleContractId: clearSaleContract
          ? null
          : saleContractId ?? this.saleContractId,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitNumber': unitNumber,
      'floorNumber': floorNumber,
      'type': type.key,
      'area': area,
      'price': price,
      'status': status.key,
      'notes': notes,
      'saleContractId': saleContractId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UnitRecord.fromJsonMap(Map<String, dynamic> map) {
    return UnitRecord(
      id: map['id'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      unitNumber: map['unitNumber'] as String? ?? '',
      floorNumber: map['floorNumber'] as int? ?? 0,
      type: UnitType.fromKey(map['type'] as String?),
      area: (map['area'] as num? ?? 0).toDouble(),
      price: (map['price'] as num? ?? 0).toDouble(),
      status: UnitStatus.fromKey(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      saleContractId: map['saleContractId'] as String?,
      createdAt: _dateFromJson(map['createdAt']),
      updatedAt: _dateFromJson(map['updatedAt']),
    );
  }
}

class CustomerRecord {
  const CustomerRecord({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.createdAt,
    this.email,
    this.notes,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;

  CustomerRecord copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? notes,
    DateTime? createdAt,
  }) {
    return CustomerRecord(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerRecord.fromJsonMap(Map<String, dynamic> map) {
    return CustomerRecord(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      notes: map['notes'] as String?,
      createdAt: _dateFromJson(map['createdAt']),
    );
  }
}

class SalesContractRecord {
  const SalesContractRecord({
    required this.id,
    required this.propertyId,
    required this.unitId,
    required this.customerId,
    required this.totalPrice,
    required this.discount,
    required this.downPayment,
    required this.installmentCount,
    required this.installmentFrequencyMonths,
    required this.startDate,
    required this.notes,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String propertyId;
  final String unitId;
  final String customerId;
  final double totalPrice;
  final double discount;
  final double downPayment;
  final int installmentCount;
  final int installmentFrequencyMonths;
  final DateTime startDate;
  final String notes;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get netPrice => totalPrice - discount;
  double get financedAmount => (netPrice - downPayment).clamp(0, double.infinity);

  SalesContractRecord copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    String? customerId,
    double? totalPrice,
    double? discount,
    double? downPayment,
    int? installmentCount,
    int? installmentFrequencyMonths,
    DateTime? startDate,
    String? notes,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesContractRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      customerId: customerId ?? this.customerId,
      totalPrice: totalPrice ?? this.totalPrice,
      discount: discount ?? this.discount,
      downPayment: downPayment ?? this.downPayment,
      installmentCount: installmentCount ?? this.installmentCount,
      installmentFrequencyMonths:
          installmentFrequencyMonths ?? this.installmentFrequencyMonths,
      startDate: startDate ?? this.startDate,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitId': unitId,
      'customerId': customerId,
      'totalPrice': totalPrice,
      'discount': discount,
      'downPayment': downPayment,
      'installmentCount': installmentCount,
      'installmentFrequencyMonths': installmentFrequencyMonths,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
      'attachments': attachments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SalesContractRecord.fromJsonMap(Map<String, dynamic> map) {
    return SalesContractRecord(
      id: map['id'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      unitId: map['unitId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      totalPrice: (map['totalPrice'] as num? ?? 0).toDouble(),
      discount: (map['discount'] as num? ?? 0).toDouble(),
      downPayment: (map['downPayment'] as num? ?? 0).toDouble(),
      installmentCount: map['installmentCount'] as int? ?? 0,
      installmentFrequencyMonths:
          map['installmentFrequencyMonths'] as int? ?? 1,
      startDate: _dateFromJson(map['startDate']),
      notes: map['notes'] as String? ?? '',
      attachments: List<String>.from(
        map['attachments'] as List<dynamic>? ?? const <dynamic>[],
      ),
      createdAt: _dateFromJson(map['createdAt']),
      updatedAt: _dateFromJson(map['updatedAt']),
    );
  }
}

class InstallmentRecord {
  const InstallmentRecord({
    required this.id,
    required this.saleContractId,
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.paidAmount,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.paymentDate,
  });

  final String id;
  final String saleContractId;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final double paidAmount;
  final InstallmentStatus status;
  final DateTime? paymentDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get remainingAmount => (amount - paidAmount).clamp(0, double.infinity);

  InstallmentRecord copyWith({
    String? id,
    String? saleContractId,
    int? installmentNumber,
    DateTime? dueDate,
    double? amount,
    double? paidAmount,
    InstallmentStatus? status,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPaymentDate = false,
  }) {
    return InstallmentRecord(
      id: id ?? this.id,
      saleContractId: saleContractId ?? this.saleContractId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentDate: clearPaymentDate ? null : paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'saleContractId': saleContractId,
      'installmentNumber': installmentNumber,
      'dueDate': dueDate.toIso8601String(),
      'amount': amount,
      'paidAmount': paidAmount,
      'status': status.key,
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InstallmentRecord.fromJsonMap(Map<String, dynamic> map) {
    return InstallmentRecord(
      id: map['id'] as String? ?? '',
      saleContractId: map['saleContractId'] as String? ?? '',
      installmentNumber: map['installmentNumber'] as int? ?? 0,
      dueDate: _dateFromJson(map['dueDate']),
      amount: (map['amount'] as num? ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] as num? ?? 0).toDouble(),
      status: InstallmentStatus.fromKey(map['status'] as String?),
      paymentDate: map['paymentDate'] == null
          ? null
          : _dateFromJson(map['paymentDate']),
      notes: map['notes'] as String? ?? '',
      createdAt: _dateFromJson(map['createdAt']),
      updatedAt: _dateFromJson(map['updatedAt']),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.saleContractId,
    required this.installmentId,
    required this.amount,
    required this.date,
    required this.createdByUserId,
    required this.createdAt,
    this.receiptUrl,
    this.notes,
  });

  final String id;
  final String saleContractId;
  final String installmentId;
  final double amount;
  final DateTime date;
  final String createdByUserId;
  final DateTime createdAt;
  final String? receiptUrl;
  final String? notes;

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'saleContractId': saleContractId,
      'installmentId': installmentId,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdByUserId': createdByUserId,
      'createdAt': createdAt.toIso8601String(),
      'receiptUrl': receiptUrl,
      'notes': notes,
    };
  }

  factory PaymentRecord.fromJsonMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id'] as String? ?? '',
      saleContractId: map['saleContractId'] as String? ?? '',
      installmentId: map['installmentId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      date: _dateFromJson(map['date']),
      createdByUserId: map['createdByUserId'] as String? ?? '',
      createdAt: _dateFromJson(map['createdAt']),
      receiptUrl: map['receiptUrl'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.propertyId,
    required this.paidByUserId,
    required this.category,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.attachmentUrl,
    this.notes,
  });

  final String id;
  final String propertyId;
  final String paidByUserId;
  final ExpenseCategory category;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? attachmentUrl;
  final String? notes;

  ExpenseRecord copyWith({
    String? id,
    String? propertyId,
    String? paidByUserId,
    ExpenseCategory? category,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? attachmentUrl,
    String? notes,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'paidByUserId': paidByUserId,
      'category': category.key,
      'title': title,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'notes': notes,
    };
  }

  factory ExpenseRecord.fromJsonMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] as String? ?? '',
      propertyId: map['propertyId'] as String? ?? '',
      paidByUserId: map['paidByUserId'] as String? ?? '',
      category: ExpenseCategory.fromKey(map['category'] as String?),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      date: _dateFromJson(map['date']),
      createdAt: _dateFromJson(map['createdAt']),
      updatedAt: _dateFromJson(map['updatedAt']),
      attachmentUrl: map['attachmentUrl'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

class AppNotificationRecord {
  const AppNotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.section,
    required this.createdAt,
    required this.isRead,
    this.entityId,
  });

  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final String section;
  final DateTime createdAt;
  final bool isRead;
  final String? entityId;

  AppNotificationRecord copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    String? section,
    DateTime? createdAt,
    bool? isRead,
    String? entityId,
  }) {
    return AppNotificationRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      section: section ?? this.section,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      entityId: entityId ?? this.entityId,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category.key,
      'section': section,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'entityId': entityId,
    };
  }

  factory AppNotificationRecord.fromJsonMap(Map<String, dynamic> map) {
    return AppNotificationRecord(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: NotificationCategory.fromKey(map['category'] as String?),
      section: map['section'] as String? ?? 'dashboard',
      createdAt: _dateFromJson(map['createdAt']),
      isRead: map['isRead'] as bool? ?? false,
      entityId: map['entityId'] as String?,
    );
  }
}

class ActivityLogRecord {
  const ActivityLogRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.actorUserId,
  });

  final String id;
  final String title;
  final String description;
  final String entityType;
  final String entityId;
  final DateTime createdAt;
  final String? actorUserId;

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': createdAt.toIso8601String(),
      'actorUserId': actorUserId,
    };
  }

  factory ActivityLogRecord.fromJsonMap(Map<String, dynamic> map) {
    return ActivityLogRecord(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      entityType: map['entityType'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      createdAt: _dateFromJson(map['createdAt']),
      actorUserId: map['actorUserId'] as String?,
    );
  }
}

class WorkspaceSnapshot {
  const WorkspaceSnapshot({
    required this.users,
    required this.properties,
    required this.units,
    required this.customers,
    required this.salesContracts,
    required this.installments,
    required this.payments,
    required this.expenses,
    required this.notifications,
    required this.activityLogs,
    required this.lastUpdatedAt,
  });

  final List<dynamic> users;
  final List<PropertyRecord> properties;
  final List<UnitRecord> units;
  final List<CustomerRecord> customers;
  final List<SalesContractRecord> salesContracts;
  final List<InstallmentRecord> installments;
  final List<PaymentRecord> payments;
  final List<ExpenseRecord> expenses;
  final List<AppNotificationRecord> notifications;
  final List<ActivityLogRecord> activityLogs;
  final DateTime lastUpdatedAt;

  String encode({
    required List<Map<String, dynamic>> usersJson,
  }) {
    return jsonEncode({
      'users': usersJson,
      'properties': properties.map((item) => item.toJsonMap()).toList(),
      'units': units.map((item) => item.toJsonMap()).toList(),
      'customers': customers.map((item) => item.toJsonMap()).toList(),
      'salesContracts': salesContracts.map((item) => item.toJsonMap()).toList(),
      'installments': installments.map((item) => item.toJsonMap()).toList(),
      'payments': payments.map((item) => item.toJsonMap()).toList(),
      'expenses': expenses.map((item) => item.toJsonMap()).toList(),
      'notifications': notifications.map((item) => item.toJsonMap()).toList(),
      'activityLogs': activityLogs.map((item) => item.toJsonMap()).toList(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    });
  }
}

DateTime _dateFromJson(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.now();
}
