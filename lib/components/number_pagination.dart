import "package:flutter/material.dart";

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

        // First page
        if (currentPage > threshold + 1 && totalPages > threshold * 2) _buildPageNumber(1, selectedColor, unselectedColor),

        // Left dots
        if (currentPage > threshold + 2 && totalPages > threshold * 2)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("..."),
          ),

        // Middle numbers
        for (int i = 1; i <= totalPages; i++)
          if ((i >= currentPage - threshold && i <= currentPage + threshold) || i == 1 || i == totalPages) _buildPageNumber(i, selectedColor, unselectedColor),

        // Right dots
        if (currentPage < totalPages - threshold - 1 && totalPages > threshold * 2)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text("..."),
          ),

        // Last page
        if (currentPage < totalPages - threshold && totalPages > threshold * 2) _buildPageNumber(totalPages, selectedColor, unselectedColor),

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
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: currentPage == page ? selectedColor : null,
        borderRadius: BorderRadius.circular(4),
      ),
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
