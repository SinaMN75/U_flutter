part of "u_process.dart";

/// Renders a process text field (plain text or Persian/Jalali date) and writes
/// user input straight into the matching field of [processStepSend].
class UProcessTextField extends StatefulWidget {
  const UProcessTextField({
    required this.field,
    required this.processStepSend,
    super.key,
  });

  final UProcessField field;
  final UProcessStepSend processStepSend;

  @override
  State<UProcessTextField> createState() => _UProcessTextFieldState();
}

class _UProcessTextFieldState extends State<UProcessTextField> {
  // Owned by the State (not recreated per build) so it is disposed properly.
  final TextEditingController _dateController = TextEditingController();

  void _setValue(String? value) => widget.processStepSend.fields.firstWhere((UProcessField f) => f.key == widget.field.key).value = value;

  String? _requiredValidator(String? v) {
    if (!widget.field.required) return null;
    if ((v ?? "").trim().isEmpty) return S.current.fieldRequired;
    return null;
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UProcessField field = widget.field;

    if (field.textFieldConfig?.type == TagTextFieldType.persianDate) {
      DateTime initial = DateTime.now();
      if (field.value != null && field.value!.trim().isNotEmpty) {
        try {
          initial = DateTime.parse(field.value!);
        } catch (_) {}
      }
      return UTextFieldDatePicker(
        labelText: field.label,
        initialDate: initial,
        validator: _requiredValidator,
        controller: _dateController,
        jalali: true,
        onChange: (DateTime d, Jalali j) {
          _dateController.text = j.formatCompactDate();
          _setValue(d.toIso8601String());
        },
      ).pSymmetric(vertical: 8);
    }

    if (field.type == TagFieldType.text) {
      final int? minLen = field.textFieldConfig?.minLength;
      final int? maxLen = field.textFieldConfig?.maxLength;

      return UTextField(
        labelText: field.label,
        required: field.required,
        initialValue: field.value ?? "",
        maxLength: maxLen,
        validator: (String? v) {
          final String? requiredError = _requiredValidator(v);
          if (requiredError != null) return requiredError;
          final String value = (v ?? "").trim();
          if (minLen != null && value.isNotEmpty && value.length < minLen) return "${S.current.atLeast} $minLen ${S.current.characters}";
          if (maxLen != null && value.isNotEmpty && value.length > maxLen) return "${S.current.atMost} $maxLen ${S.current.characters}";
          return null;
        },
        onChanged: _setValue,
      ).pSymmetric(vertical: 8);
    }

    return const SizedBox.shrink();
  }
}
