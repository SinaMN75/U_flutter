part of "u_admin.dart";

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

  final Rx<PageState> state;

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
    final Widget list = desktop
        ? UListView(
            header: URow(color: Theme.of(context).colorScheme.primary, padding: const EdgeInsets.all(8), children: desktopHeader()),
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
  static Color rowColor(BuildContext context, int index) => index.isOdd ? UAdminTheme.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.16);

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
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: URow(
      spacing: 0,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: UTextBodyLarge(title, color: Theme.of(context).colorScheme.onPrimary, textAlign: .center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (direction != null) Icon(direction! ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Theme.of(context).colorScheme.onPrimary),
      ],
    ),
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
