part of "u_admin.dart";

// Standard admin list-page scaffold: an app bar (title + optional filter / create actions) over a
// body, with controller-bound bottom pagination rendered automatically when [pageNumber],
// [totalPages] and [onPageChanged] are supplied. Replaces the hand-rolled
// UScaffold + AppBar + Column([body, Obx(UNumberPagination)]) boilerplate repeated across pages.
class UAdminScaffold extends StatelessWidget {
  const UAdminScaffold({
    required this.title,
    required this.body,
    super.key,
    this.onFilter,
    this.onCreate,
    this.extraActions,
    this.pageNumber,
    this.totalPages,
    this.onPageChanged,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;

  // When non-null a filter icon is shown in the app bar.
  final VoidCallback? onFilter;

  // When non-null a create icon is shown; callers gate this with their own permission check.
  final VoidCallback? onCreate;

  // Extra app-bar actions appended after filter/create.
  final List<Widget>? extraActions;

  // Supply all three to get a controller-bound pagination bar at the bottom.
  final RxInt? pageNumber;
  final RxInt? totalPages;
  final ValueChanged<int>? onPageChanged;

  final Widget? floatingActionButton;

  bool get _hasPagination => pageNumber != null && totalPages != null && onPageChanged != null;

  @override
  Widget build(BuildContext context) => UScaffold(
    floatingActionButton: floatingActionButton,
    appBar: AppBar(
      title: Text(title),
      actions: <Widget>[
        if (onFilter != null) IconButton(icon: const Icon(Icons.filter_alt), tooltip: U.s.filter, onPressed: onFilter),
        if (onCreate != null) IconButton(icon: const Icon(Icons.add), tooltip: U.s.create, onPressed: onCreate),
        ...?extraActions,
      ],
    ),
    body: UColumn(
      spacing: 0,
      children: <Widget>[
        body.expanded(),
        if (_hasPagination) Obx(() => UNumberPagination(currentPage: pageNumber!.value, totalPages: totalPages!.value, onPageChanged: onPageChanged!).pOnly(bottom: 16, top: 8)),
      ],
    ),
  );
}
