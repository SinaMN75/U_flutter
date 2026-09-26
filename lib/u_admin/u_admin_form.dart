part of "u_admin.dart";

/// Layout primitives shared by every admin form, so a field pair is responsive
/// by construction instead of each page re-deciding with its own `isMobileWidth`
/// branch — the thing that made two otherwise identical user forms diverge.
abstract class UAdminForm {
  /// Two fields side by side on a wide screen, stacked on a phone.
  ///
  /// The branch exists because two text fields sharing a 360px row leave each
  /// one too narrow to read what it holds.
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

  /// Any number of fields laid out in as many columns as the width allows.
  static Widget fields(List<Widget> children, {double minFieldWidth = 240}) => UAdminResponsiveGrid(minTileWidth: minFieldWidth, spacing: 10, runSpacing: 4, children: children);

  /// A divider plus a small muted caption, used to break a long form into groups.
  static Widget sectionTitle(String title) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const Divider(height: 20),
      UTextBodySmall(title, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
    ],
  );

  /// The one create/edit dialog of every admin page: a titled, width-capped, scrolling [Form] ending with submit/cancel.
  /// [onSubmit] runs once the form validates and returns true to close the dialog; the submit button spins meanwhile.
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

  /// A text field with the admin forms' spacing.
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

  /// A Jalali date field bound to [controller]; [onChanged] gets the picked date.
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

  /// The shell every admin filter dialog was hand-rolling: a titled dialog whose
  /// content scrolls, is capped to a sensible dialog width, and optionally sits
  /// in a [Form].
  ///
  /// Pages differed only in whether they remembered the [Form] and how wide they
  /// made the box, which is why no two filter dialogs behaved quite the same on a
  /// narrow screen. Pass the fields; the shell is fixed.
  static Widget filterDialog(
    BuildContext context, {
    required Widget title,
    required List<Widget> children,
    GlobalKey<FormState>? formKey,
    double maxWidth = 420,
  }) {
    final Widget body = SingleChildScrollView(
      child: UColumn(mainAxisSize: MainAxisSize.min, children: children),
    );
    return AlertDialog(
      title: title,
      content: SizedBox(
        width: context.dialogWidth(max: maxWidth),
        child: formKey == null ? body : Form(key: formKey, child: body),
      ),
    );
  }

  /// Shows a filter dialog: [children] (rebuilt through its setState) then "filter" / "clear filters", each closing the dialog.
  static Future<void> filter({
    required String title,
    required List<Widget> Function(StateSetter setState) children,
    required VoidCallback onApply,
    required VoidCallback onClear,
  }) => UNavigator.dialog<void>(
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => filterDialog(
        context,
        title: Text(title),
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
  );
}
