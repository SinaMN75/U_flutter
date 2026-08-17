import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the navigation chrome: UTabBar (closable, reorderable tabs) and
/// USideMenu (collapsible rail with groups, pinning and search).
class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final USideMenuController _menuController = USideMenuController();
  List<UTab> _tabs = <UTab>[
    const UTab(id: "1", title: "Home", icon: Icons.home),
    const UTab(id: "2", title: "Orders", icon: Icons.receipt_long),
    const UTab(id: "3", title: "Profile", icon: Icons.person),
  ];
  int _selected = 0;

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Navigation",
    intro: "UTabBar is a browser-style tab strip (select, close, reorder). USideMenu is a "
        "responsive navigation rail that expands, groups items, pins favourites and searches.",
    sections: <Widget>[
      DemoSection(
        title: "UTabBar",
        description: "Selectable, closable tabs backed by a UTab list. Tap to select, × to close.",
        code: r'''
UTabBar(
  tabs: tabs,
  selectedIndex: selected,
  onSelect: (int i) => setState(() => selected = i),
  onClose: (int i) => setState(() => tabs = <UTab>[...tabs]..removeAt(i)),
);''',
        child: SizedBox(
          height: 56,
          child: UTabBar(
            tabs: _tabs,
            selectedIndex: _selected,
            onSelect: (int i) => setState(() => _selected = i),
            onClose: (int i) => setState(() {
              _tabs = <UTab>[..._tabs]..removeAt(i);
              if (_selected >= _tabs.length) _selected = _tabs.length - 1;
            }),
          ),
        ),
      ),
      DemoSection(
        title: "USideMenu",
        description: "A collapsible side navigation with a group, badges and built-in search.",
        code: r'''
USideMenu(
  controller: USideMenuController(),
  items: <UMenuEntry>[
    UMenuItem(id: "home", title: "Home", icon: Icons.home),
    UMenuGroup(id: "shop", title: "Shop", icon: Icons.store, children: <UMenuItem>[
      UMenuItem(id: "products", title: "Products", icon: Icons.inventory_2),
    ]),
  ],
);''',
        child: SizedBox(
          height: 360,
          child: USideMenu(
            controller: _menuController,
            enableSearch: true,
            items: <UMenuEntry>[
              const UMenuItem(id: "home", title: "Home", icon: Icons.home),
              const UMenuItem(id: "orders", title: "Orders", icon: Icons.receipt_long, badge: "3"),
              const UMenuGroup(
                id: "shop",
                title: "Shop",
                icon: Icons.store,
                children: <UMenuItem>[
                  UMenuItem(id: "products", title: "Products", icon: Icons.inventory_2),
                  UMenuItem(id: "categories", title: "Categories", icon: Icons.category),
                ],
              ),
              const UMenuItem(id: "settings", title: "Settings", icon: Icons.settings),
            ],
          ),
        ),
      ),
    ],
  );
}
