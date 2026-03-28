class CachedSession {
  const CachedSession({
    required this.userId,
    required this.phone,
    required this.fullName,
    required this.roleKey,
  });

  final String userId;
  final String phone;
  final String fullName;
  final String roleKey;
}
