import "package:u/utilities.dart";

class UNumberInputFormatter extends TextInputFormatter {
  final int maxDigits;

  UNumberInputFormatter({
    this.maxDigits = 24,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String latin = newValue.text.toLatinNumber();

    final StringBuffer result = StringBuffer();

    int digitCount = 0;
    int cursorPosition = 0;

    final int requestedCursor = newValue.selection.baseOffset;

    for (int i = 0; i < latin.length; i++) {
      final String character = latin[i];

      if (character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57) {
        if (digitCount >= maxDigits) {
          break;
        }

        result.write(character);
        digitCount++;

        if (i < requestedCursor) {
          cursorPosition++;
        }
      }
    }

    final String formatted = result.toString();

    cursorPosition = cursorPosition.clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorPosition,
      ),
    );
  }
}

class UPhoneInputFormatter extends TextInputFormatter {
  final String countryCode;

  UPhoneInputFormatter({
    required this.countryCode,
  });

  static bool _isDigit(String character) => character.codeUnitAt(0) >= 48 && character.codeUnitAt(0) <= 57;

  static String _digitsOf(String value) {
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (_isDigit(value[i])) out.write(value[i]);
    }
    return out.toString();
  }

  static int _digitsBefore(String value, int offset) {
    int count = 0;
    for (int i = 0; i < value.length && i < offset; i++) {
      if (_isDigit(value[i])) count++;
    }
    return count;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String latin = newValue.text.toLatinNumber();

    if (latin.startsWith("+") || latin.startsWith("00")) {
      final String international = latin.replaceAll(RegExp(r"[^\d+]"), "");
      return TextEditingValue(
        text: international,
        selection: TextSelection.collapsed(offset: international.length),
      );
    }

    int typed = _digitsBefore(latin, newValue.selection.baseOffset);
    String digits = _digitsOf(latin);

    final bool deleted = newValue.text.length < oldValue.text.length;
    if (deleted && digits == _digitsOf(oldValue.text.toLatinNumber()) && typed > 0) {
      digits = digits.substring(0, typed - 1) + digits.substring(typed);
      typed--;
    }

    final String limited = UPhoneNumberUtils.inputDigits(digits, countryCode: countryCode);
    final String formatted = UPhoneNumberUtils.formatNational(limited, countryCode: countryCode);

    final int target = typed - (digits.length - limited.length);
    int offset = 0;
    int seen = 0;
    while (offset < formatted.length && seen < target) {
      if (_isDigit(formatted[offset])) seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset.clamp(0, formatted.length)),
    );
  }
}

class UCurrencyInputFormatter extends TextInputFormatter {
  static final RegExp _nonNumeric = RegExp(r"[^\d.]");

  final String thousandSeparator;
  final String decimalSeparator;
  final int maxDigits;

  UCurrencyInputFormatter({
    this.thousandSeparator = ",",
    this.decimalSeparator = ".",
    this.maxDigits = 24,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (newValue.text.length < oldValue.text.length) {
      return _handleDeletion(oldValue, newValue);
    }

    return _handleInsertion(oldValue, newValue);
  }

  TextEditingValue _handleDeletion(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String cleanedOld = oldValue.text.toLatinNumber().replaceAll(thousandSeparator, "").replaceAll(decimalSeparator, ".");
    final String cleanedNew = newValue.text.toLatinNumber().replaceAll(thousandSeparator, "").replaceAll(decimalSeparator, ".");

    if (cleanedNew.length == cleanedOld.length) {
      final int oldCursorPos = oldValue.selection.baseOffset;
      if (oldCursorPos > 0 && oldCursorPos <= oldValue.text.length) {
        final String deletedChar = oldValue.text[oldCursorPos - 1];
        if (deletedChar == thousandSeparator || deletedChar == decimalSeparator) {
          final StringBuffer newText = StringBuffer();
          for (int i = 0; i < oldValue.text.length; i++) {
            if (i != oldCursorPos - 2 && i != oldCursorPos - 1) {
              newText.write(oldValue.text[i]);
            }
          }

          final String formatted = _formatText(newText.toString());
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(
              offset: _calculateCursorPosition(formatted, oldCursorPos - 2),
            ),
          );
        }
      }
    }

    final String formatted = _formatText(newValue.text);
    final int newCursorPos = _calculateCursorPosition(formatted, newValue.selection.baseOffset);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  TextEditingValue _handleInsertion(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String cleanedText = newValue.text.toLatinNumber().replaceAll(_nonNumeric, "");

    final List<String> parts = cleanedText.split(".");
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : "";

    if (integerPart.length > maxDigits) {
      integerPart = integerPart.substring(0, maxDigits);
    }

    final String formattedInteger = _formatInteger(integerPart);

    String finalText = formattedInteger;
    if (decimalPart.isNotEmpty) {
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      finalText = "$formattedInteger$decimalSeparator$decimalPart";
    }

    final int newCursorPos = _calculateCursorPosition(finalText, newValue.selection.baseOffset);

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  String _formatText(String text) {
    if (text.isEmpty) return "";

    final String cleanedText = text.toLatinNumber().replaceAll(_nonNumeric, "");

    final List<String> parts = cleanedText.split(".");

    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : "";

    if (integerPart.length > maxDigits) {
      integerPart = integerPart.substring(0, maxDigits);
    }

    final String formattedInteger = _formatInteger(integerPart);

    String finalText = formattedInteger;
    if (decimalPart.isNotEmpty) {
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      finalText = "$formattedInteger$decimalSeparator$decimalPart";
    }

    return finalText;
  }

  String _formatInteger(String integerPart) {
    if (integerPart.isEmpty) return "";

    final StringBuffer result = StringBuffer();

    int count = 0;

    for (int i = integerPart.length - 1; i >= 0; i--) {
      result.write(integerPart[i]);

      count++;

      if (count == 3 && i > 0) {
        result.write(thousandSeparator);
        count = 0;
      }
    }

    return result.toString().split("").reversed.join();
  }

  int _calculateCursorPosition(String formattedText, int oldCursorPos) {
    if (formattedText.isEmpty || oldCursorPos <= 0) return 0;

    int separatorsBeforeCursor = 0;
    for (int i = 0; i < formattedText.length && i < oldCursorPos; i++) {
      if (formattedText[i] == thousandSeparator || formattedText[i] == decimalSeparator) {
        separatorsBeforeCursor++;
      }
    }

    int newCursorPos = oldCursorPos + separatorsBeforeCursor;

    newCursorPos = newCursorPos.clamp(0, formattedText.length);

    if (newCursorPos < formattedText.length && (formattedText[newCursorPos] == thousandSeparator || formattedText[newCursorPos] == decimalSeparator)) {
      newCursorPos++;
    }

    return newCursorPos.clamp(0, formattedText.length);
  }
}
