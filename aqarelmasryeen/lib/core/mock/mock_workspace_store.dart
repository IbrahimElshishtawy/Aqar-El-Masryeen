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

  late String _activeUserId;
  late Map<String, AppUser> _profilesById;
  late Map<String, String> _passwordsByEmail;
  late List<PropertyProject> _properties;
  late List<Partner> _partners;
  late List<ExpenseRecord> _expenses;
  late List<UnitSale> _units;
  late List<InstallmentPlan> _plans;
  late List<Installment> _installments;
  late List<PaymentRecord> _payments;
  late List<MaterialExpenseEntry> _materialExpenses;
  late List<PartnerLedgerEntry> _partnerLedgerEntries;
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

  AppUser get activeProfile => _profilesById[_activeUserId]!;

  AppUser profileForUid(String uid) =>
      _profilesById[uid] ?? activeProfile.copyWith(uid: uid);

  AppUser? profileByUid(String uid) => _profilesById[uid];

  AppUser? profileByEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final profile in _profilesById.values) {
      if (profile.email.trim().toLowerCase() == normalizedEmail) {
        return profile;
      }
    }
    return null;
  }

  bool validateCredentials(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    return _passwordsByEmail[normalizedEmail] == password;
  }

  AppUser createPartnerProfile({
    required String fullName,
    required String email,
    required String password,
  }) {
    final now = DateTime.now();
    final uid = 'mock-user-${_profilesById.length + 1}';
    final normalizedEmail = email.trim().toLowerCase();
    final profile = AppUser(
      uid: uid,
      phone: '',
      fullName: fullName.trim(),
      email: normalizedEmail,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: null,
      role: UserRole.partner,
      trustedDeviceEnabled: false,
      biometricEnabled: false,
      appLockEnabled: true,
      inactivityTimeoutSeconds: 90,
      deviceInfo: _deviceInfo,
      isActive: true,
      securitySetupCompletedAt: null,
    );
    _profilesById[uid] = profile;
    _passwordsByEmail[normalizedEmail] = password;
    _emit();
    return profile;
  }

  void setActiveProfile(String uid) {
    if (!_profilesById.containsKey(uid)) {
      return;
    }
    _activeUserId = uid;
    _emit();
  }

  void updateProfile({
    String? uid,
    String? fullName,
    String? email,
    bool? trustedDeviceEnabled,
    bool? biometricEnabled,
    bool? appLockEnabled,
    int? inactivityTimeoutSeconds,
  }) {
    final targetUid = uid ?? _activeUserId;
    final current = _profilesById[targetUid];
    if (current == null) {
      return;
    }
    final normalizedEmail = email?.trim().toLowerCase();
    final updated = current.copyWith(
      uid: targetUid,
      fullName: fullName,
      email: normalizedEmail,
      trustedDeviceEnabled: trustedDeviceEnabled,
      biometricEnabled: biometricEnabled,
      appLockEnabled: appLockEnabled,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds,
      updatedAt: DateTime.now(),
    );
    _profilesById[targetUid] = updated;
    final oldEmail = current.email.trim().toLowerCase();
    if (normalizedEmail != null && normalizedEmail != oldEmail) {
      final existingPassword = _passwordsByEmail.remove(oldEmail);
      if (existingPassword != null) {
        _passwordsByEmail[normalizedEmail] = existingPassword;
      }
    }
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

  List<Installment> installmentsByUnit(String unitId) => List.unmodifiable(
    allInstallments().where((item) => item.unitId == unitId).toList(),
  );

  List<PaymentRecord> allPayments() => List.unmodifiable(
    _payments.toList()..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
  );

  List<PaymentRecord> paymentsByProperty(String propertyId) =>
      List.unmodifiable(
        allPayments().where((item) => item.propertyId == propertyId).toList(),
      );

  List<PaymentRecord> paymentsByUnit(String unitId) => List.unmodifiable(
    allPayments().where((item) => item.unitId == unitId).toList(),
  );

  List<MaterialExpenseEntry> allMaterialExpenses() => List.unmodifiable(
    _materialExpenses.where((item) => !item.archived).toList()
      ..sort((a, b) => b.date.compareTo(a.date)),
  );

  List<MaterialExpenseEntry> materialExpensesByProperty(String propertyId) =>
      List.unmodifiable(
        allMaterialExpenses()
            .where((item) => item.propertyId == propertyId)
            .toList(),
      );

  List<PartnerLedgerEntry> allPartnerLedgerEntries() => List.unmodifiable(
    _partnerLedgerEntries.where((item) => !item.archived).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  List<ActivityLogEntry> recentActivity({String? propertyId}) {
    final source = propertyId == null
        ? _activity
        : _activity.where((item) {
            final scopedPropertyId = item.metadata['propertyId'] as String?;
            return scopedPropertyId == propertyId ||
                item.entityId == propertyId;
          }).toList();
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
    _upsert(_expenses, expense.id, expense.copyWith(updatedAt: DateTime.now()));
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
    _upsert(_partners, partner.id, partner.copyWith(updatedAt: DateTime.now()));
    _emit();
  }

  Future<void> saveUnit(UnitSale unit) async {
    _upsert(_units, unit.id, unit.copyWith(updatedAt: DateTime.now()));
    _emit();
  }

  Future<void> deleteUnit(String unitId) async {
    _units.removeWhere((item) => item.id == unitId);
    _plans.removeWhere((item) => item.unitId == unitId);
    _installments.removeWhere((item) => item.unitId == unitId);
    _payments.removeWhere((item) => item.unitId == unitId);
    _emit();
  }

  Future<void> savePlan(InstallmentPlan plan) async {
    _upsert(_plans, plan.id, plan.copyWith(updatedAt: DateTime.now()));
    _emit();
  }

  Future<void> saveInstallment(Installment installment) async {
    _upsert(
      _installments,
      installment.id,
      installment.copyWith(updatedAt: DateTime.now()),
    );
    _emit();
  }

  Future<void> deleteInstallment(String installmentId) async {
    _installments.removeWhere((item) => item.id == installmentId);
    _payments.removeWhere((item) => item.installmentId == installmentId);
    _emit();
  }

  Future<void> recordPayment(PaymentRecord payment) async {
    _upsert(_payments, payment.id, payment.copyWith(updatedAt: DateTime.now()));
    _emit();
  }

  Future<void> deletePayment(String paymentId) async {
    _payments.removeWhere((item) => item.id == paymentId);
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

  Future<void> saveMaterialExpense(MaterialExpenseEntry entry) async {
    _upsert(
      _materialExpenses,
      entry.id,
      entry.copyWith(updatedAt: DateTime.now()),
    );
    _emit();
  }

  Future<void> softDeleteMaterialExpense(String entryId) async {
    final index = _materialExpenses.indexWhere((item) => item.id == entryId);
    if (index == -1) return;
    _materialExpenses[index] = _materialExpenses[index].copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  Future<void> savePartnerLedgerEntry(PartnerLedgerEntry entry) async {
    _upsert(
      _partnerLedgerEntries,
      entry.id,
      entry.copyWith(updatedAt: DateTime.now()),
    );
    _emit();
  }

  Future<void> softDeletePartnerLedgerEntry(String entryId) async {
    final index = _partnerLedgerEntries.indexWhere(
      (item) => item.id == entryId,
    );
    if (index == -1) return;
    _partnerLedgerEntries[index] = _partnerLedgerEntries[index].copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  Future<void> logActivity(ActivityLogEntry entry) async {
    _upsert(_activity, entry.id, entry);
    _emit();
  }

  Future<void> createNotification(AppNotificationItem item) async {
    _upsert(_notifications, item.id, item);
    _emit();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    _emit();
  }

  void _emit() {
    _changes.add(DateTime.now().microsecondsSinceEpoch);
  }

  void _seed() {
    final now = DateTime.now();
    _activeUserId = 'mock-user';
    _profilesById = {
      'mock-user': AppUser(
        uid: 'mock-user',
        phone: '',
        fullName: 'Finance Partner',
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
      ),
      'partner-user-2': AppUser(
        uid: 'partner-user-2',
        phone: '',
        fullName: 'Mohamed Khaled',
        email: 'mohamed@mock.local',
        createdAt: now.subtract(const Duration(days: 135)),
        updatedAt: now.subtract(const Duration(days: 3)),
        lastLoginAt: now.subtract(const Duration(days: 3)),
        role: UserRole.partner,
        trustedDeviceEnabled: false,
        biometricEnabled: false,
        appLockEnabled: true,
        inactivityTimeoutSeconds: 90,
        deviceInfo: _deviceInfo,
        isActive: true,
        securitySetupCompletedAt: null,
      ),
    };
    _passwordsByEmail = {
      'demo@mock.local': '1234567890',
      'mohamed@mock.local': '1234567890',
    };

    _partners = [
      Partner(
        id: 'partner_1',
        userId: 'mock-user',
        linkedEmail: 'demo@mock.local',
        name: 'Ahmed El Masry',
        shareRatio: 0.5,
        contributionTotal: 900000,
        createdAt: now.subtract(const Duration(days: 140)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Partner(
        id: 'partner_2',
        userId: 'partner-user-2',
        linkedEmail: 'mohamed@mock.local',
        name: 'Mohamed Khaled',
        shareRatio: 0.3,
        contributionTotal: 540000,
        createdAt: now.subtract(const Duration(days: 135)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Partner(
        id: 'partner_3',
        userId: '',
        linkedEmail: 'demo@mock.local',
        name: 'Sara Ali',
        shareRatio: 0.2,
        contributionTotal: 360000,
        createdAt: now.subtract(const Duration(days: 130)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    _properties = [
      PropertyProject(
        id: 'property_1',
        name: 'Nile Compound',
        location: 'New Cairo',
        description: 'Residential project with installment collections.',
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
        name: 'Oasis Tower',
        location: 'NAC',
        description: 'Mixed-use building with active suppliers.',
        status: PropertyStatus.active,
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
        customerName: 'Amr Hassan',
        customerPhone: '01000000001',
        saleAmount: 2200000,
        totalPrice: 2200000,
        contractAmount: 2200000,
        downPayment: 400000,
        remainingAmount: 1200000,
        installmentScheduleCount: 6,
        paymentPlanType: PaymentPlanType.installment,
        status: UnitStatus.sold,
        notes: 'Priority handover client',
        projectedCompletionDate: now.add(const Duration(days: 58)),
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
        customerName: 'Mona Samir',
        customerPhone: '01000000002',
        saleAmount: 2450000,
        totalPrice: 2450000,
        contractAmount: 2450000,
        downPayment: 600000,
        remainingAmount: 1850000,
        installmentScheduleCount: 8,
        paymentPlanType: PaymentPlanType.installment,
        status: UnitStatus.reserved,
        notes: 'Reservation signed',
        projectedCompletionDate: now.add(const Duration(days: 210)),
        createdAt: now.subtract(const Duration(days: 55)),
        updatedAt: now.subtract(const Duration(days: 4)),
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
        description: 'Concrete foundation batch',
        paidByPartnerId: 'partner_1',
        paymentMethod: PaymentMethod.bankTransfer,
        date: now.subtract(const Duration(days: 18)),
        attachmentUrl: null,
        notes: 'Stage 1 foundation',
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
        description: 'Digital campaign',
        paidByPartnerId: 'partner_2',
        paymentMethod: PaymentMethod.wallet,
        date: now.subtract(const Duration(days: 9)),
        attachmentUrl: null,
        notes: 'Lead generation',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 9)),
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
      InstallmentPlan(
        id: 'plan_2',
        propertyId: 'property_1',
        unitId: 'unit_2',
        installmentCount: 8,
        startDate: now.subtract(const Duration(days: 30)),
        intervalDays: 30,
        installmentAmount: 231250,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
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
        notes: 'Paid in full',
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
        notes: '',
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
        notes: 'Split transfer',
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
        notes: 'Reminder sent',
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
        notes: '',
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
        notes: '',
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      for (var i = 0; i < 8; i++)
        Installment(
          id: 'unit2_inst_${i + 1}',
          planId: 'plan_2',
          propertyId: 'property_1',
          unitId: 'unit_2',
          sequence: i + 1,
          amount: 231250,
          paidAmount: i == 0 ? 150000 : 0,
          dueDate: now.add(Duration(days: 30 * (i + 1))),
          status: i == 0
              ? InstallmentStatus.partiallyPaid
              : InstallmentStatus.pending,
          notes: i == 0 ? 'Advance installment' : '',
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 1)),
          createdBy: 'mock-user',
          updatedBy: 'mock-user',
        ),
    ];

    _payments = [
      PaymentRecord(
        id: 'payment_1',
        propertyId: 'property_1',
        unitId: 'unit_1',
        payerName: 'Amr Hassan',
        customerName: 'Amr Hassan',
        installmentId: 'inst_1',
        amount: 300000,
        receivedAt: now.subtract(const Duration(days: 120)),
        paymentMethod: PaymentMethod.bankTransfer,
        paymentSource: 'Bank Transfer',
        notes: 'Installment 1',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      PaymentRecord(
        id: 'payment_2',
        propertyId: 'property_1',
        unitId: 'unit_1',
        payerName: 'Amr Hassan',
        customerName: 'Amr Hassan',
        installmentId: 'inst_2',
        amount: 300000,
        receivedAt: now.subtract(const Duration(days: 90)),
        paymentMethod: PaymentMethod.bankTransfer,
        paymentSource: 'Bank Transfer',
        notes: 'Installment 2',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 90)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      PaymentRecord(
        id: 'payment_3',
        propertyId: 'property_1',
        unitId: 'unit_1',
        payerName: 'Amr Hassan',
        customerName: 'Amr Hassan',
        installmentId: 'inst_3',
        amount: 180000,
        receivedAt: now.subtract(const Duration(days: 20)),
        paymentMethod: PaymentMethod.cash,
        paymentSource: 'Cash',
        notes: 'Partial payment',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
      PaymentRecord(
        id: 'payment_4',
        propertyId: 'property_1',
        unitId: 'unit_2',
        payerName: 'Mona Samir',
        customerName: 'Mona Samir',
        installmentId: 'unit2_inst_1',
        amount: 150000,
        receivedAt: now.subtract(const Duration(days: 4)),
        paymentMethod: PaymentMethod.bankTransfer,
        paymentSource: 'Collection Team',
        notes: 'First split payment',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
      ),
    ];

    _materialExpenses = [
      MaterialExpenseEntry(
        id: 'material_1',
        propertyId: 'property_1',
        date: now.subtract(const Duration(days: 7)),
        materialCategory: MaterialCategory.brick,
        itemName: 'Red Brick',
        quantity: 10000,
        unitPrice: 4,
        totalPrice: 40000,
        supplierName: 'El Amal Trading',
        amountPaid: 25000,
        amountRemaining: 15000,
        dueDate: now.add(const Duration(days: 3)),
        notes: 'Ground floor walls',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        archived: false,
      ),
      MaterialExpenseEntry(
        id: 'material_2',
        propertyId: 'property_2',
        date: now.subtract(const Duration(days: 5)),
        materialCategory: MaterialCategory.steel,
        itemName: 'Rebar',
        quantity: 12,
        unitPrice: 15000,
        totalPrice: 180000,
        supplierName: 'Delta Steel',
        amountPaid: 60000,
        amountRemaining: 120000,
        dueDate: now.subtract(const Duration(days: 1)),
        notes: 'Tower core',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        archived: false,
      ),
    ];

    _partnerLedgerEntries = [
      PartnerLedgerEntry(
        id: 'ledger_1',
        partnerId: 'partner_1',
        propertyId: 'property_1',
        entryType: PartnerLedgerEntryType.contribution,
        amount: 150000,
        notes: 'Capital top-up',
        authorizedBy: 'mock-user',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 12)),
        archived: false,
      ),
      PartnerLedgerEntry(
        id: 'ledger_2',
        partnerId: 'partner_2',
        propertyId: 'property_1',
        entryType: PartnerLedgerEntryType.settlement,
        amount: 90000,
        notes: 'Quarterly settlement',
        authorizedBy: 'mock-user',
        createdBy: 'mock-user',
        updatedBy: 'mock-user',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
        archived: false,
      ),
    ];

    _activity = [
      ActivityLogEntry(
        id: 'activity_1',
        actorId: 'mock-user',
        actorName: 'Finance Partner',
        action: 'property_created',
        entityType: 'property',
        entityId: 'property_1',
        createdAt: now.subtract(const Duration(days: 30)),
        metadata: const {'propertyId': 'property_1'},
      ),
      ActivityLogEntry(
        id: 'activity_2',
        actorId: 'mock-user',
        actorName: 'Finance Partner',
        action: 'material_expense_created',
        entityType: 'material_expense',
        entityId: 'material_1',
        createdAt: now.subtract(const Duration(days: 7)),
        metadata: const {'propertyId': 'property_1', 'amount': 40000},
      ),
    ];

    _notifications = [
      AppNotificationItem(
        id: 'notification_1',
        userId: 'mock-user',
        title: 'Overdue Installment',
        body: 'Unit A-101 has an overdue installment.',
        type: NotificationType.overdueInstallment,
        route: AppRoutes.propertyDetails('property_1'),
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 8)),
        referenceKey: 'installment-overdue-inst_4',
        metadata: const {},
      ),
      AppNotificationItem(
        id: 'notification_2',
        userId: 'mock-user',
        title: 'Supplier Payment Due',
        body: 'Delta Steel still has EGP 120,000 outstanding.',
        type: NotificationType.supplierPaymentDue,
        route: AppRoutes.expenses,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        referenceKey: 'supplier-due-material_2',
        metadata: const {},
      ),
      AppNotificationItem(
        id: 'notification_3',
        userId: 'mock-user',
        title: 'طلب شراكة جديد',
        body: 'Sara Ali أرسلت طلب ربط شريك على هذا الحساب.',
        type: NotificationType.partnerLinkRequest,
        route: AppRoutes.partners,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        referenceKey: 'partner-link-request-partner_3-mock-user',
        metadata: const {
          'partnerId': 'partner_3',
          'requesterUserId': 'partner-user-3',
          'requesterName': 'Sara Ali',
          'requesterEmail': 'sara@mock.local',
          'partnerName': 'Sara Ali',
        },
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
    ];
  }

  void _upsert<T>(List<T> items, String id, T value) {
    final index = items.indexWhere((item) => _idOf(item as Object) == id);
    if (index == -1) {
      items.add(value);
    } else {
      items[index] = value;
    }
  }

  String _idOf(Object item) {
    return switch (item) {
      PropertyProject value => value.id,
      Partner value => value.id,
      ExpenseRecord value => value.id,
      UnitSale value => value.id,
      InstallmentPlan value => value.id,
      Installment value => value.id,
      PaymentRecord value => value.id,
      MaterialExpenseEntry value => value.id,
      PartnerLedgerEntry value => value.id,
      ActivityLogEntry value => value.id,
      AppNotificationItem value => value.id,
      _ => '',
    };
  }
}
