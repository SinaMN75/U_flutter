part of "u_admin.dart";

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
    this.maxContentWidth = 1400,
    this.constrained = true,
  });

  final String title;
  final Widget body;
  final VoidCallback? onFilter;
  final VoidCallback? onCreate;
  final List<Widget>? extraActions;
  final URxInt? pageNumber;
  final URxInt? totalPages;
  final ValueChanged<int>? onPageChanged;
  final Widget? floatingActionButton;

  /// Widest the content is allowed to grow. Past this the page centres itself
  /// instead of stretching a table across a 2560px monitor.
  final double maxContentWidth;

  /// Set false for a page that manages its own width (a map, a full-bleed editor).
  final bool constrained;

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
      children: <Widget>[
        (constrained ? UAdminPageBody(maxWidth: maxContentWidth, child: body) : body).expanded(),
        if (_hasPagination)
          UObx(
            () => UNumberPagination(
              currentPage: pageNumber!.value,
              totalPages: totalPages!.value,
              onPageChanged: onPageChanged!,
            ).pOnly(bottom: 16, top: 8),
          ),
      ],
    ),
  );
}
