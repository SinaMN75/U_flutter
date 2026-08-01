import "package:u/utilities.dart";

class UCurrencyInputFormatter extends TextInputFormatter {
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
    final String cleanedText = newValue.text.toLatinNumber().replaceAll(RegExp(r"[^\d.]"), "");

    final List<String> parts = cleanedText.split(".");
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : "";

    if (integerPart.length > maxDigits) {
      integerPart = integerPart.substring(0, maxDigits);
    }

    String formattedInteger = "";
    int count = 0;

    for (int i = integerPart.length - 1; i >= 0; i--) {
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
      if (count == 3 && i > 0) {
        formattedInteger = thousandSeparator + formattedInteger;
        count = 0;
      }
    }

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

    final String cleanedText = text.toLatinNumber().replaceAll(RegExp(r"[^\d.]"), "");

    final List<String> parts = cleanedText.split(".");
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : "";

    if (integerPart.length > maxDigits) {
      integerPart = integerPart.substring(0, maxDigits);
    }

    String formattedInteger = "";
    int count = 0;

    for (int i = integerPart.length - 1; i >= 0; i--) {
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
      if (count == 3 && i > 0) {
        formattedInteger = thousandSeparator + formattedInteger;
        count = 0;
      }
    }

    String finalText = formattedInteger;
    if (decimalPart.isNotEmpty) {
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }
      finalText = "$formattedInteger$decimalSeparator$decimalPart";
    }

    return finalText;
  }

  int _calculateCursorPosition(String formattedText, int oldCursorPos) {
    if (formattedText.isEmpty) return 0;

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

    return newCursorPos;
  }
}
