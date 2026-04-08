class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const profile = '/auth/profile';
  static const securitySetup = '/auth/security-setup';
  static const unlock = '/auth/unlock';
  static const dashboard = '/dashboard';
  static const properties = '/properties';
  static const expenses = '/expenses';
  static const profileHome = '/profile';
  static const partners = '/partners';
  static const reports = '/reports';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static String expensesTab(String tab) =>
      Uri(path: expenses, queryParameters: {'tab': tab}).toString();

  static String propertyDetails(String propertyId) => '/properties/$propertyId';

  static String propertyExpenses(String propertyId) =>
      '/properties/$propertyId/expenses';

  static String propertyExpenseDetails(String propertyId) =>
      '/properties/$propertyId/expenses/details';

  static String propertyMaterials(String propertyId) =>
      '/properties/$propertyId/materials';

  static String propertyMaterialSupplier(
    String propertyId,
    String supplierName,
  ) {
    return Uri(
      path: '/properties/$propertyId/materials/supplier',
      queryParameters: {'name': supplierName},
    ).toString();
  }

  static String propertyUnitDetails(String propertyId, String unitId) =>
      '/properties/$propertyId/units/$unitId';

  static String editProperty(String propertyId) =>
      '/properties/$propertyId/edit';
}
