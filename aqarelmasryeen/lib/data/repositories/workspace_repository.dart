import 'dart:convert';

import 'package:aqarelmasryeen/core/constants/storage_keys.dart';
import 'package:aqarelmasryeen/core/services/local_cache_service.dart';
import 'package:aqarelmasryeen/core/services/notification_service.dart';
import 'package:aqarelmasryeen/core/services/session_service.dart';
import 'package:aqarelmasryeen/data/models/app_role.dart';
import 'package:aqarelmasryeen/data/models/user_profile.dart';
import 'package:aqarelmasryeen/data/models/workspace_models.dart';
import 'package:get/get.dart';

class WorkspaceRepository extends GetxService {
  WorkspaceRepository({
    required LocalCacheService localCacheService,
    required SessionService sessionService,
    required NotificationService notificationService,
  }) : _localCacheService = localCacheService,
       _sessionService = sessionService,
       _notificationService = notificationService;

  final LocalCacheService _localCacheService;
  final SessionService _sessionService;
  final NotificationService _notificationService;

  final RxBool isReady = false.obs;
  final Rx<AppRole> currentRole = AppRole.owner.obs;
  final RxList<UserProfile> users = <UserProfile>[].obs;
  final RxList<PropertyRecord> properties = <PropertyRecord>[].obs;
  final RxList<UnitRecord> units = <UnitRecord>[].obs;
  final RxList<CustomerRecord> customers = <CustomerRecord>[].obs;
  final RxList<SalesContractRecord> salesContracts = <SalesContractRecord>[].obs;
  final RxList<InstallmentRecord> installments = <InstallmentRecord>[].obs;
  final RxList<PaymentRecord> payments = <PaymentRecord>[].obs;
  final RxList<ExpenseRecord> expenses = <ExpenseRecord>[].obs;
  final RxList<AppNotificationRecord> notifications =
      <AppNotificationRecord>[].obs;
  final RxList<ActivityLogRecord> activityLogs = <ActivityLogRecord>[].obs;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      await refreshCurrentRole();
      return;
    }

    await _localCacheService.initialize();
    await refreshCurrentRole();
    final encoded = await _localCacheService.readString(
      StorageKeys.workspaceSnapshot,
    );

    if (encoded == null || encoded.isEmpty) {
      _seedWorkspace();
      await _saveSnapshot();
    } else {
      _decodeSnapshot(encoded);
    }

    _refreshDerivedState();
    _initialized = true;
    isReady.value = true;
  }

  Future<void> refreshCurrentRole() async {
    final session = await _sessionService.readCachedSession();
    currentRole.value = AppRole.fromKey(session?.roleKey);
  }

  bool get canManageUsers => currentRole.value == AppRole.owner;
  bool get canManageProperties =>
      currentRole.value == AppRole.owner ||
      currentRole.value == AppRole.employee;
  bool get canManageFinance =>
      currentRole.value == AppRole.owner ||
      currentRole.value == AppRole.accountant;

  double get totalSalesValue => salesContracts.fold<double>(
    0,
    (sum, contract) => sum + contract.netPrice,
  );

  double get totalExpensesValue =>
      expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

  double get totalCollectedValue =>
      payments.fold<double>(0, (sum, payment) => sum + payment.amount) +
      salesContracts.fold<double>(0, (sum, contract) => sum + contract.downPayment);

  double get totalReceivablesValue =>
      (totalSalesValue - totalCollectedValue).clamp(0, double.infinity);

  int get overdueInstallmentsCount => installments.where((installment) {
    return _statusForInstallment(
          installment.paidAmount,
          installment.amount,
          installment.dueDate,
        ) ==
        InstallmentStatus.overdue;
  }).length;

  int get activeContractsCount => salesContracts.length;

  List<ActivityLogRecord> get recentActivity {
    final items = activityLogs.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(6).toList();
  }

  List<AppNotificationRecord> get recentNotifications {
    final items = notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(8).toList();
  }

  List<PropertyOverviewSummary> get propertySummaries {
    return properties.map((property) {
      final propertyUnits = units
          .where((unit) => unit.propertyId == property.id)
          .toList();
      final propertyContracts = salesContracts
          .where((contract) => contract.propertyId == property.id)
          .toList();
      final propertyExpenses = expenses
          .where((expense) => expense.propertyId == property.id)
          .toList();
      final soldUnits = propertyUnits
          .where(
            (unit) =>
                unit.status == UnitStatus.sold ||
                unit.status == UnitStatus.installment,
          )
          .length;
      final availableUnits = propertyUnits
          .where((unit) => unit.status == UnitStatus.available)
          .length;
      final reservedUnits = propertyUnits
          .where((unit) => unit.status == UnitStatus.reserved)
          .length;
      final totalSales = propertyContracts.fold<double>(
        0,
        (sum, contract) => sum + contract.netPrice,
      );
      final downPayments = propertyContracts.fold<double>(
        0,
        (sum, contract) => sum + contract.downPayment,
      );
      final contractIds = propertyContracts.map((item) => item.id).toSet();
      final totalPayments = payments
          .where((payment) => contractIds.contains(payment.saleContractId))
          .fold<double>(0, (sum, payment) => sum + payment.amount);
      final totalExpenses = propertyExpenses.fold<double>(
        0,
        (sum, expense) => sum + expense.amount,
      );
      return PropertyOverviewSummary(
        property: property.copyWith(unitsCount: propertyUnits.length),
        totalUnits: propertyUnits.length,
        soldUnits: soldUnits,
        availableUnits: availableUnits,
        reservedUnits: reservedUnits,
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        remainingReceivables:
            (totalSales - downPayments - totalPayments).clamp(0, double.infinity),
        progress: propertyUnits.isEmpty ? 0 : soldUnits / propertyUnits.length,
      );
    }).toList()
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));
  }

  List<ExpenseGroupSummary> get expenseTotalsByUser {
    final totals = <String, double>{};
    for (final expense in expenses) {
      final name = userNameById(expense.paidByUserId);
      totals[name] = (totals[name] ?? 0) + expense.amount;
    }
    return totals.entries
        .map((entry) => ExpenseGroupSummary(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  List<ExpenseGroupSummary> get expenseTotalsByCategory {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.category.key] = (totals[expense.category.key] ?? 0) + expense.amount;
    }
    return totals.entries
        .map((entry) => ExpenseGroupSummary(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  String userNameById(String id) {
    return users.firstWhereOrNull((user) => user.id == id)?.fullName ??
        'unknown_user'.tr;
  }

  String propertyNameById(String id) {
    return properties.firstWhereOrNull((item) => item.id == id)?.name ??
        'unknown_property'.tr;
  }

  String customerNameById(String id) {
    return customers.firstWhereOrNull((item) => item.id == id)?.fullName ??
        'unknown_customer'.tr;
  }

  UnitRecord? unitById(String id) {
    return units.firstWhereOrNull((item) => item.id == id);
  }

  PropertyRecord? propertyById(String id) {
    return properties.firstWhereOrNull((item) => item.id == id);
  }

  SalesContractRecord? contractById(String id) {
    return salesContracts.firstWhereOrNull((item) => item.id == id);
  }

  List<InstallmentRecord> installmentsForContract(String contractId) {
    return installments.where((item) => item.saleContractId == contractId).toList()
      ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
  }

  List<PaymentRecord> paymentsForContract(String contractId) {
    return payments.where((item) => item.saleContractId == contractId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<UnitRecord> unitsForProperty(String propertyId) {
    return units.where((item) => item.propertyId == propertyId).toList()
      ..sort((a, b) => a.floorNumber.compareTo(b.floorNumber));
  }

  List<InstallmentRecord> overdueInstallments() {
    final items = installments.where((installment) {
      return _statusForInstallment(
            installment.paidAmount,
            installment.amount,
            installment.dueDate,
          ) ==
          InstallmentStatus.overdue;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  List<CustomerStatementLine> statementForCustomer(String customerId) {
    final contractIds = salesContracts
        .where((contract) => contract.customerId == customerId)
        .map((contract) => contract.id)
        .toSet();
    final lines = <CustomerStatementLine>[];

    for (final contract in salesContracts.where((item) => contractIds.contains(item.id))) {
      lines.add(
        CustomerStatementLine(
          title: 'contract_statement_contract'.tr,
          amount: contract.netPrice,
          date: contract.createdAt,
        ),
      );
      if (contract.downPayment > 0) {
        lines.add(
          CustomerStatementLine(
            title: 'contract_statement_down_payment'.tr,
            amount: -contract.downPayment,
            date: contract.startDate,
          ),
        );
      }
    }

    for (final payment in payments.where((item) => contractIds.contains(item.saleContractId))) {
      lines.add(
        CustomerStatementLine(
          title: 'contract_statement_payment'.tr,
          amount: -payment.amount,
          date: payment.date,
        ),
      );
    }

    lines.sort((a, b) => a.date.compareTo(b.date));
    return lines;
  }

  String formatAmount(double value) => 'EGP ${value.toStringAsFixed(0)}';

  Future<void> addOrUpdateUser(UserProfile profile) async {
    final index = users.indexWhere((item) => item.id == profile.id);
    final updated = profile.copyWith(updatedAt: DateTime.now());
    if (index == -1) {
      users.add(updated);
      await _recordActivity(
        title: 'activity_user_added'.tr,
        description: updated.fullName,
        entityType: 'user',
        entityId: updated.id,
      );
    } else {
      users[index] = updated;
      await _recordActivity(
        title: 'activity_user_updated'.tr,
        description: updated.fullName,
        entityType: 'user',
        entityId: updated.id,
      );
    }
    await _saveAfterMutation();
  }

  Future<void> deleteUser(String userId) async {
    users.removeWhere((item) => item.id == userId);
    properties.value = properties
        .map(
          (property) => property.copyWith(
            assignedUserIds: property.assignedUserIds
                .where((id) => id != userId)
                .toList(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();
    await _recordActivity(
      title: 'activity_user_removed'.tr,
      description: userId,
      entityType: 'user',
      entityId: userId,
    );
    await _saveAfterMutation();
  }

  Future<void> addOrUpdateProperty(PropertyRecord property) async {
    final updated = property.copyWith(updatedAt: DateTime.now());
    final index = properties.indexWhere((item) => item.id == property.id);
    if (index == -1) {
      properties.add(updated);
      await _pushNotification(
        title: 'notification_property_added_title'.tr,
        body: updated.name,
        category: NotificationCategory.property,
        section: 'properties',
        entityId: updated.id,
      );
      await _recordActivity(
        title: 'activity_property_added'.tr,
        description: updated.name,
        entityType: 'property',
        entityId: updated.id,
      );
    } else {
      properties[index] = updated;
      await _recordActivity(
        title: 'activity_property_updated'.tr,
        description: updated.name,
        entityType: 'property',
        entityId: updated.id,
      );
    }
    await _saveAfterMutation();
  }

  Future<void> addOrUpdateUnit(UnitRecord unit) async {
    final updated = unit.copyWith(updatedAt: DateTime.now());
    final index = units.indexWhere((item) => item.id == unit.id);
    if (index == -1) {
      units.add(updated);
      await _recordActivity(
        title: 'activity_unit_added'.tr,
        description: updated.unitNumber,
        entityType: 'unit',
        entityId: updated.id,
      );
    } else {
      units[index] = updated;
      await _recordActivity(
        title: 'activity_unit_updated'.tr,
        description: updated.unitNumber,
        entityType: 'unit',
        entityId: updated.id,
      );
    }
    await _saveAfterMutation();
  }

  Future<String> addOrUpdateCustomer(CustomerRecord customer) async {
    final id = customer.id.isEmpty ? _newId('customer') : customer.id;
    final updated = customer.copyWith(id: id);
    final index = customers.indexWhere((item) => item.id == id);
    if (index == -1) {
      customers.add(updated);
      await _recordActivity(
        title: 'activity_customer_added'.tr,
        description: updated.fullName,
        entityType: 'customer',
        entityId: updated.id,
      );
    } else {
      customers[index] = updated;
    }
    await _saveAfterMutation();
    return id;
  }

  Future<void> addOrUpdateContract(SalesContractRecord contract) async {
    final unit = unitById(contract.unitId);
    if (unit == null) {
      throw StateError('missing_unit'.tr);
    }

    final updated = contract.copyWith(updatedAt: DateTime.now());
    final existing = salesContracts.firstWhereOrNull((item) => item.id == contract.id);
    final existingIndex = salesContracts.indexWhere((item) => item.id == contract.id);
    final hasPayments = payments.any((item) => item.saleContractId == contract.id);

    if (existingIndex == -1) {
      salesContracts.add(updated);
      installments.addAll(_generateInstallments(updated));
      await _pushNotification(
        title: 'notification_contract_added_title'.tr,
        body: '${customerNameById(updated.customerId)} - ${unit.unitNumber}',
        category: NotificationCategory.assignment,
        section: 'sales',
        entityId: updated.id,
      );
      await _recordActivity(
        title: 'activity_contract_added'.tr,
        description: unit.unitNumber,
        entityType: 'contract',
        entityId: updated.id,
      );
    } else {
      salesContracts[existingIndex] = updated;
      if (existing != null &&
          !hasPayments &&
          _requiresInstallmentRebuild(existing, updated)) {
        installments.removeWhere((item) => item.saleContractId == updated.id);
        installments.addAll(_generateInstallments(updated));
      }
      await _recordActivity(
        title: 'activity_contract_updated'.tr,
        description: unit.unitNumber,
        entityType: 'contract',
        entityId: updated.id,
      );
    }

    final unitIndex = units.indexWhere((item) => item.id == unit.id);
    units[unitIndex] = unit.copyWith(
      saleContractId: updated.id,
      status: updated.financedAmount > 0 ? UnitStatus.installment : UnitStatus.sold,
      updatedAt: DateTime.now(),
    );
    await _saveAfterMutation();
  }

  Future<void> recordPayment({
    required String installmentId,
    required double amount,
    required String createdByUserId,
    String? notes,
  }) async {
    final installmentIndex = installments.indexWhere((item) => item.id == installmentId);
    if (installmentIndex == -1) {
      throw StateError('missing_installment'.tr);
    }
    final installment = installments[installmentIndex];
    final payable = amount.clamp(0, installment.remainingAmount);
    if (payable <= 0) {
      throw StateError('invalid_payment_amount'.tr);
    }

    final now = DateTime.now();
    final paidAmount = installment.paidAmount + payable;
    installments[installmentIndex] = installment.copyWith(
      paidAmount: paidAmount,
      paymentDate: now,
      status: _statusForInstallment(paidAmount, installment.amount, installment.dueDate),
      updatedAt: now,
    );
    payments.add(
      PaymentRecord(
        id: _newId('payment'),
        saleContractId: installment.saleContractId,
        installmentId: installmentId,
        amount: payable.toDouble(),
        date: now,
        createdByUserId: createdByUserId,
        createdAt: now,
        notes: notes,
      ),
    );
    await _pushNotification(
      title: 'notification_payment_title'.tr,
      body: formatAmount(payable.toDouble()),
      category: NotificationCategory.payment,
      section: 'sales',
      entityId: installment.saleContractId,
    );
    await _recordActivity(
      title: 'activity_payment_added'.tr,
      description: formatAmount(payable.toDouble()),
      entityType: 'payment',
      entityId: installmentId,
      actorUserId: createdByUserId,
    );
    await _saveAfterMutation();
  }

  Future<void> addOrUpdateExpense(ExpenseRecord expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    final index = expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      expenses.add(updated);
      await _pushNotification(
        title: 'notification_expense_title'.tr,
        body: '${updated.title} - ${formatAmount(updated.amount)}',
        category: NotificationCategory.expense,
        section: 'expenses',
        entityId: updated.id,
      );
      await _recordActivity(
        title: 'activity_expense_added'.tr,
        description: updated.title,
        entityType: 'expense',
        entityId: updated.id,
      );
    } else {
      expenses[index] = updated;
      await _recordActivity(
        title: 'activity_expense_updated'.tr,
        description: updated.title,
        entityType: 'expense',
        entityId: updated.id,
      );
    }
    await _saveAfterMutation();
  }

  Future<void> deleteExpense(String expenseId) async {
    expenses.removeWhere((item) => item.id == expenseId);
    await _recordActivity(
      title: 'activity_expense_removed'.tr,
      description: expenseId,
      entityType: 'expense',
      entityId: expenseId,
    );
    await _saveAfterMutation();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1) {
      return;
    }
    notifications[index] = notifications[index].copyWith(isRead: true);
    await _saveSnapshot();
  }

  Future<void> markAllNotificationsRead() async {
    notifications.value = notifications
        .map((item) => item.copyWith(isRead: true))
        .toList();
    await _saveSnapshot();
  }

  void _decodeSnapshot(String encoded) {
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    users.value = (decoded['users'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => UserProfile.fromJsonMap(item as Map<String, dynamic>))
        .toList();
    properties.value =
        (decoded['properties'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => PropertyRecord.fromJsonMap(item as Map<String, dynamic>))
            .toList();
    units.value = (decoded['units'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => UnitRecord.fromJsonMap(item as Map<String, dynamic>))
        .toList();
    customers.value =
        (decoded['customers'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => CustomerRecord.fromJsonMap(item as Map<String, dynamic>))
            .toList();
    salesContracts.value =
        (decoded['salesContracts'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) =>
                  SalesContractRecord.fromJsonMap(item as Map<String, dynamic>),
            )
            .toList();
    installments.value =
        (decoded['installments'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) =>
                  InstallmentRecord.fromJsonMap(item as Map<String, dynamic>),
            )
            .toList();
    payments.value =
        (decoded['payments'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => PaymentRecord.fromJsonMap(item as Map<String, dynamic>))
            .toList();
    expenses.value =
        (decoded['expenses'] as List<dynamic>? ?? const <dynamic>[])
            .map((item) => ExpenseRecord.fromJsonMap(item as Map<String, dynamic>))
            .toList();
    notifications.value =
        (decoded['notifications'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) =>
                  AppNotificationRecord.fromJsonMap(item as Map<String, dynamic>),
            )
            .toList();
    activityLogs.value =
        (decoded['activityLogs'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (item) =>
                  ActivityLogRecord.fromJsonMap(item as Map<String, dynamic>),
            )
            .toList();
  }

  void _seedWorkspace() {
    final now = DateTime.now();
    users.assignAll([
      UserProfile(
        id: 'user_owner',
        fullName: 'أحمد المصري',
        phone: '+201001112233',
        email: 'owner@aqar.app',
        role: AppRole.owner,
        assignedProperties: const ['property_palm', 'property_capital'],
        isActive: true,
        notes: 'مدير النظام',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
      UserProfile(
        id: 'user_accountant',
        fullName: 'منة خالد',
        phone: '+201009998877',
        email: 'accounting@aqar.app',
        role: AppRole.accountant,
        assignedProperties: const ['property_palm', 'property_capital'],
        isActive: true,
        notes: 'محاسبة رئيسية',
        createdAt: now.subtract(const Duration(days: 110)),
        updatedAt: now,
      ),
      UserProfile(
        id: 'user_employee',
        fullName: 'محمد سامح',
        phone: '+201007776655',
        email: null,
        role: AppRole.employee,
        assignedProperties: const ['property_nile'],
        isActive: true,
        notes: 'متابعة تنفيذ',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
    ]);
    properties.assignAll([
      PropertyRecord(
        id: 'property_palm',
        name: 'Palm View Residence',
        code: 'PVR-01',
        location: 'القاهرة الجديدة',
        description: 'مشروع سكني جاهز للبيع والتحصيل.',
        floorsCount: 8,
        unitsCount: 0,
        status: PropertyStatus.active,
        assignedUserIds: const ['user_owner', 'user_accountant'],
        attachments: const [],
        createdAt: now.subtract(const Duration(days: 140)),
        updatedAt: now,
      ),
      PropertyRecord(
        id: 'property_nile',
        name: 'Nile Crown Towers',
        code: 'NCT-04',
        location: 'المعادي',
        description: 'برج إداري وتجاري قيد التنفيذ.',
        floorsCount: 12,
        unitsCount: 0,
        status: PropertyStatus.construction,
        assignedUserIds: const ['user_owner', 'user_employee'],
        attachments: const [],
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now,
      ),
      PropertyRecord(
        id: 'property_capital',
        name: 'East Gate Plaza',
        code: 'EGP-09',
        location: 'العاصمة الإدارية',
        description: 'مشروع تجاري بعقود تقسيط نشطة.',
        floorsCount: 10,
        unitsCount: 0,
        status: PropertyStatus.collection,
        assignedUserIds: const ['user_owner', 'user_accountant'],
        attachments: const [],
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ),
    ]);
    units.assignAll([
      UnitRecord(
        id: 'unit_palm_101',
        propertyId: 'property_palm',
        unitNumber: 'A-101',
        floorNumber: 1,
        type: UnitType.apartment,
        area: 155,
        price: 2500000,
        status: UnitStatus.installment,
        notes: 'واجهة رئيسية',
        saleContractId: 'contract_1',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
      UnitRecord(
        id: 'unit_palm_205',
        propertyId: 'property_palm',
        unitNumber: 'B-205',
        floorNumber: 2,
        type: UnitType.apartment,
        area: 165,
        price: 2850000,
        status: UnitStatus.available,
        notes: 'جاهزة للبيع',
        createdAt: now.subtract(const Duration(days: 80)),
        updatedAt: now,
      ),
      UnitRecord(
        id: 'unit_nile_s1',
        propertyId: 'property_nile',
        unitNumber: 'S-01',
        floorNumber: 0,
        type: UnitType.shop,
        area: 88,
        price: 3200000,
        status: UnitStatus.reserved,
        notes: 'حجز أولي',
        createdAt: now.subtract(const Duration(days: 70)),
        updatedAt: now,
      ),
      UnitRecord(
        id: 'unit_capital_o1',
        propertyId: 'property_capital',
        unitNumber: 'OF-14',
        floorNumber: 4,
        type: UnitType.office,
        area: 120,
        price: 4100000,
        status: UnitStatus.installment,
        notes: 'خطة تقسيط شهرية',
        saleContractId: 'contract_2',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
    ]);
    customers.assignAll([
      CustomerRecord(
        id: 'customer_1',
        fullName: 'عمرو هشام',
        phone: '+201011223344',
        email: 'amr@example.com',
        notes: 'عميل متابع',
        createdAt: now.subtract(const Duration(days: 70)),
      ),
      CustomerRecord(
        id: 'customer_2',
        fullName: 'رحاب السيد',
        phone: '+201012229955',
        email: 'rehab@example.com',
        notes: 'شركة استثمار',
        createdAt: now.subtract(const Duration(days: 50)),
      ),
    ]);
    salesContracts.assignAll([
      SalesContractRecord(
        id: 'contract_1',
        propertyId: 'property_palm',
        unitId: 'unit_palm_101',
        customerId: 'customer_1',
        totalPrice: 2500000,
        discount: 50000,
        downPayment: 500000,
        installmentCount: 8,
        installmentFrequencyMonths: 1,
        startDate: now.subtract(const Duration(days: 150)),
        notes: 'عقد سكني',
        attachments: const [],
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now,
      ),
      SalesContractRecord(
        id: 'contract_2',
        propertyId: 'property_capital',
        unitId: 'unit_capital_o1',
        customerId: 'customer_2',
        totalPrice: 4100000,
        discount: 100000,
        downPayment: 900000,
        installmentCount: 10,
        installmentFrequencyMonths: 1,
        startDate: now.subtract(const Duration(days: 120)),
        notes: 'عقد إداري',
        attachments: const [],
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
    ]);
    installments.assignAll([
      InstallmentRecord(
        id: 'installment_1',
        saleContractId: 'contract_1',
        installmentNumber: 1,
        dueDate: now.subtract(const Duration(days: 120)),
        amount: 243750,
        paidAmount: 243750,
        status: InstallmentStatus.paid,
        paymentDate: now.subtract(const Duration(days: 118)),
        notes: '',
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now,
      ),
      InstallmentRecord(
        id: 'installment_2',
        saleContractId: 'contract_1',
        installmentNumber: 2,
        dueDate: now.subtract(const Duration(days: 30)),
        amount: 243750,
        paidAmount: 0,
        status: InstallmentStatus.overdue,
        notes: '',
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now,
      ),
      InstallmentRecord(
        id: 'installment_3',
        saleContractId: 'contract_2',
        installmentNumber: 1,
        dueDate: now.add(const Duration(days: 7)),
        amount: 310000,
        paidAmount: 0,
        status: InstallmentStatus.unpaid,
        notes: '',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
    ]);
    payments.assignAll([
      PaymentRecord(
        id: 'payment_1',
        saleContractId: 'contract_1',
        installmentId: 'installment_1',
        amount: 243750,
        date: now.subtract(const Duration(days: 118)),
        createdByUserId: 'user_accountant',
        createdAt: now.subtract(const Duration(days: 118)),
        notes: 'تحويل بنكي',
      ),
    ]);
    expenses.assignAll([
      ExpenseRecord(
        id: 'expense_1',
        propertyId: 'property_nile',
        paidByUserId: 'user_employee',
        category: ExpenseCategory.construction,
        title: 'دفعة خرسانة',
        description: 'توريد وصب الأساسات',
        amount: 680000,
        date: now.subtract(const Duration(days: 20)),
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
        notes: 'المرحلة الأولى',
      ),
      ExpenseRecord(
        id: 'expense_2',
        propertyId: 'property_palm',
        paidByUserId: 'user_accountant',
        category: ExpenseCategory.finishing,
        title: 'تشطيبات مدخل',
        description: 'رخام وإضاءة',
        amount: 185000,
        date: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now,
        notes: null,
      ),
    ]);
    notifications.assignAll([
      AppNotificationRecord(
        id: 'notification_1',
        title: 'قسط متأخر',
        body: 'العميل عمرو هشام لديه قسط متأخر',
        category: NotificationCategory.installment,
        section: 'sales',
        createdAt: now.subtract(const Duration(hours: 8)),
        isRead: false,
        entityId: 'contract_1',
      ),
    ]);
    activityLogs.assignAll([
      ActivityLogRecord(
        id: 'activity_1',
        title: 'تم تسجيل دفعة',
        description: 'دفعة أولى لعقد Palm View',
        entityType: 'payment',
        entityId: 'payment_1',
        createdAt: now.subtract(const Duration(days: 2)),
        actorUserId: 'user_accountant',
      ),
    ]);
  }

  Future<void> _saveAfterMutation() async {
    _refreshDerivedState();
    await _saveSnapshot();
  }

  void _refreshDerivedState() {
    properties.value = properties.map((property) {
      final propertyUnits = units.where((unit) => unit.propertyId == property.id).length;
      return property.copyWith(unitsCount: propertyUnits, updatedAt: DateTime.now());
    }).toList();
    installments.value = installments
        .map(
          (item) => item.copyWith(
            status: _statusForInstallment(item.paidAmount, item.amount, item.dueDate),
          ),
        )
        .toList();
  }

  Future<void> _recordActivity({
    required String title,
    required String description,
    required String entityType,
    required String entityId,
    String? actorUserId,
  }) async {
    activityLogs.insert(
      0,
      ActivityLogRecord(
        id: _newId('activity'),
        title: title,
        description: description,
        entityType: entityType,
        entityId: entityId,
        createdAt: DateTime.now(),
        actorUserId: actorUserId,
      ),
    );
  }

  Future<void> _pushNotification({
    required String title,
    required String body,
    required NotificationCategory category,
    required String section,
    String? entityId,
  }) async {
    notifications.insert(
      0,
      AppNotificationRecord(
        id: _newId('notification'),
        title: title,
        body: body,
        category: category,
        section: section,
        createdAt: DateTime.now(),
        isRead: false,
        entityId: entityId,
      ),
    );
    await _notificationService.showLocalNotification(title: title, body: body);
  }

  List<InstallmentRecord> _generateInstallments(SalesContractRecord contract) {
    if (contract.installmentCount <= 0 || contract.financedAmount <= 0) {
      return <InstallmentRecord>[];
    }
    final amountPerInstallment = contract.financedAmount / contract.installmentCount;
    return List<InstallmentRecord>.generate(contract.installmentCount, (index) {
      final dueDate = DateTime(
        contract.startDate.year,
        contract.startDate.month + ((index + 1) * contract.installmentFrequencyMonths),
        contract.startDate.day,
      );
      return InstallmentRecord(
        id: _newId('installment'),
        saleContractId: contract.id,
        installmentNumber: index + 1,
        dueDate: dueDate,
        amount: amountPerInstallment,
        paidAmount: 0,
        status: _statusForInstallment(0, amountPerInstallment, dueDate),
        notes: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  bool _requiresInstallmentRebuild(
    SalesContractRecord existing,
    SalesContractRecord updated,
  ) {
    return existing.financedAmount != updated.financedAmount ||
        existing.installmentCount != updated.installmentCount ||
        existing.installmentFrequencyMonths != updated.installmentFrequencyMonths;
  }

  InstallmentStatus _statusForInstallment(
    double paidAmount,
    double amount,
    DateTime dueDate,
  ) {
    if (amount <= 0 || paidAmount >= amount) {
      return InstallmentStatus.paid;
    }
    if (paidAmount > 0) {
      return dueDate.isBefore(DateTime.now())
          ? InstallmentStatus.overdue
          : InstallmentStatus.partiallyPaid;
    }
    return dueDate.isBefore(DateTime.now())
        ? InstallmentStatus.overdue
        : InstallmentStatus.unpaid;
  }

  Future<void> _saveSnapshot() async {
    final encoded = jsonEncode({
      'users': users.map((item) => item.toJsonMap()).toList(),
      'properties': properties.map((item) => item.toJsonMap()).toList(),
      'units': units.map((item) => item.toJsonMap()).toList(),
      'customers': customers.map((item) => item.toJsonMap()).toList(),
      'salesContracts': salesContracts.map((item) => item.toJsonMap()).toList(),
      'installments': installments.map((item) => item.toJsonMap()).toList(),
      'payments': payments.map((item) => item.toJsonMap()).toList(),
      'expenses': expenses.map((item) => item.toJsonMap()).toList(),
      'notifications': notifications.map((item) => item.toJsonMap()).toList(),
      'activityLogs': activityLogs.map((item) => item.toJsonMap()).toList(),
      'lastUpdatedAt': DateTime.now().toIso8601String(),
    });
    await _localCacheService.writeString(StorageKeys.workspaceSnapshot, encoded);
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}

class PropertyOverviewSummary {
  const PropertyOverviewSummary({
    required this.property,
    required this.totalUnits,
    required this.soldUnits,
    required this.availableUnits,
    required this.reservedUnits,
    required this.totalSales,
    required this.totalExpenses,
    required this.remainingReceivables,
    required this.progress,
  });

  final PropertyRecord property;
  final int totalUnits;
  final int soldUnits;
  final int availableUnits;
  final int reservedUnits;
  final double totalSales;
  final double totalExpenses;
  final double remainingReceivables;
  final double progress;
}

class ExpenseGroupSummary {
  const ExpenseGroupSummary(this.key, this.total);

  final String key;
  final double total;
}

class CustomerStatementLine {
  const CustomerStatementLine({
    required this.title,
    required this.amount,
    required this.date,
  });

  final String title;
  final double amount;
  final DateTime date;
}
