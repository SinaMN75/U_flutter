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
  });

  final String title;
  final Widget body;
  final VoidCallback? onFilter;
  final VoidCallback? onCreate;
  final List<Widget>? extraActions;
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
        if (_hasPagination)
          Obx(
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
