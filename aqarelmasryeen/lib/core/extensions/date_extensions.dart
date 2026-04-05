import 'package:intl/intl.dart';

extension DateFormattingX on DateTime {
  String formatShort() => DateFormat('dd MMM yyyy', 'ar_EG').format(this);

  String formatWithTime() =>
      DateFormat('dd MMM yyyy، hh:mm a', 'ar_EG').format(this);
}
