class CacheKeys {
  const CacheKeys._();

  static const auth = 'cache.auth';
  static String authProfile(String uid) => '$auth.profile.$uid';
  static const properties = 'cache.properties.all';
  static String property(String propertyId) => 'cache.properties.$propertyId';

  static const expenses = 'cache.expenses.all';
  static String expensesByProperty(String propertyId) =>
      'cache.expenses.$propertyId';
  static String unitExpensesByUnit(String unitId, {String? workspaceId}) =>
      'cache.unit_expenses.${workspaceId ?? 'global'}.unit.$unitId';

  static const materialExpenses = 'cache.material_expenses.all';
  static String materialExpensesByProperty(String propertyId) =>
      'cache.material_expenses.$propertyId';
  static const supplierPayments = 'cache.supplier_payments.all';
  static String supplierPaymentsByProperty(String propertyId) =>
      'cache.supplier_payments.$propertyId';

  static const partners = 'cache.partners.all';
  static const partnerLedger = 'cache.partner_ledger.all';

  static const payments = 'cache.payments.all';
  static String paymentsByProperty(String propertyId) =>
      'cache.payments.property.$propertyId';
  static String paymentsByUnit(String unitId) => 'cache.payments.unit.$unitId';

  static const units = 'cache.units.all';
  static String unitsByProperty(String propertyId) => 'cache.units.$propertyId';

  static const installments = 'cache.installments.all';
  static String installmentPlansByProperty(String propertyId) =>
      'cache.installment_plans.$propertyId';
  static String installmentsByProperty(String propertyId) =>
      'cache.installments.property.$propertyId';
  static String installmentsByUnit(String unitId) =>
      'cache.installments.unit.$unitId';

  static String notifications(String userId, {String? workspaceId}) =>
      'cache.notifications.${workspaceId ?? 'global'}.$userId';
  static String activity({String? propertyId, String? workspaceId}) {
    final scope = workspaceId ?? 'global';
    return propertyId == null
        ? 'cache.activity.$scope.all'
        : 'cache.activity.$scope.$propertyId';
  }
}
