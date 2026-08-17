part of "u_process.dart";

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
  final TextEditingController _dateController = TextEditingController();

  void _setValue(String? value) => widget.processStepSend.fields.firstWhere((UProcessField f) => f.key == widget.field.key).value = value;

  String? _requiredValidator(String? v) {
    if (!widget.field.required) return null;
    if ((v ?? "").trim().isEmpty) return U.s.thisFieldIsRequired;
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
          if (minLen != null && value.isNotEmpty && value.length < minLen) return "${U.s.atLeast} $minLen ${U.s.characters}";
          if (maxLen != null && value.isNotEmpty && value.length > maxLen) return "${U.s.atMost} $maxLen ${U.s.characters}";
          return null;
        },
        onChanged: _setValue,
      ).pSymmetric(vertical: 8);
    }

    return const SizedBox.shrink();
  }
}
