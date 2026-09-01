part of "u_admin.dart";

class UAdminShell extends StatefulWidget {
  const UAdminShell({super.key});

  @override
  State<UAdminShell> createState() => _UAdminShellState();
}

class _UAdminShellState extends State<UAdminShell> with SingleTickerProviderStateMixin {
  late final UAdminModule _dashboard = UAdmin.config.dashboard();
  late final USideMenuController _menu = USideMenuController(selectedId: _dashboard.title);

  @override
  void initState() {
    super.initState();
    U.tabs.value = <TabData>[TabData(title: _dashboard.title, page: _dashboard.page())];
    U.updateTabController();
  }

  @override
  void dispose() {
    _menu.dispose();
    U.tabController?.dispose();
    U.tabController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
      body: UColumn(
        children: <Widget>[
          if (context.isMobileWidth) URow(
            children: <Widget>[
              IconButton(icon: const Icon(Icons.menu_rounded), onPressed: _menu.openDrawer),
              _tabBar().expanded(),
            ],
          ) else _tabBar(),
          Obx(
            () => URow(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _sideMenu(),
                Expanded(
                  child: U.tabs.isEmpty
                      ? const SizedBox.shrink()
                      : TabBarView(
                          controller: U.tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: U.tabs.map((TabData tab) => tab.page).toList(),
                        ),
                ),
              ],
            ),
          ).expanded(),
        ],
      ),
    );

  Widget _tabBar() => Obx(() {
    if (U.tabs.isEmpty || U.tabController == null) return const SizedBox.shrink();
    final TabController controller = U.tabController!;
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) => UTabBar(
        selectedIndex: controller.index,
        onSelect: (int index) => U.tabController?.animateTo(index),
        onClose: _closeTab,
        onReorder: _reorderTabs,
        onMenuAction: _tabMenuAction,
        tabs: U.tabs.map((TabData tab) => UTab(id: tab.title, title: tab.title)).toList(),
      ),
    );
  });

  void _applyTabs(List<TabData> newTabs, {int? select}) {
    U.tabs.value = newTabs;
    U.updateTabController();
    if (U.tabController != null && newTabs.isNotEmpty) U.tabController!.index = (select ?? U.tabController!.index).clamp(0, newTabs.length - 1);
  }

  void _closeTab(int index) {
    final int selected = U.tabController?.index ?? 0;
    final List<TabData> newTabs = <TabData>[...U.tabs]..removeAt(index);
    int select;
    if (newTabs.isEmpty) {
      select = 0;
    } else if (index < selected) {
      select = selected - 1;
    } else if (index == selected) {
      select = index.clamp(0, newTabs.length - 1);
    } else {
      select = selected;
    }
    _applyTabs(newTabs, select: select);
  }

  void _reorderTabs(int oldIndex, int newIndex) {
    final TabData? selectedTab = (U.tabController != null && U.tabs.isNotEmpty) ? U.tabs[U.tabController!.index] : null;
    final List<TabData> newTabs = <TabData>[...U.tabs];
    final TabData moved = newTabs.removeAt(oldIndex);
    newTabs.insert(newIndex, moved);
    U.tabs.value = newTabs;
    if (U.tabController != null && newTabs.isNotEmpty) {
      final int select = selectedTab == null ? 0 : newTabs.indexOf(selectedTab);
      U.tabController!.index = (select < 0 ? 0 : select).clamp(0, newTabs.length - 1);
    }
  }

  void _tabMenuAction(UTabMenuAction action, int index) {
    switch (action) {
      case UTabMenuAction.close:
        _closeTab(index);
        break;
      case UTabMenuAction.closeOthers:
        _applyTabs(<TabData>[U.tabs[index]], select: 0);
        break;
      case UTabMenuAction.closeAll:
        _applyTabs(<TabData>[]);
        break;
      case UTabMenuAction.closeToRight:
        _applyTabs(<TabData>[...U.tabs.sublist(0, index + 1)], select: (U.tabController?.index ?? 0).clamp(0, index));
        break;
    }
  }

  List<UMenuEntry> _menuEntries() => UAdmin.config.menu().expand((UAdminGroup group) => group.toEntries()).toList();

  Widget _sideMenu() => USideMenu(
    controller: _menu,
    showRailOnMobile: false,
    searchHint: U.s.search,
    version: "v${UApp.version}",
    header: UIconTextHorizontal(
      leading: CircleAvatar(radius: 18, backgroundColor: UAdminTheme.white24, child: UImage(UAdmin.logo)),
      trailing: UTextTitleLarge(UAdmin.config.appName, color: Theme.of(context).colorScheme.surface),
    ),
    profileName: "${U.user.firstName} ${U.user.lastName}".trim(),
    profileSubtitle: U.user.email ?? U.user.phoneNumber,
    profileAvatar: CircleAvatar(radius: 18, backgroundColor: UAdminTheme.white24, child: UImage(UAdmin.logo)),
    isDarkMode: ULocalStorage.isDarkMode(),
    onToggleTheme: (bool dark) {
      UAppState.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      ULocalStorage.setDarkMode(dark);
      setState(() {});
    },
    profileMenuItems: <UMenuItem>[
      UMenuItem(id: "settings", title: U.s.settings, icon: Icons.settings_rounded),
      UMenuItem(id: "logout", title: U.s.logout, icon: Icons.logout_rounded),
    ],
    onProfileMenuSelected: (String id) {
      if (id == "settings") {
        _menu.select("settings");
        U.addOrSwitchTab(U.s.settings, const UAdminSettingsPage());
      } else if (id == "logout") {
        ULocalStorage.remove(UConstants.token);
        UNavigator.offAll(const UAdminLoginPage());
      }
    },
    items: _menuEntries(),
  );
}
