class PhoneVerificationSession {
  const PhoneVerificationSession({
    required this.phone,
    required this.verificationId,
    required this.isRegistration,
    this.resendToken,
  });

  final String phone;
  final String verificationId;
  final bool isRegistration;
  final int? resendToken;

  PhoneVerificationSession copyWith({
    String? phone,
    String? verificationId,
    bool? isRegistration,
    int? resendToken,
    bool clearResendToken = false,
  }) {
    return PhoneVerificationSession(
      phone: phone ?? this.phone,
      verificationId: verificationId ?? this.verificationId,
      isRegistration: isRegistration ?? this.isRegistration,
      resendToken: clearResendToken ? null : resendToken ?? this.resendToken,
    );
  }
}
