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
  UAdminGroup({
    required this.title,
    required this.icon,
    this.modules = const <UAdminModule>[],
    this.groups = const <UAdminGroup>[],
    this.id,
    this.header,
    this.roles,
    this.expanded = false,
  });

  final String title;
  final IconData icon;
  final List<UAdminModule> modules;
  final List<UAdminGroup> groups;
  final String? id;
  final String? header;
  final bool expanded;
  final List<TagUser>? roles;

  String get resolvedId => id ?? title;

  List<UMenuEntry> _children() {
    final List<UMenuEntry> children = <UMenuEntry>[];
    for (final UAdminModule m in modules.where((UAdminModule m) => m.visible)) {
      children.add(m.toItem());
    }
    for (final UAdminGroup g in groups) {
      final UMenuGroup? sub = g._toGroup();
      if (sub != null) children.add(sub);
    }
    return children;
  }

  UMenuGroup? _toGroup() {
    if (!UAdmin.canAccess(roles)) return null;
    final List<UMenuEntry> children = _children();
    if (children.isEmpty) return null;
    return UMenuGroup(
      id: resolvedId,
      title: title,
      icon: icon,
      initiallyExpanded: expanded,
      children: children,
    );
  }

  List<UMenuEntry> toEntries() {
    final UMenuGroup? group = _toGroup();
    if (group == null) return <UMenuEntry>[];
    return <UMenuEntry>[
      if (header != null) UMenuHeader(header!),
      group,
    ];
  }
}

abstract class UAdminModules {
  static UAdminModule financialOpsDashboard({List<TagUser>? roles}) => UAdminModule(
    title: U.s.financialAndOperations,
    icon: Icons.account_balance_wallet_rounded,
    page: () => const UAdminFinancialOpsDashboardPage(),
    roles: roles,
  );

  static UAdminModule propertyDashboard({List<TagUser>? roles}) => UAdminModule(
    title: "${U.s.propertyDashboard} ⚡",
    icon: Icons.apartment_rounded,
    page: () => const UAdminHotelDashboardPage(),
    roles: roles,
  );

  static UAdminModule hotels({List<TagUser>? roles}) => UAdminModule(
    title: U.s.hotels,
    icon: Icons.apartment_rounded,
    page: () => const UAdminHotelPage(),
    roles: roles,
  );

  static UAdminModule hotelRooms({List<TagUser>? roles}) => UAdminModule(
    title: U.s.hotelRooms,
    icon: Icons.meeting_room_rounded,
    page: () => const UAdminHotelRoomPage(),
    roles: roles,
  );

  static UAdminModule reservations({List<TagUser>? roles}) => UAdminModule(
    title: U.s.reservations,
    icon: Icons.event_available_rounded,
    page: () => const UAdminReservationPage(),
    roles: roles,
  );

  static UAdminModule dorms({List<TagUser>? roles}) => UAdminModule(
    title: U.s.dorms,
    icon: Icons.bedroom_parent_rounded,
    page: () => const UAdminDormPage(),
    roles: roles,
  );

  static UAdminModule dormRooms({List<TagUser>? roles}) => UAdminModule(
    title: U.s.dormRooms,
    icon: Icons.meeting_room_rounded,
    page: () => const UAdminDormRoomPage(),
    roles: roles,
  );

  static UAdminModule dormBeds({List<TagUser>? roles}) => UAdminModule(
    title: U.s.beds,
    icon: Icons.bed_rounded,
    page: () => const UAdminDormBedPage(),
    roles: roles,
  );

  static UAdminModule contracts({List<TagUser>? roles}) => UAdminModule(
    title: U.s.contracts,
    icon: Icons.description_rounded,
    page: () => const UAdminContractPage(),
    roles: roles,
  );

  static UAdminModule invoices({List<TagUser>? roles}) => UAdminModule(
    title: U.s.invoices,
    icon: Icons.receipt_long_rounded,
    page: () => const UAdminInvoicePage(),
    roles: roles,
  );

  static UAdminModule users({List<TagUser>? roles}) => UAdminModule(
    title: U.s.users,
    icon: Icons.person_rounded,
    page: () => UAdminUserPage(args: UAdminUsersPageArgs()),
    roles: roles,
  );

  static UAdminModule adminUsers({List<TagUser>? roles, UAdminActionBuilder<UUserResponse>? actions}) => UAdminModule(
    title: U.s.users,
    icon: Icons.manage_accounts_rounded,
    page: () => UAdminUsersPage(actions: actions),
    roles: roles,
  );

  static UAdminModule merchants({List<TagUser>? roles, UAdminActionBuilder<UMerchantResponse>? actions}) => UAdminModule(
    title: U.s.merchants,
    icon: Icons.storefront_rounded,
    page: () => UAdminMerchantsPage(actions: actions),
    roles: roles,
  );

  static UAdminModule terminals({List<TagUser>? roles, UAdminActionBuilder<UTerminalResponse>? actions}) => UAdminModule(
    title: U.s.terminals,
    icon: Icons.point_of_sale_rounded,
    page: () => UAdminTerminalsPage(actions: actions),
    roles: roles,
  );

  static UAdminModule moadis({List<TagUser>? roles, UAdminActionBuilder<UMoadiResponse>? actions}) => UAdminModule(
    title: U.s.taxpayerRequests,
    icon: Icons.receipt_long_rounded,
    page: () => UAdminMoadisPage(actions: actions),
    roles: roles,
  );

  static UAdminModule gold({List<TagUser>? roles}) => UAdminModule(
    title: U.s.gold,
    icon: Icons.diamond_rounded,
    page: () => const UAdminGoldPage(),
    roles: roles,
  );

  static UAdminModule wallet({List<TagUser>? roles}) => UAdminModule(
    title: U.s.wallets,
    icon: Icons.account_balance_wallet_rounded,
    page: () => const UAdminWalletPage(),
    roles: roles,
  );

  static UAdminModule transactions({List<TagUser>? roles}) => UAdminModule(
    title: U.s.transactions,
    icon: Icons.swap_horiz_rounded,
    page: () => const UAdminTransactionsPage(),
    roles: roles,
  );

  static UAdminModule accounting({List<TagUser>? roles}) => UAdminModule(
    title: U.s.accounting,
    icon: Icons.bar_chart_rounded,
    page: () => const UAdminAccountingPage(),
    roles: roles,
  );

  static UAdminModule parking({List<TagUser>? roles, UAdminActionBuilder<UParkingResponse>? actions}) => UAdminModule(
    title: U.s.parking,
    icon: Icons.local_parking_rounded,
    page: () => UAdminParkingPage(actions: actions),
    roles: roles,
  );

  static UAdminModule parkingReport({List<TagUser>? roles}) => UAdminModule(
    title: U.s.parkingReports,
    icon: Icons.assessment_rounded,
    page: () => const UAdminParkingReportPage(),
    roles: roles,
  );

  static UAdminModule parkingTariff({List<TagUser>? roles}) => UAdminModule(
    title: U.s.tariffs,
    icon: Icons.request_quote_rounded,
    page: () => const UAdminParkingTariffPage(),
    roles: roles,
  );

  static UAdminModule parkingSubscription({List<TagUser>? roles}) => UAdminModule(
    title: U.s.subscriptions,
    icon: Icons.card_membership_rounded,
    page: () => const UAdminParkingSubscriptionPage(),
    roles: roles,
  );

  static UAdminModule parkingStaff({List<TagUser>? roles}) => UAdminModule(
    title: U.s.staffManagement,
    icon: Icons.badge_rounded,
    page: () => const UAdminParkingStaffPage(),
    roles: roles,
  );

  static UAdminModule parkingPlateFlag({List<TagUser>? roles}) => UAdminModule(
    title: U.s.specialPlates,
    icon: Icons.gpp_maybe_rounded,
    page: () => const UAdminParkingPlateFlagPage(),
    roles: roles,
  );

  static UAdminModule parkingShift({List<TagUser>? roles}) => UAdminModule(
    title: U.s.shift,
    icon: Icons.point_of_sale_rounded,
    page: () => const UAdminParkingShiftPage(),
    roles: roles,
  );

  static UAdminModule blogs({List<TagUser>? roles}) => UAdminModule(
    title: U.s.blogs,
    icon: Icons.article_rounded,
    page: () => const UAdminBlogPage(),
    roles: roles,
  );

  static UAdminModule contents({List<TagUser>? roles}) => UAdminModule(
    title: U.s.content,
    icon: Icons.content_copy,
    selectedIcon: Icons.content_copy_outlined,
    page: () => const UAdminContentsPage(),
    roles: roles,
  );

  static UAdminModule pnApiTester({List<TagUser>? roles}) => UAdminModule(
    title: U.s.pnapiTester,
    icon: Icons.api_rounded,
    page: () => const UAdminPnTesterPage(),
    roles: roles,
  );

  static UAdminModule cryptoTester({List<TagUser>? roles}) => UAdminModule(
    title: U.s.cryptoTester,
    icon: Icons.security_rounded,
    page: () => const UAdminCryptoTesterPage(),
    roles: roles,
  );

  static UAdminModule barcodeGenerator({List<TagUser>? roles}) => UAdminModule(
    title: U.s.barcodeqrGenerator,
    icon: Icons.qr_code_2_rounded,
    page: () => const UAdminBarcodeGeneratorPage(),
    roles: roles,
  );

  static UAdminModule fileManager({List<TagUser>? roles}) => UAdminModule(
    title: U.s.fileManager,
    icon: Icons.folder_open_rounded,
    page: () => const UAdminFileManagerPage(),
    roles: roles,
  );

  static UAdminModule dbAdmin({List<TagUser>? roles}) => UAdminModule(
    title: U.s.databaseConsole,
    icon: Icons.storage_rounded,
    page: () => const UAdminDbAdminPage(),
    roles: roles,
  );

  static UAdminModule appSettings({List<TagUser>? roles}) => UAdminModule(
    title: U.s.appSettings,
    icon: Icons.tune_rounded,
    page: () => const UAdminAppSettingsPage(),
    roles: roles,
  );

  static UAdminModule settings({List<TagUser>? roles}) => UAdminModule(
    title: U.s.settings,
    icon: Icons.settings_rounded,
    page: () => const UAdminSettingsPage(),
    roles: roles,
  );

  static UAdminModule apiLogs({List<TagUser>? roles}) => UAdminModule(
    title: U.s.apiRequestLogs,
    icon: Icons.travel_explore_rounded,
    page: () => const UAdminApiLogPage(),
    roles: roles,
  );

  static UAdminModule storage({List<TagUser>? roles}) => UAdminModule(
    title: U.s.keyValue,
    icon: Icons.storage,
    page: () => const UStorageManagerPage(),
    roles: roles,
  );
}
