class CacheKeys {
  const CacheKeys._();

  static const auth = 'cache.auth';
  static String authProfile(String uid) => '$auth.profile.$uid';
  static String properties({String? workspaceId}) =>
      'cache.properties.${_scope(workspaceId)}.all';
  static String property(String propertyId, {String? workspaceId}) =>
      'cache.properties.${_scope(workspaceId)}.$propertyId';

  static String expenses({String? workspaceId}) =>
      'cache.expenses.${_scope(workspaceId)}.all';
  static String expensesByProperty(String propertyId, {String? workspaceId}) =>
      'cache.expenses.${_scope(workspaceId)}.$propertyId';
  static String unitExpensesByUnit(String unitId, {String? workspaceId}) =>
      'cache.unit_expenses.${_scope(workspaceId)}.unit.$unitId';

  static String materialExpenses({String? workspaceId}) =>
      'cache.material_expenses.${_scope(workspaceId)}.all';
  static String materialExpensesByProperty(
    String propertyId, {
    String? workspaceId,
  }) => 'cache.material_expenses.${_scope(workspaceId)}.$propertyId';
  static String supplierPayments({String? workspaceId}) =>
      'cache.supplier_payments.${_scope(workspaceId)}.all';
  static String supplierPaymentsByProperty(
    String propertyId, {
    String? workspaceId,
  }) => 'cache.supplier_payments.${_scope(workspaceId)}.$propertyId';

  static String partners({String? workspaceId}) =>
      'cache.partners.${_scope(workspaceId)}.all';
  static String partnerLedger({String? workspaceId}) =>
      'cache.partner_ledger.${_scope(workspaceId)}.all';

  static String payments({String? workspaceId}) =>
      'cache.payments.${_scope(workspaceId)}.all';
  static String paymentsByProperty(String propertyId, {String? workspaceId}) =>
      'cache.payments.${_scope(workspaceId)}.property.$propertyId';
  static String paymentsByUnit(String unitId, {String? workspaceId}) =>
      'cache.payments.${_scope(workspaceId)}.unit.$unitId';

  static String units({String? workspaceId}) =>
      'cache.units.${_scope(workspaceId)}.all';
  static String unitsByProperty(String propertyId, {String? workspaceId}) =>
      'cache.units.${_scope(workspaceId)}.$propertyId';

  static String installments({String? workspaceId}) =>
      'cache.installments.${_scope(workspaceId)}.all';
  static String installmentPlansByProperty(
    String propertyId, {
    String? workspaceId,
  }) => 'cache.installment_plans.${_scope(workspaceId)}.$propertyId';
  static String installmentsByProperty(
    String propertyId, {
    String? workspaceId,
  }) => 'cache.installments.${_scope(workspaceId)}.property.$propertyId';
  static String installmentsByUnit(String unitId, {String? workspaceId}) =>
      'cache.installments.${_scope(workspaceId)}.unit.$unitId';

  static String notifications(String userId, {String? workspaceId}) =>
      'cache.notifications.${_scope(workspaceId)}.$userId';
  static String activity({String? propertyId, String? workspaceId}) {
    final scope = _scope(workspaceId);
    return propertyId == null
        ? 'cache.activity.$scope.all'
        : 'cache.activity.$scope.$propertyId';
  }

  static String _scope(String? workspaceId) {
    final normalized = workspaceId?.trim() ?? '';
    return normalized.isEmpty ? 'global' : normalized;
  }
}
