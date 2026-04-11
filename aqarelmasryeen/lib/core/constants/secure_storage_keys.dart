class SecureStorageKeys {
  const SecureStorageKeys._();

  static const trustedDeviceId = 'security.trusted_device_id';
  static const lastKnownUid = 'auth.last_known_uid';
  static const hasOpenedApp = 'app.has_opened';
  static const appLockEnabled = 'security.app_lock_enabled';
  static const biometricEnabled = 'security.biometric_enabled';
  static const trustedDeviceEnabled = 'security.trusted_device_enabled';
  static const inactivityTimeoutSeconds = 'security.inactivity_timeout_seconds';
  static const lastActivityAt = 'security.last_activity_at';
  static const lastBackgroundAt = 'security.last_background_at';
  static const isLocked = 'security.is_locked';
  static const notificationsEnabled = 'notifications.enabled';
}
