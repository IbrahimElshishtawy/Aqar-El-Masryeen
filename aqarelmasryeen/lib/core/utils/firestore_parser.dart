import 'package:cloud_firestore/cloud_firestore.dart';

DateTime parseDate(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}

double parseDouble(dynamic value, {double fallback = 0}) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  return double.tryParse('$value') ?? fallback;
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  return int.tryParse('$value') ?? fallback;
}
