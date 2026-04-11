class AppConfig {
  const AppConfig._();

  static const appName = 'عقار المصريين';
  static const defaultWorkspaceId = '';
  static const defaultInactivityTimeoutSeconds = 90;
  static const minPasswordLength = 10;
  static const notificationChannelId = 'activity_alerts';
  static const notificationChannelName = 'تنبيهات النشاط';
  static const notificationChannelDescription =
      'إشعارات الأنشطة والتحديثات المهمة داخل مساحة العمل.';
  static const reminderLeadDays = <int>[7, 3, 1];
}
