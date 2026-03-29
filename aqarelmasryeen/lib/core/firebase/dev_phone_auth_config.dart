import 'package:aqarelmasryeen/core/utils/phone_utils.dart';
import 'package:flutter/foundation.dart';

abstract final class DevPhoneAuthConfig {
  static const bool _enabledFromDefine = bool.fromEnvironment(
    'ENABLE_DEV_PHONE_AUTH',
    defaultValue: true,
  );
  static const String _defaultPhoneNumber = '+201000000001';
  static const String _defaultSmsCode = '123456';
  static const String _phoneNumberFromDefine = String.fromEnvironment(
    'DEV_PHONE_AUTH_NUMBER',
    defaultValue: _defaultPhoneNumber,
  );
  static const String _smsCodeFromDefine = String.fromEnvironment(
    'DEV_PHONE_AUTH_CODE',
    defaultValue: _defaultSmsCode,
  );

  static bool get isEnabled => kDebugMode && _enabledFromDefine;

  // Mirror this pair in Firebase Console > Authentication > Phone.
  static String get phoneNumber => PhoneUtils.normalize(_phoneNumberFromDefine);
  static String get smsCode => _smsCodeFromDefine;

  static bool get canAutoSubmitOtp => isEnabled && smsCode.length == 6;

  static bool matchesPhone(String phone) =>
      isEnabled && PhoneUtils.normalize(phone) == phoneNumber;
}
