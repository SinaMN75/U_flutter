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
}
