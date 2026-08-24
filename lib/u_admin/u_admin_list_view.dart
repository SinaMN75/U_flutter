part of "u_admin.dart";

// One label/value pair rendered inside a [UAdminTable.mobileCard]. Pass [valueWidget] for a
// non-text value (a chip, image, coloured amount); otherwise [value] is shown as text.
class UAdminField {
  const UAdminField(this.label, this.value, {this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;
}

class UAdminListView<T> extends StatelessWidget {
  const UAdminListView({
    required this.state,
    required this.items,
    required this.totalCount,
    required this.desktopHeader,
    required this.desktopRow,
    required this.mobileRow,
    required this.onRetry,
    required this.emptyText,
    super.key,
    this.desktopBreakpoint = 800,
  });

  final RxState state;

  final List<T> Function() items;
  final int Function() totalCount;
  final List<Widget> Function() desktopHeader;
  final Widget Function(T item, int index) desktopRow;
  final Widget Function(T item, int index) mobileRow;
  final VoidCallback onRetry;
  final String emptyText;
  final double desktopBreakpoint;

  @override
  Widget build(BuildContext context) => Obx(() {
    if (state.value.isError()) return _AdminListError(onRetry: onRetry);
    if (state.value.isEmpty()) return _AdminListEmpty(text: emptyText);
    if (!state.value.isLoaded()) return const Center(child: CircularProgressIndicator());

    final List<T> data = items();
    final bool desktop = MediaQuery.sizeOf(context).width >= desktopBreakpoint;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget list = desktop
        ? UListView(
            padding: const EdgeInsets.only(bottom: 8),
            header: UContainer(
              color: scheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              child: URow(children: desktopHeader()),
            ),
            itemBuilder: (BuildContext context, int index) => desktopRow(data[index], index),
            itemCount: data.length,
          )
        : UListView(itemBuilder: (BuildContext context, int index) => mobileRow(data[index], index), itemCount: data.length);

    return UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: URow(
            spacing: 0,
            children: <Widget>[
              Icon(Icons.format_list_bulleted_rounded, size: 16, color: Theme.of(context).disabledColor),
              const SizedBox(width: 6),
              UTextBodySmall("${U.s.totalResults}: ${totalCount().toString().separateNumbers3By3()}", color: Theme.of(context).disabledColor),
            ],
          ),
        ),
        list.expanded(),
      ],
    );
  });
}

// Builders for the desktop table + mobile card shared by admin list pages, so each page no longer
// hand-rolls header cells, centered body cells, zebra row colors, or the mobile ListTile card.
abstract class UAdminTable {
  // A single primary-colored, centered header cell (use [flex] for wider columns).
  static Widget headerCell(String title, {int flex = 1}) => UTextBodyLarge(title, color: UAdminTheme.white, textAlign: TextAlign.center).expanded(flex: flex);

  // Primary-colored, centered header cells from column titles (all equal width).
  static List<Widget> header(List<String> titles) => titles.map(headerCell).toList();

  // A centered body cell for a desktop row (use [flex] to match a wider header column).
  static Widget cell(String text, {int flex = 1}) => UTextBodyMedium(text, textAlign: TextAlign.center).expanded(flex: flex);

  // Zebra background for a desktop row.
  static Color rowColor(BuildContext context, int index) => index.isOdd ? UAdminTheme.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);

  // Standard padding for a desktop row so table rows breathe consistently across pages.
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 12);

  // A pill-shaped status chip reused by desktop rows and mobile cards for a consistent look.
  static Widget statusChip(BuildContext context, {required String label, required Color color}) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    radius: 20,
    color: color.withValues(alpha: 0.14),
    child: UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
  );

  // A tinted rounded square holding a leading [icon], the default leading for [mobileCard].
  static Widget leadingIcon(BuildContext context, IconData icon, {Color? color}) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return UContainer(
      width: 44,
      height: 44,
      radius: 12,
      color: c.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(icon, color: c, size: 22),
    );
  }

  // The beautiful, reusable mobile card used by every list page. Shows a leading icon/thumbnail,
  // a title (+ optional subtitle), an optional status [badge] and [trailing] menu, then every
  // desktop column as a clean label -> value row so mobile stays complete and scannable.
  static Widget mobileCard(
    BuildContext context, {
    required String title,
    required List<UAdminField> fields,
    Widget? leading,
    IconData? icon,
    String? subtitle,
    Widget? badge,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget card = UContainer(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      padding: const EdgeInsets.all(14),
      radius: 16,
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      boxShadow: <BoxShadow>[BoxShadow(color: scheme.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      child: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              leading ?? leadingIcon(context, icon ?? Icons.circle_outlined),
              Expanded(
                child: UColumn(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    UTextTitleSmall(title, maxLines: 2, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w700),
                    if (subtitle.isNotNullOrEmpty()) UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              ?badge,
              ?trailing,
            ],
          ),
          if (fields.isNotEmpty) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            ...fields.mapIndexed(
              (int idx, UAdminField f) => Padding(
                padding: EdgeInsets.only(top: idx == 0 ? 0 : 10),
                child: _fieldRow(context, f),
              ),
            ),
          ],
        ],
      ),
    );
    return onTap == null ? card : card.onTapInk(onTap);
  }

  static Widget _fieldRow(BuildContext context, UAdminField f) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        UTextBodySmall(f.label, color: scheme.onSurfaceVariant),
        Flexible(
          child: f.valueWidget ?? UTextBodyMedium(f.value ?? "-", textAlign: TextAlign.end, maxLines: 3, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // The mobile card row (UContainer + dense ListTile) used by every list page.
  static Widget mobileTile(BuildContext context, {required int index, required IconData icon, required String title, required List<Widget> subtitle, Widget? trailing, VoidCallback? onTap}) =>
      UContainer(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: index.isOdd ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        radius: 8,
        child: ListTile(
          dense: true,
          onTap: onTap,
          leading: Icon(icon),
          title: UTextBodyMedium(title),
          subtitle: UColumn(spacing: 0, crossAxisAlignment: CrossAxisAlignment.start, children: subtitle),
          trailing: trailing,
        ),
      );
}

class UAdminSortHeader extends StatelessWidget {
  const UAdminSortHeader({required this.title, required this.onTap, this.direction, super.key});

  final String title;
  final VoidCallback onTap;
  final bool? direction;

  @override
  Widget build(BuildContext context) => URow(
    onTap: onTap,
    spacing: 0,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Flexible(
        child: UTextBodyLarge(title, color: Theme.of(context).colorScheme.onPrimary, textAlign: .center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      if (direction != null) Icon(direction! ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Theme.of(context).colorScheme.onPrimary),
    ],
  ).expanded();
}

class _AdminListError extends StatelessWidget {
  const _AdminListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: UColumn(
      spacing: 0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 12),
        UTextBodyMedium(U.s.errorReadingData),
        const SizedBox(height: 12),
        UButton(title: U.s.tryAgain, icon: const Icon(Icons.refresh), onTap: onRetry, width: 180),
      ],
    ),
  );
}

class _AdminListEmpty extends StatelessWidget {
  const _AdminListEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: UColumn(
      spacing: 0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.inbox_rounded, size: 56, color: Theme.of(context).disabledColor),
        const SizedBox(height: 12),
        UTextBodyMedium(text, color: Theme.of(context).disabledColor),
      ],
    ),
  );
}
