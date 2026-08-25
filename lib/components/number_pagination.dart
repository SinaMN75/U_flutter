import "package:u/utilities.dart";

class UNumberPagination extends StatelessWidget {
  const UNumberPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
    this.threshold = 3,
    this.selectedColor,
    this.unselectedColor,
    this.showPrevNext = true,
    this.prevIcon,
    this.nextIcon,
  });

  final int currentPage;
  final int totalPages;
  final int threshold;
  final ValueChanged<int> onPageChanged;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool showPrevNext;
  final Icon? prevIcon;
  final Icon? nextIcon;

  // Computes the ordered pages to display; a null entry represents an ellipsis gap. Always includes
  // page 1, the last page, and a window of +/- threshold around the current page. Iterates only the
  // visible window (not every page), so it stays cheap even with thousands of pages, and never emits
  // a page twice (the previous implementation double-rendered the first/last page).
  List<int?> _visiblePages() {
    if (totalPages <= 0) return <int?>[];
    final Set<int> pages = <int>{1, totalPages};
    for (int i = currentPage - threshold; i <= currentPage + threshold; i++) {
      if (i >= 1 && i <= totalPages) pages.add(i);
    }
    final List<int> sorted = pages.toList()..sort();
    final List<int?> result = <int?>[];
    int? previous;
    for (final int page in sorted) {
      if (previous != null && page - previous > 1) result.add(null);
      result.add(page);
      previous = page;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color selectedColor = this.selectedColor ?? theme.primaryColor;
    final Color unselectedColor = this.unselectedColor ?? theme.disabledColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (showPrevNext)
          IconButton(
            icon: prevIcon ?? const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
        for (final int? page in _visiblePages())
          if (page == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("..."),
            )
          else
            _buildPageNumber(page, selectedColor, unselectedColor),
        if (showPrevNext)
          IconButton(
            icon: nextIcon ?? const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
      ],
    );
  }

  Widget _buildPageNumber(int page, Color selectedColor, Color unselectedColor) => InkWell(
    onTap: () => onPageChanged(page),
    child: UContainer(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: currentPage == page ? selectedColor : null,
      radius: 4,
      child: Text(
        "$page",
        style: TextStyle(
          color: currentPage == page ? Colors.white : unselectedColor,
          fontWeight: currentPage == page ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}
