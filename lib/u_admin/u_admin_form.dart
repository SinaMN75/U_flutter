part of "u_admin.dart";

abstract class UAdminForm {
  static Widget pair(BuildContext context, Widget first, Widget second, {double gap = 10}) => context.isMobileWidth
      ? UColumn(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          margin: const EdgeInsets.symmetric(vertical: 6),
          children: <Widget>[first, second],
        )
      : URow(
          crossAxisAlignment: CrossAxisAlignment.start,
          margin: const EdgeInsets.symmetric(vertical: 6),
          children: <Widget>[
            first.expanded(),
            SizedBox(width: gap),
            second.expanded(),
          ],
        );

  static Widget sectionTitle(String title) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Divider(height: 20),
      UTextBodySmall(title, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
    ],
  );

  static Future<void> editDialog({
    required String title,
    required GlobalKey<FormState> formKey,
    required List<Widget> Function(BuildContext context, StateSetter setState) children,
    required Future<bool> Function() onSubmit,
    double maxWidth = 480,
  }) {
    bool saving = false;
    return UNavigator.dialog<void>(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: context.dialogWidth(max: maxWidth),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ...children(context, setState),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      isLoading: saving,
                      onSubmit: () async {
                        if (saving || !(formKey.currentState?.validate() ?? false)) return;
                        setState(() => saving = true);
                        final bool ok = await onSubmit();
                        if (!context.mounted) return;
                        if (ok) return UNavigator.back();
                        setState(() => saving = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget text(TextEditingController controller, String label, {int lines = 1, bool number = false, bool money = false, bool required = false, int? expanded}) => UTextField(
    controller: controller,
    labelText: label,
    lines: lines,
    expanded: expanded,
    keyboardType: number || money ? TextInputType.number : TextInputType.text,
    formatters: money ? <TextInputFormatter>[UCurrencyInputFormatter()] : null,
    validator: required ? UValidators.required(message: "") : null,
    margin: const EdgeInsets.symmetric(vertical: 6),
  );

  static Widget date(TextEditingController controller, String label, ValueChanged<DateTime> onChanged, {DateTime? initial, bool required = false}) => UTextFieldDatePicker(
    controller: controller,
    labelText: label,
    jalali: true,
    initialDate: initial,
    validator: required ? UValidators.required(message: "") : null,
    onChange: (DateTime d, UJalali j) {
      onChanged(d);
      controller.text = d.toJalaliDate();
    },
  ).pSymmetric(vertical: 6);

  static Future<void> filter({
    required String title,
    required List<Widget> Function(StateSetter setState) children,
    required VoidCallback onApply,
    required VoidCallback onClear,
  }) => UNavigator.dialog<void>(
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: UColumn(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ...children(setState),
                const SizedBox(height: 20),
                UButtonSubmitCancel(
                  submitTitle: U.s.filter,
                  cancelTitle: U.s.clearFilters,
                  onSubmit: () {
                    UNavigator.back();
                    onApply();
                  },
                  onCancel: () {
                    UNavigator.back();
                    onClear();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
