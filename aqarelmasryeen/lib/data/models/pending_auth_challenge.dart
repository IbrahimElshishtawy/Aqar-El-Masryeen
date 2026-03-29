import 'dart:convert';

class PendingAuthChallenge {
  const PendingAuthChallenge({
    required this.phone,
    required this.verificationId,
    required this.isRegistration,
    required this.createdAt,
    required this.lastCodeSentAt,
    required this.resendAvailableAt,
    this.resendToken,
    this.fullName,
    this.email,
    this.encryptedPassword,
    this.failedOtpAttempts = 0,
    this.sendCount = 1,
  });

  final String phone;
  final String verificationId;
  final bool isRegistration;
  final int? resendToken;
  final String? fullName;
  final String? email;
  final String? encryptedPassword;
  final int failedOtpAttempts;
  final int sendCount;
  final DateTime createdAt;
  final DateTime lastCodeSentAt;
  final DateTime resendAvailableAt;

  bool get canResend => DateTime.now().isAfter(resendAvailableAt);

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'verificationId': verificationId,
      'isRegistration': isRegistration,
      'resendToken': resendToken,
      'fullName': fullName,
      'email': email,
      'encryptedPassword': encryptedPassword,
      'failedOtpAttempts': failedOtpAttempts,
      'sendCount': sendCount,
      'createdAt': createdAt.toIso8601String(),
      'lastCodeSentAt': lastCodeSentAt.toIso8601String(),
      'resendAvailableAt': resendAvailableAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  PendingAuthChallenge copyWith({
    String? phone,
    String? verificationId,
    bool? isRegistration,
    int? resendToken,
    String? fullName,
    String? email,
    String? encryptedPassword,
    int? failedOtpAttempts,
    int? sendCount,
    DateTime? createdAt,
    DateTime? lastCodeSentAt,
    DateTime? resendAvailableAt,
    bool clearResendToken = false,
  }) {
    return PendingAuthChallenge(
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      isRegistration: isRegistration ?? this.isRegistration,
      resendToken: clearResendToken ? null : resendToken ?? this.resendToken,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      failedOtpAttempts: failedOtpAttempts ?? this.failedOtpAttempts,
      sendCount: sendCount ?? this.sendCount,
      createdAt: createdAt ?? this.createdAt,
      lastCodeSentAt: lastCodeSentAt ?? this.lastCodeSentAt,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
    );
  }

  factory PendingAuthChallenge.fromMap(Map<String, dynamic> map) {
    return PendingAuthChallenge(
      phone: map['phone'] as String? ?? '',
      verificationId: map['verificationId'] as String? ?? '',
      isRegistration: map['isRegistration'] as bool? ?? false,
      resendToken: map['resendToken'] as int?,
      fullName: map['fullName'] as String?,
      email: map['email'] as String?,
      encryptedPassword: map['encryptedPassword'] as String?,
      failedOtpAttempts: map['failedOtpAttempts'] as int? ?? 0,
      sendCount: map['sendCount'] as int? ?? 1,
      createdAt: _parseDate(map['createdAt']),
      lastCodeSentAt: _parseDate(map['lastCodeSentAt']),
      resendAvailableAt: _parseDate(map['resendAvailableAt']),
    );
  }

  factory PendingAuthChallenge.fromJson(String source) {
    return PendingAuthChallenge.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
