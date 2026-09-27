part of "u_admin.dart";

class UAdminModule {
  UAdminModule({required this.title, required this.icon, required this.page, this.selectedIcon, this.roles});

  final String title;
  final IconData icon;
  final Widget Function() page;
  final IconData? selectedIcon;
  final List<TagUser>? roles;

  bool get visible => UAdmin.canAccess(roles);

  UMenuItem toItem() => UMenuItem(id: title, title: title, icon: icon, selectedIcon: selectedIcon, onTap: () => U.addOrSwitchTab(title, page()));
}

class UAdminGroup {
  UAdminGroup({required this.title, required this.icon, required this.modules, this.header, this.roles});

  final String title;
  final IconData icon;
  final List<UAdminModule> modules;
  final String? header;
  final List<TagUser>? roles;

  List<UMenuEntry> toEntries() {
    final List<UMenuEntry> items = modules.where((UAdminModule m) => m.visible).map((UAdminModule m) => m.toItem()).toList();
    if (!UAdmin.canAccess(roles) || items.isEmpty) return <UMenuEntry>[];
    return <UMenuEntry>[
      if (header != null) UMenuHeader(header!),
      UMenuGroup(id: title, title: title, icon: icon, children: items),
    ];
  }
}
