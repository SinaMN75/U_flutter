import "dart:math" as math;

import "package:u/utilities.dart";

enum USideMenuIndicatorStyle { bar, pill, filled, gradient, none }

abstract class UMenuEntry {
  const UMenuEntry();
}

class UMenuHeader extends UMenuEntry {
  final String label;

  const UMenuHeader(this.label);
}

class UMenuItem extends UMenuEntry {
  final String id;
  final String title;
  final IconData icon;
  final IconData? selectedIcon;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;
  final bool pinnable;
  final String? tooltip;

  const UMenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.selectedIcon,
    this.onTap,
    this.badge,
    this.badgeColor,
    this.trailing,
    this.pinnable = true,
    this.tooltip,
  });
}

class UMenuGroup extends UMenuEntry {
  final String id;
  final String title;
  final IconData icon;
  final List<UMenuEntry> children;
  final bool initiallyExpanded;

  const UMenuGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });
}

class USideMenuController extends ChangeNotifier {
  USideMenuController({
    this._selectedId,
    this._collapsed = false,
    Set<String>? expandedGroups,
    Set<String>? pinnedIds,
  }) : _expandedGroups = expandedGroups ?? <String>{},
       _pinnedIds = pinnedIds ?? <String>{};

  String? _selectedId;
  bool _collapsed;
  String _search = "";
  final Set<String> _expandedGroups;
  final Set<String> _pinnedIds;

  String? get selectedId => _selectedId;

  set selectedId(String? value) {
    if (_selectedId != value) {
      _selectedId = value;
      notifyListeners();
    }
  }

  void select(String id) => selectedId = id;

  bool get collapsed => _collapsed;

  set collapsed(bool value) {
    if (_collapsed != value) {
      _collapsed = value;
      notifyListeners();
    }
  }

  void toggleCollapsed() => collapsed = !_collapsed;

  String get search => _search;

  set search(String value) {
    if (_search != value) {
      _search = value;
      notifyListeners();
    }
  }

  bool isGroupExpanded(String id) => _expandedGroups.contains(id);

  void toggleGroup(String id) {
    if (!_expandedGroups.remove(id)) _expandedGroups.add(id);
    notifyListeners();
  }

  void setGroupExpanded(String id, bool expanded) {
    final bool changed = expanded ? _expandedGroups.add(id) : _expandedGroups.remove(id);
    if (changed) notifyListeners();
  }

  bool isPinned(String id) => _pinnedIds.contains(id);

  Set<String> get pinnedIds => Set<String>.unmodifiable(_pinnedIds);

  void togglePin(String id) {
    if (!_pinnedIds.remove(id)) _pinnedIds.add(id);
    notifyListeners();
  }

  VoidCallback? _openDrawerCb;
  VoidCallback? _closeDrawerCb;

  void attachDrawer(VoidCallback open, VoidCallback close) {
    _openDrawerCb = open;
    _closeDrawerCb = close;
  }

  void detachDrawer() {
    _openDrawerCb = null;
    _closeDrawerCb = null;
  }

  void openDrawer() => _openDrawerCb?.call();

  void closeDrawer() => _closeDrawerCb?.call();
}

class USideMenuTheme {
  final double expandedWidth;
  final double railWidth;
  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final Color selectedItemColor;
  final Color hoverColor;
  final Color indicatorColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final TextStyle? itemTextStyle;
  final TextStyle? headerTextStyle;
  final double iconSize;
  final double itemSpacing;
  final EdgeInsetsGeometry itemPadding;
  final BorderRadius itemRadius;
  final USideMenuIndicatorStyle indicatorStyle;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool enableHoverElevation;
  final List<BoxShadow>? shadow;
  final Color scrimColor;
  final Color dividerColor;

  const USideMenuTheme({
    required this.backgroundColor,
    required this.selectedItemColor,
    required this.hoverColor,
    required this.indicatorColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.scrimColor,
    required this.dividerColor,
    this.expandedWidth = 280,
    this.railWidth = 84,
    this.backgroundGradient,
    this.itemTextStyle,
    this.headerTextStyle,
    this.iconSize = 22,
    this.itemSpacing = 4,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.itemRadius = const BorderRadius.all(Radius.circular(14)),
    this.indicatorStyle = USideMenuIndicatorStyle.bar,
    this.animationDuration = const Duration(milliseconds: 600),
    this.animationCurve = Curves.easeOutCubic,
    this.enableHoverElevation = true,
    this.shadow,
  });

  factory USideMenuTheme.from(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = cs.primary;
    final Color on = cs.onPrimary;
    return USideMenuTheme(
      backgroundColor: bg,
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.alphaBlend(Colors.white.withValues(alpha: 0.04), bg),
          Color.alphaBlend(Colors.black.withValues(alpha: 0.16), bg),
        ],
      ),
      selectedItemColor: on.withValues(alpha: 0.16),
      hoverColor: on.withValues(alpha: 0.08),
      indicatorColor: on,
      selectedTextColor: on,
      unselectedTextColor: on.withValues(alpha: 0.74),
      selectedIconColor: on,
      unselectedIconColor: on.withValues(alpha: 0.74),
      headerTextStyle: TextStyle(
        color: on.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      shadow: <BoxShadow>[
        BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
      ],
      scrimColor: Colors.black.withValues(alpha: 0.5),
      dividerColor: on.withValues(alpha: 0.12),
    );
  }

  USideMenuTheme copyWith({
    double? expandedWidth,
    double? railWidth,
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? selectedItemColor,
    Color? hoverColor,
    Color? indicatorColor,
    Color? selectedTextColor,
    Color? unselectedTextColor,
    Color? selectedIconColor,
    Color? unselectedIconColor,
    TextStyle? itemTextStyle,
    TextStyle? headerTextStyle,
    double? iconSize,
    double? itemSpacing,
    EdgeInsetsGeometry? itemPadding,
    BorderRadius? itemRadius,
    USideMenuIndicatorStyle? indicatorStyle,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableHoverElevation,
    List<BoxShadow>? shadow,
    Color? scrimColor,
    Color? dividerColor,
  }) => USideMenuTheme(
    expandedWidth: expandedWidth ?? this.expandedWidth,
    railWidth: railWidth ?? this.railWidth,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    selectedItemColor: selectedItemColor ?? this.selectedItemColor,
    hoverColor: hoverColor ?? this.hoverColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    selectedTextColor: selectedTextColor ?? this.selectedTextColor,
    unselectedTextColor: unselectedTextColor ?? this.unselectedTextColor,
    selectedIconColor: selectedIconColor ?? this.selectedIconColor,
    unselectedIconColor: unselectedIconColor ?? this.unselectedIconColor,
    itemTextStyle: itemTextStyle ?? this.itemTextStyle,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    iconSize: iconSize ?? this.iconSize,
    itemSpacing: itemSpacing ?? this.itemSpacing,
    itemPadding: itemPadding ?? this.itemPadding,
    itemRadius: itemRadius ?? this.itemRadius,
    indicatorStyle: indicatorStyle ?? this.indicatorStyle,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    enableHoverElevation: enableHoverElevation ?? this.enableHoverElevation,
    shadow: shadow ?? this.shadow,
    scrimColor: scrimColor ?? this.scrimColor,
    dividerColor: dividerColor ?? this.dividerColor,
  );
}

class USideMenu extends StatefulWidget {
  const USideMenu({
    required this.controller,
    required this.items,
    super.key,
    this.theme,
    this.header,
    this.enableSearch = true,
    this.searchHint = "Search…",
    this.enablePinning = true,
    this.pinnedSectionLabel = "PINNED",
    this.enableToggleButton = true,
    this.showRailOnMobile = true,
    this.mobileBreakpoint = 720,
    this.autoCollapseBreakpoint = 1000,
    this.profileName,
    this.profileSubtitle,
    this.profileAvatar,
    this.profileMenuItems,
    this.onProfileMenuSelected,
    this.isDarkMode,
    this.onToggleTheme,
    this.version,
    this.footer,
  });

  final USideMenuController controller;
  final List<UMenuEntry> items;
  final USideMenuTheme? theme;
  final Widget? header;
  final bool enableSearch;
  final String searchHint;
  final bool enablePinning;
  final String pinnedSectionLabel;
  final bool enableToggleButton;
  final bool showRailOnMobile;
  final double mobileBreakpoint;
  final double autoCollapseBreakpoint;
  final String? profileName;
  final String? profileSubtitle;
  final Widget? profileAvatar;
  final List<UMenuItem>? profileMenuItems;
  final ValueChanged<String>? onProfileMenuSelected;
  final bool? isDarkMode;
  final ValueChanged<bool>? onToggleTheme;
  final String? version;
  final Widget? footer;

  @override
  State<USideMenu> createState() => _USideMenuState();
}

class _USideMenuState extends State<USideMenu> with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _drawer;
  final OverlayPortalController _portal = OverlayPortalController();
  final TextEditingController _searchCtrl = TextEditingController();
  late USideMenuTheme _t;

  @override
  void initState() {
    super.initState();
    _seedExpandedGroups(widget.items);
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _drawer = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    widget.controller.addListener(_onControllerChanged);
    widget.controller.attachDrawer(_openDrawer, _closeDrawer);
  }

  void _seedExpandedGroups(List<UMenuEntry> entries) {
    for (final UMenuEntry e in entries) {
      if (e is UMenuGroup) {
        if (e.initiallyExpanded) widget.controller.setGroupExpanded(e.id, true);
        _seedExpandedGroups(e.children);
      }
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant USideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.detachDrawer();
      widget.controller.addListener(_onControllerChanged);
      widget.controller.attachDrawer(_openDrawer, _closeDrawer);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.detachDrawer();
    _reveal.dispose();
    _drawer.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < widget.mobileBreakpoint;

  bool get _autoCollapsed => MediaQuery.sizeOf(context).width < widget.autoCollapseBreakpoint;

  bool get _effectiveCollapsed => _isMobile || (widget.controller.collapsed || _autoCollapsed);

  void _openDrawer() {
    _portal.show();
    _drawer.forward();
  }

  Future<void> _closeDrawer() async {
    await _drawer.reverse();
    if (mounted) _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    _t = widget.theme ?? USideMenuTheme.from(context);

    if (_isMobile) {
      return OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildMobileOverlay,
        child: widget.showRailOnMobile ? _buildRail(showHamburger: true) : const SizedBox.shrink(),
      );
    }
    return _buildPanel(_effectiveCollapsed, inOverlay: false);
  }

  Widget _buildPanel(bool collapsed, {required bool inOverlay}) => AnimatedContainer(
    duration: _t.animationDuration,
    curve: _t.animationCurve,
    width: collapsed ? _t.railWidth : _t.expandedWidth,
    decoration: BoxDecoration(
      color: _t.backgroundGradient == null ? _t.backgroundColor : null,
      gradient: _t.backgroundGradient,
      boxShadow: inOverlay ? _t.shadow : null,
    ),
    child: _buildContent(collapsed, inOverlay: inOverlay),
  );

  Widget _buildRail({required bool showHamburger}) => UContainer(
    width: _t.railWidth,
    color: _t.backgroundGradient == null ? _t.backgroundColor : null,
    gradient: _t.backgroundGradient,
    child: _buildContent(true, inOverlay: false, forceHamburger: showHamburger),
  );

  Widget _buildMobileOverlay(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Size size = MediaQuery.sizeOf(context);
    final CurvedAnimation curved = CurvedAnimation(parent: _drawer, curve: Curves.easeOutCubic);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FadeTransition(
              opacity: curved,
              child: UContainer(
                onTap: _closeDrawer,
                color: _t.scrimColor,
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: rtl ? null : 0,
            right: rtl ? 0 : null,
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(rtl ? 1 : -1, 0), end: Offset.zero).animate(curved),
              child: Material(
                color: Colors.transparent,
                child: _buildPanel(false, inOverlay: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool collapsed, {required bool inOverlay, bool forceHamburger = false}) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeaderRow(collapsed, inOverlay: inOverlay, forceHamburger: forceHamburger),
        if (widget.enableSearch && !collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: _buildSearchBox(),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: collapsed ? 8 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildEntries(collapsed),
            ),
          ),
        ),
        _buildFooter(collapsed),
      ],
    ),
  );

  Widget _buildHeaderRow(bool collapsed, {required bool inOverlay, required bool forceHamburger}) {
    final List<Widget> children = <Widget>[];
    if (widget.header != null) {
      children.add(
        Expanded(
          child: AnimatedSwitcher(
            duration: _t.animationDuration,
            child: collapsed
                ? Center(
                    key: const ValueKey<String>("logo-c"),
                    child: _LogoFallback(header: widget.header!),
                  )
                : Padding(
                    key: const ValueKey<String>("logo-e"),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: widget.header,
                  ),
          ),
        ),
      );
    } else {
      children.add(const Spacer());
    }

    if (inOverlay) {
      children.add(
        IconButton(
          tooltip: "Close",
          color: _t.indicatorColor,
          icon: const Icon(Icons.close_rounded),
          onPressed: _closeDrawer,
        ),
      );
    } else if (forceHamburger) {
      children.add(
        IconButton(
          tooltip: "Menu",
          color: _t.indicatorColor,
          icon: const Icon(Icons.menu_rounded),
          onPressed: _openDrawer,
        ),
      );
    } else if (widget.enableToggleButton && !_autoCollapsed) {
      children.add(
        IconButton(
          tooltip: collapsed ? "Expand" : "Collapse",
          color: _t.indicatorColor,
          icon: AnimatedRotation(
            turns: collapsed ? 0.5 : 0,
            duration: _t.animationDuration,
            child: const Icon(Icons.menu_open_rounded),
          ),
          onPressed: widget.controller.toggleCollapsed,
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: children),
    );
  }

  Widget _buildSearchBox() => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.9, end: 1),
    duration: _t.animationDuration,
    curve: Curves.easeOutBack,
    builder: (BuildContext context, double scale, Widget? child) => Transform.scale(scale: scale, child: child),
    child: TextField(
      controller: _searchCtrl,
      onChanged: (String v) => widget.controller.search = v,
      style: TextStyle(color: _t.selectedTextColor, fontSize: 14),
      cursorColor: _t.indicatorColor,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.searchHint,
        hintStyle: TextStyle(color: _t.unselectedTextColor.withValues(alpha: 0.7), fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: _t.unselectedIconColor, size: 20),
        suffixIcon: widget.controller.search.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, color: _t.unselectedIconColor, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  widget.controller.search = "";
                },
              ),
        filled: true,
        fillColor: _t.hoverColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _t.indicatorColor.withValues(alpha: 0.6)),
        ),
      ),
    ),
  );

  List<Widget> _buildEntries(bool collapsed) {
    final String query = widget.controller.search.trim().toLowerCase();
    final bool searching = query.isNotEmpty;
    final List<Widget> out = <Widget>[];
    int revealIndex = 0;

    Widget reveal(Widget child) => _Reveal(parent: _reveal, index: revealIndex++, child: child);

    if (widget.enablePinning && !collapsed && !searching && widget.controller.pinnedIds.isNotEmpty) {
      final List<UMenuItem> pinned = _allItems().where((UMenuItem i) => widget.controller.isPinned(i.id)).toList();
      if (pinned.isNotEmpty) {
        out.add(reveal(_buildHeaderLabel(widget.pinnedSectionLabel)));
        for (final UMenuItem item in pinned) {
          out.add(reveal(_buildItemTile(item, collapsed: collapsed)));
        }
        out.add(reveal(_buildDivider()));
      }
    }

    for (final UMenuEntry entry in widget.items) {
      if (entry is UMenuHeader) {
        if (!collapsed && !searching) out.add(reveal(_buildHeaderLabel(entry.label)));
      } else if (entry is UMenuItem) {
        if (searching && !_matches(entry, query)) continue;
        out.add(reveal(_buildItemTile(entry, collapsed: collapsed)));
      } else if (entry is UMenuGroup) {
        if (searching && !_entryMatches(entry, query)) continue;

        if (collapsed) {
          for (final UMenuItem child in _collectLeafItems(entry)) {
            if (searching && !_matches(child, query)) continue;
            out.add(reveal(_buildItemTile(child, collapsed: true)));
          }
        } else {
          out.add(reveal(_buildGroup(entry, depth: 0, searching: searching, query: query)));
        }
      }
    }

    if (searching && out.isEmpty) {
      out.add(
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "No results",
            textAlign: .center,
            style: TextStyle(color: _t.unselectedTextColor),
          ),
        ),
      );
    }
    return out;
  }

  List<UMenuItem> _allItems() {
    final List<UMenuItem> result = <UMenuItem>[];
    for (final UMenuEntry e in widget.items) {
      if (e is UMenuItem) result.add(e);
      if (e is UMenuGroup) result.addAll(_collectLeafItems(e));
    }
    return result;
  }

  // Flattens a group's entire subtree down to its leaf items.
  List<UMenuItem> _collectLeafItems(UMenuGroup group) {
    final List<UMenuItem> result = <UMenuItem>[];
    for (final UMenuEntry child in group.children) {
      if (child is UMenuItem) result.add(child);
      if (child is UMenuGroup) result.addAll(_collectLeafItems(child));
    }
    return result;
  }

  bool _matches(UMenuItem item, String query) => item.title.toLowerCase().contains(query);

  bool _entryMatches(UMenuEntry entry, String query) {
    if (entry is UMenuItem) return _matches(entry, query);
    if (entry is UMenuGroup) return entry.title.toLowerCase().contains(query) || entry.children.any((UMenuEntry c) => _entryMatches(c, query));
    return false;
  }

  List<UMenuEntry> _filterChildren(UMenuGroup group, bool searching, String query) {
    if (!searching || group.title.toLowerCase().contains(query)) return group.children;
    return group.children.where((UMenuEntry c) => _entryMatches(c, query)).toList();
  }

  Widget _buildGroup(UMenuGroup group, {required int depth, required bool searching, required String query}) {
    final List<Widget> childWidgets = <Widget>[];
    for (final UMenuEntry child in _filterChildren(group, searching, query)) {
      if (child is UMenuHeader) {
        childWidgets.add(_buildHeaderLabel(child.label));
      } else if (child is UMenuItem) {
        childWidgets.add(_buildItemTile(child, collapsed: false, depth: depth + 1));
      } else if (child is UMenuGroup) {
        childWidgets.add(_buildGroup(child, depth: depth + 1, searching: searching, query: query));
      }
    }
    return _GroupTile(
      key: ValueKey<String>("group-${group.id}"),
      group: group,
      theme: _t,
      depth: depth,
      expanded: searching || widget.controller.isGroupExpanded(group.id),
      forceExpanded: searching,
      onToggle: () => widget.controller.toggleGroup(group.id),
      childWidgets: childWidgets,
    );
  }

  Widget _buildHeaderLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 14, 16, 6),
    child: Text(label, style: _t.headerTextStyle),
  );

  Widget _buildDivider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    child: Divider(height: 1, thickness: 1, color: _t.dividerColor),
  );

  Widget _buildItemTile(UMenuItem item, {required bool collapsed, int depth = 0}) => _ItemTile(
    item: item,
    theme: _t,
    collapsed: collapsed,
    depth: depth,
    selected: widget.controller.selectedId == item.id,
    pinned: widget.controller.isPinned(item.id),
    enablePinning: widget.enablePinning && item.pinnable,
    onTap: () {
      item.onTap?.call();
      widget.controller.select(item.id);
      if (_isMobile) _closeDrawer();
    },
    onTogglePin: () => widget.controller.togglePin(item.id),
  );

  Widget _buildFooter(bool collapsed) {
    if (widget.footer != null) return widget.footer!;

    final bool hasProfile = widget.profileName != null || widget.profileAvatar != null;
    final bool hasTheme = widget.isDarkMode != null && widget.onToggleTheme != null;
    if (!hasProfile && !hasTheme && widget.version == null) return const SizedBox.shrink();

    return UContainer(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      border: Border(top: BorderSide(color: _t.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasTheme) _buildThemeToggle(collapsed),
          if (hasProfile) _buildProfile(collapsed),
          if (widget.version != null && !collapsed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.version!,
                textAlign: .center,
                style: TextStyle(color: _t.unselectedTextColor.withValues(alpha: 0.6), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(bool collapsed) {
    final bool dark = widget.isDarkMode ?? false;
    final Widget icon = AnimatedSwitcher(
      duration: _t.animationDuration,
      transitionBuilder: (Widget child, Animation<double> a) => RotationTransition(
        turns: Tween<double>(begin: 0.75, end: 1).animate(a),
        child: FadeTransition(opacity: a, child: child),
      ),
      child: Icon(
        dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        key: ValueKey<bool>(dark),
        color: _t.indicatorColor,
        size: 20,
      ),
    );

    if (collapsed) {
      return IconButton(
        tooltip: dark ? "Light mode" : "Dark mode",
        onPressed: () => widget.onToggleTheme!(!dark),
        icon: icon,
      );
    }

    return InkWell(
      borderRadius: _t.itemRadius,
      onTap: () => widget.onToggleTheme!(!dark),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dark ? "Dark mode" : "Light mode",
                style: TextStyle(color: _t.selectedTextColor, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            _MiniSwitch(value: dark, color: _t.indicatorColor, track: _t.hoverColor),
          ],
        ),
      ),
    );
  }

  String _initial(String? name) {
    final String n = (name ?? "").trim();
    return n.isEmpty ? "?" : n.substring(0, 1).toUpperCase();
  }

  Widget _buildProfile(bool collapsed) {
    final Widget avatar =
        widget.profileAvatar ??
        CircleAvatar(
          radius: 18,
          backgroundColor: _t.indicatorColor.withValues(alpha: 0.2),
          child: Text(
            _initial(widget.profileName),
            style: TextStyle(color: _t.indicatorColor, fontWeight: FontWeight.w700),
          ),
        );

    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: <Widget>[
          avatar,
          if (!collapsed) ...<Widget>[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.profileName ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _t.selectedTextColor, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (widget.profileSubtitle != null)
                    Text(
                      widget.profileSubtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _t.unselectedTextColor, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (widget.profileMenuItems != null && widget.profileMenuItems!.isNotEmpty) Icon(Icons.more_vert_rounded, color: _t.unselectedIconColor, size: 20),
          ],
        ],
      ),
    );

    if (widget.profileMenuItems == null || widget.profileMenuItems!.isEmpty) {
      return Material(color: Colors.transparent, child: row);
    }

    return PopupMenuButton<String>(
      tooltip: "",
      offset: const Offset(0, -8),
      onSelected: (String id) => widget.onProfileMenuSelected?.call(id),
      itemBuilder: (BuildContext context) => widget.profileMenuItems!
          .map(
            (UMenuItem i) => PopupMenuItem<String>(
              value: i.id,
              child: Row(
                children: <Widget>[
                  Icon(i.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(i.title),
                ],
              ),
            ),
          )
          .toList(),
      child: InkWell(borderRadius: _t.itemRadius, child: row),
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({
    required this.item,
    required this.theme,
    required this.collapsed,
    required this.selected,
    required this.pinned,
    required this.enablePinning,
    required this.onTap,
    required this.onTogglePin,
    this.depth = 0,
  });

  final UMenuItem item;
  final USideMenuTheme theme;
  final bool collapsed;
  final int depth;
  final bool selected;
  final bool pinned;
  final bool enablePinning;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final USideMenuTheme t = widget.theme;
    final bool selected = widget.selected;
    final bool active = selected;

    final Color bg = _backgroundColor();
    final Color iconColor = active ? t.selectedIconColor : t.unselectedIconColor;
    final Color textColor = active ? t.selectedTextColor : t.unselectedTextColor;

    final Widget iconData = Icon(
      active ? (widget.item.selectedIcon ?? widget.item.icon) : widget.item.icon,
      size: t.iconSize,
      color: iconColor,
    );

    final Widget icon = widget.item.badge == null
        ? iconData
        : Badge(
            label: Text(widget.item.badge!, style: const TextStyle(fontSize: 10)),
            backgroundColor: widget.item.badgeColor ?? Colors.redAccent,
            child: iconData,
          );

    final Widget tile = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover && t.enableHoverElevation ? 1.05 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: t.itemPadding.horizontal / 2,
            vertical: t.itemSpacing / 2,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: t.itemRadius,
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: t.animationDuration,
                curve: t.animationCurve,
                decoration: BoxDecoration(
                  color: t.indicatorStyle == USideMenuIndicatorStyle.gradient && active ? null : bg,
                  gradient: t.indicatorStyle == USideMenuIndicatorStyle.gradient && active
                      ? LinearGradient(
                          colors: <Color>[
                            t.indicatorColor.withValues(alpha: 0.28),
                            t.indicatorColor.withValues(alpha: 0.06),
                          ],
                        )
                      : null,
                  borderRadius: t.itemRadius,
                ),
                child: ListTile(
                  leading: _buildLeadingIndicator(active),
                  title: widget.collapsed
                      ? icon
                      : ListTile(
                          leading: icon,
                          title: AnimatedDefaultTextStyle(
                            duration: t.animationDuration,
                            style: Theme.of(context).textTheme.bodyLarge!.merge(t.itemTextStyle).copyWith(color: textColor, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
                            child: Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          trailing: _buildTrailing(t),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.collapsed) {
      return Tooltip(
        message: widget.item.tooltip ?? widget.item.title,
        preferBelow: false,
        child: tile,
      );
    }
    return tile;
  }

  Widget _buildLeadingIndicator(bool active) {
    if (widget.theme.indicatorStyle != USideMenuIndicatorStyle.bar) {
      return const SizedBox(width: 4);
    }
    return AnimatedContainer(
      duration: widget.theme.animationDuration,
      curve: widget.theme.animationCurve,
      width: 4,
      height: active ? 32 : 0,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: widget.theme.indicatorColor,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
      ),
    );
  }

  Widget _buildTrailing(USideMenuTheme t) {
    if (widget.enablePinning && (_hover || widget.pinned)) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        tooltip: widget.pinned ? "Unpin" : "Pin",
        icon: Icon(
          widget.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          size: 16,
          color: widget.pinned ? t.indicatorColor : t.unselectedIconColor,
        ),
        onPressed: widget.onTogglePin,
      );
    }
    if (widget.item.trailing != null) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: widget.item.trailing);
    }
    return const SizedBox(width: 8);
  }

  Color _backgroundColor() {
    final USideMenuTheme t = widget.theme;
    if (widget.selected) {
      switch (t.indicatorStyle) {
        case USideMenuIndicatorStyle.none:
        case USideMenuIndicatorStyle.bar:
          return _hover ? t.selectedItemColor.withValues(alpha: 0.22) : t.selectedItemColor;
        case USideMenuIndicatorStyle.pill:
        case USideMenuIndicatorStyle.filled:
          return t.indicatorColor.withValues(alpha: _hover ? 0.26 : 0.2);
        case USideMenuIndicatorStyle.gradient:
          return Colors.transparent;
      }
    }
    return _hover ? t.hoverColor : Colors.transparent;
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.theme,
    required this.depth,
    required this.expanded,
    required this.forceExpanded,
    required this.onToggle,
    required this.childWidgets,
    super.key,
  });

  final UMenuGroup group;
  final USideMenuTheme theme;
  final int depth;
  final bool expanded;
  final bool forceExpanded;
  final VoidCallback onToggle;
  final List<Widget> childWidgets;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ListTile(
        onTap: forceExpanded ? null : onToggle,
        contentPadding: EdgeInsets.only(left: (16 + depth * 14).toDouble(), right: 8),
        leading: Icon(group.icon, size: theme.iconSize, color: theme.unselectedIconColor),
        title: UTextBodyMedium(
          group.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          color: theme.unselectedTextColor,
        ),
        trailing: AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: theme.animationDuration,
          curve: theme.animationCurve,
          child: Icon(Icons.keyboard_arrow_down_rounded, color: theme.unselectedIconColor),
        ),
      ).pSymmetric(
        horizontal: theme.itemPadding.horizontal / 2,
        vertical: theme.itemSpacing / 2,
      ),
      AnimatedSize(
        duration: theme.animationDuration,
        curve: theme.animationCurve,
        alignment: Alignment.topCenter,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: expanded ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: childWidgets,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.parent, required this.index, required this.child});

  final Animation<double> parent;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double start = math.min(index * 0.05, 0.7);
    final Animation<double> anim = CurvedAnimation(
      parent: parent,
      curve: Interval(start, math.min(start + 0.5, 1), curve: Curves.easeOutCubic),
    );
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: anim,
      builder: (BuildContext context, Widget? child) {
        final double t = anim.value;
        final double dx = (1 - t) * 18 * (rtl ? -1 : 1);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
      child: child,
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) => SizedBox(width: 40, height: 40, child: FittedBox(child: header));
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.value, required this.color, required this.track});

  final bool value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 240),
    curve: Curves.easeOut,
    width: 40,
    height: 22,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: value ? color.withValues(alpha: 0.35) : track,
      borderRadius: BorderRadius.circular(20),
    ),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: UContainer(
        width: 16,
        height: 16,
        color: color,
        shape: BoxShape.circle,
      ),
    ),
  );
}
