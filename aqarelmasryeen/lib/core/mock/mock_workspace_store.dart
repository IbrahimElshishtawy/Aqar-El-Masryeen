import 'dart:async';

import 'package:aqarelmasryeen/core/routing/app_routes.dart';
import 'package:aqarelmasryeen/shared/enums/app_enums.dart';
import 'package:aqarelmasryeen/shared/models/app_user.dart';
import 'package:aqarelmasryeen/shared/models/auth_device_info.dart';
import 'package:aqarelmasryeen/shared/models/financial_models.dart';
import 'package:aqarelmasryeen/shared/models/partner_models.dart';
import 'package:aqarelmasryeen/shared/models/property_models.dart';

class MockWorkspaceStore {
  MockWorkspaceStore._() {
    _seed();
  }

  static final MockWorkspaceStore instance = MockWorkspaceStore._();

  final StreamController<int> _changes = StreamController<int>.broadcast();

  late AppUser _profile;
  late List<PropertyProject> _properties;
  late List<Partner> _partners;
  late List<ExpenseRecord> _expenses;
  late List<UnitSale> _units;
  late List<InstallmentPlan> _plans;
  late List<Installment> _installments;
  late List<PaymentRecord> _payments;
  late List<ActivityLogEntry> _activity;
  late List<AppNotificationItem> _notifications;
  late List<PropertyStorageFile> _files;

  AuthDeviceInfo get _deviceInfo => const AuthDeviceInfo(
    deviceId: 'mock-device-01',
    deviceName: 'TECNO LE6h Mock',
    platform: 'android',
    osVersion: 'Android 13',
    appVersion: '1.0.0',
    buildNumber: '1',
    model: 'LE6h',
    manufacturer: 'TECNO',
    isPhysicalDevice: true,
  );

  AppUser profileForUid(String uid) => _profile.copyWith(uid: uid);

  void updateProfile({
    String? uid,
    String? fullName,
    String? email,
    bool? trustedDeviceEnabled,
    bool? biometricEnabled,
    bool? appLockEnabled,
    int? inactivityTimeoutSeconds,
  }) {
    _profile = _profile.copyWith(
      uid: uid,
      fullName: fullName,
      email: email,
      trustedDeviceEnabled: trustedDeviceEnabled,
      biometricEnabled: biometricEnabled,
      appLockEnabled: appLockEnabled,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  Stream<T> watch<T>(T Function() selector) async* {
    yield selector();
    yield* _changes.stream.map((_) => selector());
  }

  List<PropertyProject> activeProperties() => List.unmodifiable(
    _properties.where((item) => !item.archived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  PropertyProject? propertyById(String propertyId) {
    for (final item in _properties) {
      if (item.id == propertyId) {
        return item;
      }
    }
    return null;
  }

  List<ExpenseRecord> allExpenses() => List.unmodifiable(
    _expenses.where((item) => !item.archived).toList()
      ..sort((a, b) => b.date.compareTo(a.date)),
  );

  List<ExpenseRecord> expensesByProperty(String propertyId) =>
      List.unmodifiable(
        allExpenses().where((item) => item.propertyId == propertyId).toList(),
      );

  List<Partner> partners() => List.unmodifiable(
    _partners.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
  );

  List<UnitSale> allUnits() => List.unmodifiable(
    _units.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  List<UnitSale> unitsByProperty(String propertyId) => List.unmodifiable(
    allUnits().where((item) => item.propertyId == propertyId).toList(),
  );

  List<InstallmentPlan> plansByProperty(String propertyId) => List.unmodifiable(
    _plans.where((item) => item.propertyId == propertyId).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  List<Installment> allInstallments() => List.unmodifiable(
    _installments.toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
  );

  List<Installment> installmentsByProperty(String propertyId) =>
      List.unmodifiable(
        allInstallments()
            .where((item) => item.propertyId == propertyId)
            .toList(),
      );

  List<PaymentRecord> allPayments() => List.unmodifiable(
    _payments.toList()..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
  );

  List<PaymentRecord> paymentsByProperty(String propertyId) =>
      List.unmodifiable(
        allPayments().where((item) => item.propertyId == propertyId).toList(),
      );

  List<ActivityLogEntry> recentActivity({String? propertyId}) {
    final source = propertyId == null
        ? _activity
        : _activity.where((item) => item.entityId == propertyId).toList();
    return List.unmodifiable(
      source.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  List<AppNotificationItem> notificationsFor(String userId) =>
      List.unmodifiable(
        _notifications.where((item) => item.userId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  List<PropertyStorageFile> filesFor(String propertyId) => List.unmodifiable(
    _files.where((item) => item.fullPath.contains('/$propertyId/')).toList(),
  );

  Future<void> saveProperty(PropertyProject property) async {
    _upsert(
      _properties,
      property.id,
      property.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> archiveProperty(
    String propertyId, {
    required String actorId,
  }) async {
    final current = propertyById(propertyId);
    if (current == null) return;
    await saveProperty(
      current.copyWith(
        archived: true,
        status: PropertyStatus.archived,
        updatedBy: actorId,
      ),
    );
  }

  Future<void> saveExpense(ExpenseRecord expense) async {
    _upsert(
      _expenses,
      expense.id,
      expense.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> softDeleteExpense(String expenseId) async {
    final index = _expenses.indexWhere((item) => item.id == expenseId);
    if (index == -1) return;
    _expenses[index] = _expenses[index].copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  Future<void> upsertPartner(Partner partner) async {
    _upsert(
      _partners,
      partner.id,
      partner.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> saveUnit(UnitSale unit) async {
    _upsert(
      _units,
      unit.id,
      unit.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> savePlan(InstallmentPlan plan) async {
    _upsert(
      _plans,
      plan.id,
      plan.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> saveInstallment(Installment installment) async {
    _upsert(
      _installments,
      installment.id,
      installment.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> recordPayment(PaymentRecord payment) async {
    _upsert(
      _payments,
      payment.id,
      payment.copyWith(updatedAt: DateTime.now()),
      (item) => item.id,
    );
    _emit();
  }

  Future<void> updateInstallmentPayment({
    required String installmentId,
    required double paidAmount,
  }) async {
    final index = _installments.indexWhere((item) => item.id == installmentId);
    if (index == -1) return;
    final current = _installments[index];
    final totalPaid = current.paidAmount + paidAmount;
    final status = totalPaid >= current.amount
        ? InstallmentStatus.paid
        : totalPaid > 0
        ? InstallmentStatus.partiallyPaid
        : current.dueDate.isBefore(DateTime.now())
        ? InstallmentStatus.overdue
        : InstallmentStatus.pending;
    _installments[index] = current.copyWith(
      paidAmount: totalPaid,
      status: status,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  Future<void> logActivity(ActivityLogEntry entry) async {
    _upsert(_activity, entry.id, entry, (item) => item.id);
    _emit();
  }

  Future<void> createNotification(AppNotificationItem item) async {
    _upsert(_notifications, item.id, item, (entry) => entry.id);
    _emit();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index == -1) return;
    final item = _notifications[index];
    _notifications[index] = AppNotificationItem(
      id: item.id,
      userId: item.userId,
      title: item.title,
      body: item.body,
      type: item.type,
      route: item.route,
      isRead: true,
      createdAt: item.createdAt,
    );
    _emit();
  }

  void _emit() {
    _changes.add(DateTime.now().microsecondsSinceEpoch);
  }

  void _seed() {
    final now = DateTime.now();
    _profile = AppUser(
      uid: 'mock-user',
      phone: '',
      fullName: 'شريك تجريبي',
      email: 'demo@mock.local',
      createdAt: now.subtract(const Duration(days: 120)),
      updatedAt: now,
      lastLoginAt: now,
      role: UserRole.partner,
      trustedDeviceEnabled: false,
      biometricEnabled: false,
      appLockEnabled: false,
      inactivityTimeoutSeconds: 90,
      deviceInfo: _deviceInfo,
      isActive: true,
      securitySetupCompletedAt: now.subtract(const Duration(days: 10)),
    );

    _partners = [
      Partner(
        id: 'partner_1',
        userId: 'mock-user',
        name: 'أحمد المصري',
        shareRatio: 0.5,
        contributionTotal: 900000,
        createdAt: now.subtract(const Duration(days: 140)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Partner(
        id: 'partner_2',
        userId: 'partner-user-2',
        name: 'محمد خالد',
        shareRatio: 0.3,
        contributionTotal: 540000,
        createdAt: now.subtract(const Duration(days: 135)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Partner(
        id: 'partner_3',
        userId: 'partner-user-3',
        name: 'سارة علي',
        shareRatio: 0.2,
        contributionTotal: 360000,
        createdAt: now.subtract(const Duration(days: 130)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    _properties = [
      PropertyProject(
        id: 'property_1',
        name: 'كمبوند النيل',
        location: 'التجمع الخامس',
        description: 'مشروع سكني متوسط التشطيب.',
        status: PropertyStatus.active,
        totalBudget: 1800000,
        totalSalesTarget: 4200000,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        archived: false,
      ),
      PropertyProject(
        id: 'property_2',
        name: 'برج الواحة',
        location: 'العاصمة الإدارية',
        description: 'وحدات إدارية وتجارية.',
        status: PropertyStatus.planning,
        totalBudget: 2600000,
        totalSalesTarget: 6100000,
        createdAt: now.subtract(const Duration(days: 95)),
        updatedAt: now.subtract(const Duration(days: 1)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        archived: false,
      ),
    ];

    _units = [
      UnitSale(
        id: 'unit_1',
        propertyId: 'property_1',
        unitNumber: 'A-101',
        floor: 1,
        unitType: UnitType.apartment,
        area: 145,
        customerName: 'عمرو حسن',
        customerPhone: '01000000001',
        totalPrice: 2200000,
        downPayment: 400000,
        remainingAmount: 1800000,
        paymentPlanType: PaymentPlanType.installment,
        status: UnitStatus.sold,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      UnitSale(
        id: 'unit_2',
        propertyId: 'property_1',
        unitNumber: 'B-203',
        floor: 2,
        unitType: UnitType.apartment,
        area: 160,
        customerName: 'منى سمير',
        customerPhone: '01000000002',
        totalPrice: 2450000,
        downPayment: 600000,
        remainingAmount: 1850000,
        paymentPlanType: PaymentPlanType.installment,
        status: UnitStatus.reserved,
        createdAt: now.subtract(const Duration(days: 55)),
        updatedAt: now.subtract(const Duration(days: 4)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      UnitSale(
        id: 'unit_3',
        propertyId: 'property_2',
        unitNumber: 'C-11',
        floor: 1,
        unitType: UnitType.office,
        area: 90,
        customerName: '',
        customerPhone: '',
        totalPrice: 1950000,
        downPayment: 0,
        remainingAmount: 1950000,
        paymentPlanType: PaymentPlanType.custom,
        status: UnitStatus.available,
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 1)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
    ];

    _expenses = [
      ExpenseRecord(
        id: 'expense_1',
        propertyId: 'property_1',
        amount: 120000,
        category: ExpenseCategory.construction,
        description: 'دفعة خرسانة',
        paidByPartnerId: 'partner_1',
        paymentMethod: PaymentMethod.bankTransfer,
        date: now.subtract(const Duration(days: 18)),
        attachmentUrl: null,
        notes: 'المرحلة الأولى',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 18)),
        archived: false,
      ),
      ExpenseRecord(
        id: 'expense_2',
        propertyId: 'property_1',
        amount: 45000,
        category: ExpenseCategory.marketing,
        description: 'حملة ممولة',
        paidByPartnerId: 'partner_2',
        paymentMethod: PaymentMethod.wallet,
        date: now.subtract(const Duration(days: 9)),
        attachmentUrl: null,
        notes: 'إعلانات سوشيال',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 9)),
        archived: false,
      ),
      ExpenseRecord(
        id: 'expense_3',
        propertyId: 'property_2',
        amount: 30000,
        category: ExpenseCategory.legal,
        description: 'أتعاب قانونية',
        paidByPartnerId: 'partner_3',
        paymentMethod: PaymentMethod.cash,
        date: now.subtract(const Duration(days: 6)),
        attachmentUrl: null,
        notes: '',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
        archived: false,
      ),
    ];

    _plans = [
      InstallmentPlan(
        id: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        installmentCount: 6,
        startDate: now.subtract(const Duration(days: 150)),
        intervalDays: 30,
        installmentAmount: 300000,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
    ];

    _installments = [
      Installment(
        id: 'inst_1',
        planId: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        sequence: 1,
        amount: 300000,
        paidAmount: 300000,
        dueDate: now.subtract(const Duration(days: 120)),
        status: InstallmentStatus.paid,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 120)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      Installment(
        id: 'inst_2',
        planId: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        sequence: 2,
        amount: 300000,
        paidAmount: 300000,
        dueDate: now.subtract(const Duration(days: 90)),
        status: InstallmentStatus.paid,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 90)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      Installment(
        id: 'inst_3',
        planId: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        sequence: 3,
        amount: 300000,
        paidAmount: 180000,
        dueDate: now.subtract(const Duration(days: 30)),
        status: InstallmentStatus.partiallyPaid,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 20)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      Installment(
        id: 'inst_4',
        planId: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        sequence: 4,
        amount: 300000,
        paidAmount: 0,
        dueDate: now.subtract(const Duration(days: 2)),
        status: InstallmentStatus.overdue,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      Installment(
        id: 'inst_5',
        planId: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        sequence: 5,
        amount: 300000,
        paidAmount: 0,
        dueDate: now.add(const Duration(days: 28)),
        status: InstallmentStatus.pending,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      Installment(
        id: 'inst_6',
        planId: 'plan_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        sequence: 6,
        amount: 300000,
        paidAmount: 0,
        dueDate: now.add(const Duration(days: 58)),
        status: InstallmentStatus.pending,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
    ];

    _payments = [
      PaymentRecord(
        id: 'payment_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        installmentId: 'inst_1',
        amount: 300000,
        receivedAt: now.subtract(const Duration(days: 120)),
        paymentMethod: PaymentMethod.bankTransfer,
        notes: 'سداد القسط الأول',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      PaymentRecord(
        id: 'payment_2',
        propertyId: 'property_1',
        unitId: 'unit_1',
        installmentId: 'inst_2',
        amount: 300000,
        receivedAt: now.subtract(const Duration(days: 90)),
        paymentMethod: PaymentMethod.bankTransfer,
        notes: 'سداد القسط الثاني',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 90)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      PaymentRecord(
        id: 'payment_3',
        propertyId: 'property_1',
        unitId: 'unit_1',
        installmentId: 'inst_3',
        amount: 180000,
        receivedAt: now.subtract(const Duration(days: 20)),
        paymentMethod: PaymentMethod.cash,
        notes: 'دفعة جزئية',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
    ];

    _activity = [
      ActivityLogEntry(
        id: 'activity_1',
        actorId: 'mock-user',
        actorName: 'شريك تجريبي',
        action: 'property_created',
        entityType: 'property',
        entityId: 'property_1',
        createdAt: now.subtract(const Duration(days: 30)),
        metadata: const {'propertyId': 'property_1'},
      ),
      ActivityLogEntry(
        id: 'activity_2',
        actorId: 'mock-user',
        actorName: 'شريك تجريبي',
        action: 'expense_created',
        entityType: 'expense',
        entityId: 'property_1',
        createdAt: now.subtract(const Duration(days: 9)),
        metadata: const {'amount': 45000},
      ),
      ActivityLogEntry(
        id: 'activity_3',
        actorId: 'mock-user',
        actorName: 'شريك تجريبي',
        action: 'payment_received',
        entityType: 'payment',
        entityId: 'property_1',
        createdAt: now.subtract(const Duration(days: 5)),
        metadata: const {'amount': 180000},
      ),
      ActivityLogEntry(
        id: 'activity_4',
        actorId: 'mock-user',
        actorName: 'شريك تجريبي',
        action: 'partner_updated',
        entityType: 'partner',
        entityId: 'partner_2',
        createdAt: now.subtract(const Duration(days: 2)),
        metadata: const {},
      ),
    ];

    _notifications = [
      AppNotificationItem(
        id: 'notification_1',
        userId: 'mock-user',
        title: 'قسط متأخر',
        body: 'يوجد قسط متأخر للوحدة A-101.',
        type: NotificationType.overdueInstallment,
        route: AppRoutes.propertyDetails('property_1'),
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      AppNotificationItem(
        id: 'notification_2',
        userId: 'mock-user',
        title: 'مصروف جديد',
        body: 'تمت إضافة مصروف تسويق على كمبوند النيل.',
        type: NotificationType.expenseAdded,
        route: AppRoutes.propertyDetails('property_1'),
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    _files = [
      PropertyStorageFile(
        name: 'layout-plan.pdf',
        fullPath: 'properties/property_1/files/layout-plan.pdf',
        downloadUrl: 'https://example.com/layout-plan.pdf',
        sizeBytes: 245760,
        updatedAt: now.subtract(const Duration(days: 2)),
        contentType: 'application/pdf',
      ),
      PropertyStorageFile(
        name: 'site-photo.jpg',
        fullPath: 'properties/property_1/files/site-photo.jpg',
        downloadUrl: 'https://example.com/site-photo.jpg',
        sizeBytes: 512000,
        updatedAt: now.subtract(const Duration(days: 4)),
        contentType: 'image/jpeg',
      ),
    ];
  }

  void _upsert<T>(
    List<T> items,
    String id,
    T value,
    String Function(T item) idSelector,
  ) {
    final index = items.indexWhere((item) => idSelector(item) == id);
    if (index == -1) {
      items.add(value);
    } else {
      items[index] = value;
    }
  }
}

extension on PropertyProject {
  PropertyProject copyWith({
    String? id,
    String? name,
    String? location,
    String? description,
    PropertyStatus? status,
    double? totalBudget,
    double? totalSalesTarget,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? archived,
  }) {
    return PropertyProject(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      status: status ?? this.status,
      totalBudget: totalBudget ?? this.totalBudget,
      totalSalesTarget: totalSalesTarget ?? this.totalSalesTarget,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      archived: archived ?? this.archived,
    );
  }
}

extension on ExpenseRecord {
  ExpenseRecord copyWith({
    String? id,
    String? propertyId,
    double? amount,
    ExpenseCategory? category,
    String? description,
    String? paidByPartnerId,
    PaymentMethod? paymentMethod,
    DateTime? date,
    String? attachmentUrl,
    String? notes,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      paidByPartnerId: paidByPartnerId ?? this.paidByPartnerId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
    );
  }
}

extension on Partner {
  Partner copyWith({
    String? id,
    String? userId,
    String? name,
    double? shareRatio,
    double? contributionTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Partner(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      shareRatio: shareRatio ?? this.shareRatio,
      contributionTotal: contributionTotal ?? this.contributionTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension on UnitSale {
  UnitSale copyWith({
    String? id,
    String? propertyId,
    String? unitNumber,
    int? floor,
    UnitType? unitType,
    double? area,
    String? customerName,
    String? customerPhone,
    double? totalPrice,
    double? downPayment,
    double? remainingAmount,
    PaymentPlanType? paymentPlanType,
    UnitStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return UnitSale(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitNumber: unitNumber ?? this.unitNumber,
      floor: floor ?? this.floor,
      unitType: unitType ?? this.unitType,
      area: area ?? this.area,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalPrice: totalPrice ?? this.totalPrice,
      downPayment: downPayment ?? this.downPayment,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentPlanType: paymentPlanType ?? this.paymentPlanType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

extension on InstallmentPlan {
  InstallmentPlan copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    int? installmentCount,
    DateTime? startDate,
    int? intervalDays,
    double? installmentAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      installmentCount: installmentCount ?? this.installmentCount,
      startDate: startDate ?? this.startDate,
      intervalDays: intervalDays ?? this.intervalDays,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

extension on Installment {
  Installment copyWith({
    String? id,
    String? planId,
    String? propertyId,
    String? unitId,
    int? sequence,
    double? amount,
    double? paidAmount,
    DateTime? dueDate,
    InstallmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return Installment(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      sequence: sequence ?? this.sequence,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

extension on PaymentRecord {
  PaymentRecord copyWith({
    String? id,
    String? propertyId,
    String? unitId,
    String? installmentId,
    double? amount,
    DateTime? receivedAt,
    PaymentMethod? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      unitId: unitId ?? this.unitId,
      installmentId: installmentId ?? this.installmentId,
      amount: amount ?? this.amount,
      receivedAt: receivedAt ?? this.receivedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
