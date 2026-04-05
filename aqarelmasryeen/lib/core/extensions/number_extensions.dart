import 'package:intl/intl.dart';

extension CurrencyFormattingX on num {
  String get egp => NumberFormat.currency(
    locale: 'ar_EG',
    symbol: 'ج.م ',
    decimalDigits: 0,
  ).format(this);
}
