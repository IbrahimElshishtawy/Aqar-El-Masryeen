import 'package:intl/intl.dart';

extension DateFormattingX on DateTime {
  String formatShort() => DateFormat('dd MMM yyyy').format(this);

  String formatWithTime() => DateFormat('dd MMM yyyy, hh:mm a').format(this);
}
