import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GroupedNumberInputFormatter extends TextInputFormatter {
  GroupedNumberInputFormatter({
    this.allowDecimal = true,
    this.locale = 'en_US',
  });

  final bool allowDecimal;
  final String locale;

  static String normalize(String value) =>
      value.replaceAll(',', '').replaceAll(' ', '').trim();

  static double? tryParse(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  static String formatNumber(
    num value, {
    int decimalDigits = 0,
    String locale = 'en_US',
  }) {
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimalDigits,
    ).format(value);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    final selectionIndex = newValue.selection.extentOffset;
    final sanitized = _sanitize(rawText);

    if (sanitized.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _formatSanitized(sanitized);
    final rawCursor = _relevantCharactersBeforeCursor(rawText, selectionIndex);
    final nextCursor = _cursorOffsetForFormattedText(formatted, rawCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: nextCursor),
      composing: TextRange.empty,
    );
  }

  String _sanitize(String value) {
    final withoutGrouping = normalize(value);
    final buffer = StringBuffer();
    var sawDecimal = false;

    for (final rune in withoutGrouping.runes) {
      final character = String.fromCharCode(rune);
      if (_isDigit(character)) {
        buffer.write(character);
        continue;
      }
      if (allowDecimal && character == '.' && !sawDecimal) {
        sawDecimal = true;
        buffer.write(character);
      }
    }

    return buffer.toString();
  }

  String _formatSanitized(String value) {
    final parts = value.split('.');
    final integerPart = parts.first;
    final hasTrailingDecimal = value.endsWith('.') && allowDecimal;
    final decimalPart = parts.length > 1 ? parts.sublist(1).join() : '';
    final normalizedInteger = integerPart.isEmpty ? '0' : integerPart;
    final formattedInteger = NumberFormat.decimalPattern(
      locale,
    ).format(int.parse(normalizedInteger));

    if (!allowDecimal) {
      return formattedInteger;
    }
    if (hasTrailingDecimal) {
      return '$formattedInteger.';
    }
    if (decimalPart.isEmpty) {
      return formattedInteger;
    }
    return '$formattedInteger.$decimalPart';
  }

  int _relevantCharactersBeforeCursor(String text, int cursorOffset) {
    final safeOffset = cursorOffset.clamp(0, text.length);
    var count = 0;
    var sawDecimal = false;

    for (var index = 0; index < safeOffset; index++) {
      final character = text[index];
      if (_isDigit(character)) {
        count++;
        continue;
      }
      if (allowDecimal && character == '.' && !sawDecimal) {
        sawDecimal = true;
        count++;
      }
    }

    return count;
  }

  int _cursorOffsetForFormattedText(String text, int rawCursor) {
    if (rawCursor <= 0) {
      return 0;
    }

    var seen = 0;
    var sawDecimal = false;
    for (var index = 0; index < text.length; index++) {
      final character = text[index];
      if (_isDigit(character)) {
        seen++;
      } else if (allowDecimal && character == '.' && !sawDecimal) {
        sawDecimal = true;
        seen++;
      }

      if (seen >= rawCursor) {
        return index + 1;
      }
    }

    return text.length;
  }

  bool _isDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
}

double parseGroupedDouble(String value) {
  return GroupedNumberInputFormatter.tryParse(value) ?? 0;
}
