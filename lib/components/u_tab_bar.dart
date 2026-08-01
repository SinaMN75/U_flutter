import "package:flutter/material.dart";

class UTab {
  final String id;
  final String title;
  final IconData? icon;

  final Widget? badge;

  const UTab({required this.id, required this.title, this.icon, this.badge});
}

enum UTabMenuAction { close, closeOthers, closeAll, closeToRight }

class UTabBarTheme {
  final Color backgroundColor;
  final Gradient? backgroundGradient;

  final Color selectedTabColor;
  final Color hoverTabColor;
  final Color unselectedTabColor;

  final Color selectedTextColor;
  final Color unselectedTextColor;

  final Color indicatorColor;
  final Color controlColor;

  final double height;
  final double tabHeight;
  final double minTabWidth;
  final double maxTabWidth;
  final double gap;
  final BorderRadius tabRadius;

  final Duration animationDuration;
  final Curve animationCurve;
  final bool showSelectedUnderline;

  const UTabBarTheme({
    required this.backgroundColor,
    required this.selectedTabColor,
    required this.hoverTabColor,
    required this.unselectedTabColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.indicatorColor,
    required this.controlColor,
    this.backgroundGradient,
    this.height = 52,
    this.tabHeight = 38,
    this.minTabWidth = 120,
    this.maxTabWidth = 220,
    this.gap = 6,
    this.tabRadius = const BorderRadius.all(Radius.circular(12)),
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = Curves.easeOutCubic,
    this.showSelectedUnderline = true,
  });

  factory UTabBarTheme.from(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = cs.primary;
    final Color on = cs.onPrimary;
    return UTabBarTheme(
      backgroundColor: bg,
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.alphaBlend(Colors.white.withValues(alpha: 0.05), bg),
          bg,
        ],
      ),
      selectedTabColor: Color.alphaBlend(Colors.black.withValues(alpha: 0.22), bg),
      hoverTabColor: on.withValues(alpha: 0.10),
      unselectedTabColor: on.withValues(alpha: 0.04),
      selectedTextColor: on,
      unselectedTextColor: on.withValues(alpha: 0.75),
      indicatorColor: on,
      controlColor: on.withValues(alpha: 0.85),
    );
  }

  UTabBarTheme copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? selectedTabColor,
    Color? hoverTabColor,
    Color? unselectedTabColor,
    Color? selectedTextColor,
    Color? unselectedTextColor,
    Color? indicatorColor,
    Color? controlColor,
    double? height,
    double? tabHeight,
    double? minTabWidth,
    double? maxTabWidth,
    double? gap,
    BorderRadius? tabRadius,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? showSelectedUnderline,
  }) => UTabBarTheme(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    selectedTabColor: selectedTabColor ?? this.selectedTabColor,
    hoverTabColor: hoverTabColor ?? this.hoverTabColor,
    unselectedTabColor: unselectedTabColor ?? this.unselectedTabColor,
    selectedTextColor: selectedTextColor ?? this.selectedTextColor,
    unselectedTextColor: unselectedTextColor ?? this.unselectedTextColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    controlColor: controlColor ?? this.controlColor,
    height: height ?? this.height,
    tabHeight: tabHeight ?? this.tabHeight,
    minTabWidth: minTabWidth ?? this.minTabWidth,
    maxTabWidth: maxTabWidth ?? this.maxTabWidth,
    gap: gap ?? this.gap,
    tabRadius: tabRadius ?? this.tabRadius,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    showSelectedUnderline: showSelectedUnderline ?? this.showSelectedUnderline,
  );
}

class UTabBar extends StatefulWidget {
  const UTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelect,
    required this.onClose,
    super.key,
    this.onReorder,
    this.onMenuAction,
    this.theme,
    this.enableReorder = true,
    this.enableContextMenu = true,
    this.showOverflowMenu = true,
    this.closeLabels = const <UTabMenuAction, String>{},
    this.leading,
    this.trailing,
  });

  final List<UTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;

  final void Function(int oldIndex, int newIndex)? onReorder;

  final void Function(UTabMenuAction action, int index)? onMenuAction;

  final UTabBarTheme? theme;
  final bool enableReorder;
  final bool enableContextMenu;
  final bool showOverflowMenu;

  final Map<UTabMenuAction, String> closeLabels;

  final Widget? leading;

  final Widget? trailing;

  @override
  State<UTabBar> createState() => _UTabBarState();
}

class _UTabBarState extends State<UTabBar> {
  final ScrollController _scroll = ScrollController();
  late UTabBarTheme _t;
  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
      _scrollSelectedIntoView();
    });
  }

  @override
  void didUpdateWidget(covariant UTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrows();
      if (oldWidget.selectedIndex != widget.selectedIndex || oldWidget.tabs.length != widget.tabs.length) {
        _scrollSelectedIntoView();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateArrows);
    _scroll.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_scroll.hasClients) return;
    final bool left = _scroll.offset > 2;
    final bool right = _scroll.offset < _scroll.position.maxScrollExtent - 2;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _scrollSelectedIntoView() {
    if (!_scroll.hasClients) return;
    final int i = widget.selectedIndex;
    if (i < 0 || i >= widget.tabs.length) return;

    final double approx = (widget.theme ?? _t).maxTabWidth.clamp(0, 200).toDouble();
    final double target = (i * (approx * 0.85)) - 80;
    _scroll.animateTo(
      target.clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _nudge(double delta) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      (_scroll.offset + delta).clamp(0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    widget.onReorder?.call(oldIndex, newIndex);
  }

  String _menuLabel(UTabMenuAction a) {
    if (widget.closeLabels.containsKey(a)) return widget.closeLabels[a]!;
    switch (a) {
      case UTabMenuAction.close:
        return "Close";
      case UTabMenuAction.closeOthers:
        return "Close others";
      case UTabMenuAction.closeAll:
        return "Close all";
      case UTabMenuAction.closeToRight:
        return "Close tabs to the right";
    }
  }

  Future<void> _showContextMenu(Offset globalPosition, int index) async {
    final RenderObject? overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final UTabMenuAction? action = await showMenu<UTabMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<UTabMenuAction>>[
        _menuItem(UTabMenuAction.close, Icons.close_rounded),
        _menuItem(UTabMenuAction.closeOthers, Icons.clear_all_rounded),
        _menuItem(UTabMenuAction.closeToRight, Icons.arrow_forward_rounded),
        const PopupMenuDivider(),
        _menuItem(UTabMenuAction.closeAll, Icons.delete_sweep_rounded),
      ],
    );
    if (action == null || !mounted) return;
    if (widget.onMenuAction != null)
      widget.onMenuAction!(action, index);
    else if (action == UTabMenuAction.close)
      widget.onClose(index);
  }

  PopupMenuItem<UTabMenuAction> _menuItem(UTabMenuAction action, IconData icon) => PopupMenuItem<UTabMenuAction>(
    value: action,
    height: 40,
    child: Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(_menuLabel(action)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    _t = widget.theme ?? UTabBarTheme.from(context);

    if (widget.tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: _t.height,
      decoration: BoxDecoration(
        color: _t.backgroundGradient == null ? _t.backgroundColor : null,
        gradient: _t.backgroundGradient,
      ),
      child: Row(
        children: <Widget>[
          if (widget.leading != null) widget.leading!,
          _scrollButton(Icons.chevron_left_rounded, _canLeft, () => _nudge(-240)),
          Expanded(child: _buildList()),
          _scrollButton(Icons.chevron_right_rounded, _canRight, () => _nudge(240)),
          if (widget.showOverflowMenu && widget.tabs.length > 1) _overflowButton(),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }

  Widget _scrollButton(IconData icon, bool enabled, VoidCallback onTap) => AnimatedSize(
    duration: _t.animationDuration,
    curve: _t.animationCurve,
    child: enabled
        ? IconButton(
            iconSize: 22,
            color: _t.controlColor,
            splashRadius: 18,
            icon: Icon(icon),
            onPressed: onTap,
          )
        : const SizedBox(height: 1, width: 0),
  );

  Widget _overflowButton() => PopupMenuButton<int>(
    tooltip: "All tabs",
    icon: Icon(Icons.expand_more_rounded, color: _t.controlColor),
    position: PopupMenuPosition.under,
    onSelected: widget.onSelect,
    itemBuilder: (BuildContext context) => widget.tabs
        .asMap()
        .entries
        .map(
          (MapEntry<int, UTab> e) => PopupMenuItem<int>(
            value: e.key,
            height: 40,
            child: Row(
              children: <Widget>[
                Icon(
                  e.value.icon ?? Icons.tab_rounded,
                  size: 18,
                  color: e.key == widget.selectedIndex ? Theme.of(context).colorScheme.primary : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.value.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: e.key == widget.selectedIndex ? FontWeight.w700 : FontWeight.w400),
                  ),
                ),
                if (e.key == widget.selectedIndex) const Icon(Icons.check_rounded, size: 16),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _buildList() {
    if (!widget.enableReorder) {
      return ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.tabs.length,
        itemBuilder: (BuildContext context, int index) => _wrapChip(index),
      );
    }
    return ReorderableListView.builder(
      scrollController: _scroll,
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: widget.tabs.length,
      onReorderItem: _handleReorder,
      proxyDecorator: (Widget child, int index, Animation<double> animation) => AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? c) {
          final double t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1 + 0.04 * t,
            child: Material(
              color: Colors.transparent,
              elevation: 8 * t,
              shadowColor: Colors.black54,
              borderRadius: _t.tabRadius,
              child: c,
            ),
          );
        },
        child: child,
      ),
      itemBuilder: (BuildContext context, int index) => _wrapChip(index),
    );
  }

  Widget _wrapChip(int index) {
    final UTab tab = widget.tabs[index];
    final Widget chip = Padding(
      key: ValueKey<String>("tab-${tab.id}"),
      padding: EdgeInsets.only(right: _t.gap),
      child: Center(
        child: _TabChip(
          tab: tab,
          theme: _t,
          selected: index == widget.selectedIndex,
          onTap: () => widget.onSelect(index),
          onClose: () => widget.onClose(index),
          onSecondaryTap: widget.enableContextMenu ? (Offset pos) => _showContextMenu(pos, index) : null,
        ),
      ),
    );

    if (widget.enableReorder) {
      return ReorderableDelayedDragStartListener(
        key: ValueKey<String>("drag-${tab.id}"),
        index: index,
        child: chip,
      );
    }
    return chip;
  }
}

class _TabChip extends StatefulWidget {
  const _TabChip({
    required this.tab,
    required this.theme,
    required this.selected,
    required this.onTap,
    required this.onClose,
    this.onSecondaryTap,
  });

  final UTab tab;
  final UTabBarTheme theme;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(Offset globalPosition)? onSecondaryTap;

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  bool _hover = false;
  bool _closeHover = false;

  @override
  Widget build(BuildContext context) {
    final UTabBarTheme t = widget.theme;
    final bool selected = widget.selected;

    final Color bg = selected ? t.selectedTabColor : (_hover ? t.hoverTabColor : t.unselectedTabColor);
    final Color textColor = selected ? t.selectedTextColor : t.unselectedTextColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: widget.onSecondaryTap == null ? null : (TapDownDetails d) => widget.onSecondaryTap!(d.globalPosition),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.92, end: 1),
          duration: t.animationDuration,
          curve: Curves.easeOutBack,
          builder: (BuildContext context, double scale, Widget? child) => Transform.scale(scale: scale, child: child),
          child: AnimatedContainer(
            duration: t.animationDuration,
            curve: t.animationCurve,
            height: t.tabHeight,
            constraints: BoxConstraints(minWidth: t.minTabWidth, maxWidth: t.maxTabWidth),
            padding: const EdgeInsets.only(left: 14, right: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: t.tabRadius,
              border: Border.all(
                color: selected ? t.indicatorColor.withValues(alpha: 0.18) : Colors.transparent,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3)),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.tab.icon != null) ...<Widget>[
                  Icon(widget.tab.icon, size: 16, color: textColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: t.animationDuration,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Text(widget.tab.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                if (widget.tab.badge != null) ...<Widget>[
                  const SizedBox(width: 6),
                  widget.tab.badge!,
                ],
                const Spacer(),
                _closeButton(t, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _closeButton(UTabBarTheme t, Color textColor) => MouseRegion(
    onEnter: (_) => setState(() => _closeHover = true),
    onExit: (_) => setState(() => _closeHover = false),
    child: GestureDetector(
      onTap: widget.onClose,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: _closeHover ? t.indicatorColor.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          Icons.close_rounded,
          size: 15,
          color: textColor.withValues(alpha: widget.selected || _closeHover ? 1 : 0.6),
        ),
      ),
    ),
  );
}
