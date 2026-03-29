import 'dart:convert';

class StoredAuthCredentials {
  const StoredAuthCredentials({
    required this.phone,
    required this.encryptedPassword,
    required this.createdAt,
    required this.updatedAt,
  });

  final String phone;
  final String encryptedPassword;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'encryptedPassword': encryptedPassword,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  factory StoredAuthCredentials.fromMap(Map<String, dynamic> map) {
    return StoredAuthCredentials(
      phone: map['phone'] as String? ?? '',
      encryptedPassword: map['encryptedPassword'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  factory StoredAuthCredentials.fromJson(String source) {
    return StoredAuthCredentials.fromMap(
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
