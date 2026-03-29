abstract final class StorageKeys {
  static const onboardingSeen = 'onboarding_seen';
  static const localeCode = 'locale_code';
  static const workspaceSnapshot = 'workspace_snapshot';
  static const notificationToken = 'notification_token';
  static const cachedUserId = 'cached_user_id';
  static const cachedPhone = 'cached_phone';
  static const cachedName = 'cached_name';
  static const cachedRole = 'cached_role';
  static const biometricEnabled = 'biometric_enabled';
  static const appLockEnabled = 'app_lock_enabled';
  static const sessionLocked = 'session_locked';
  static const pendingVerificationPhone = 'pending_verification_phone';
  static const pendingVerificationId = 'pending_verification_id';
  static const pendingVerificationIsRegistration =
      'pending_verification_is_registration';
  static const pendingVerificationResendToken =
      'pending_verification_resend_token';
  static const pendingAuthFlow = 'pending_auth_flow';
  static const savedAuthCredentials = 'saved_auth_credentials';
  static const otpSendAttemptPrefix = 'otp_send_attempt_';
  static const otpVerifyAttemptPrefix = 'otp_verify_attempt_';
  static const passwordLoginAttemptPrefix = 'password_login_attempt_';
}
