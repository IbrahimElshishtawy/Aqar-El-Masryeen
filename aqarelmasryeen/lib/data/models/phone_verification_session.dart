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
}
