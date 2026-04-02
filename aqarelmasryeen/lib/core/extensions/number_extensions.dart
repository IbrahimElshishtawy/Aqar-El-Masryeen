import 'package:intl/intl.dart';

extension CurrencyFormattingX on num {
  String get egp => NumberFormat.currency(
        locale: 'en_EG',
        symbol: 'EGP ',
        decimalDigits: 0,
      ).format(this);
}
