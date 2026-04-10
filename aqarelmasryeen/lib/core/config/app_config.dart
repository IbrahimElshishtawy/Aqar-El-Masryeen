class AppConfig {
  const AppConfig._();

  static const appName = 'عقار المصريين';
  static const defaultWorkspaceId = '';
  static const defaultInactivityTimeoutSeconds = 90;
  static const minPasswordLength = 10;
  static const notificationChannelId = 'finance_alerts';
  static const notificationChannelName = 'تنبيهات مالية';
  static const notificationChannelDescription =
      'تنبيهات الأقساط والتحصيلات والمصروفات والأمان.';
  static const reminderLeadDays = <int>[7, 3, 1];
}
