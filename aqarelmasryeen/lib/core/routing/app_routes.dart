class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const otp = '/auth/otp';
  static const profile = '/auth/profile';
  static const securitySetup = '/auth/security-setup';
  static const unlock = '/auth/unlock';
  static const dashboard = '/dashboard';
  static const properties = '/properties';
  static const partners = '/partners';
  static const reports = '/reports';
  static const settings = '/settings';
  static const notifications = '/notifications';

  static String propertyDetails(String propertyId) => '/properties/$propertyId';

  static String editProperty(String propertyId) =>
      '/properties/$propertyId/edit';
}
