import "package:u/utilities.dart";

abstract class UAdminPageSwitcher {
  static void financialOpsDashboard() => U.addOrSwitchTab(U.s.financialOperations, const UAdminFinancialOpsDashboardPage());

  static void propertyDashboard() => U.addOrSwitchTab(U.s.propertyDashboard, const UAdminHotelDashboardPage());

  static void contents() => U.addOrSwitchTab(U.s.content, const UAdminContentsPage());

  static void blogs() => U.addOrSwitchTab(U.s.blogs, const UAdminBlogPage());

  static void parking() => U.addOrSwitchTab(U.s.parkingManagement, const UAdminParkingPage());

  static void parkingReport({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.parkingReports : "${U.s.parkingReports} · ${parking.title}",
    UAdminParkingReportPage(parking: parking),
  );

  static void parkingTariff({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.tariffs : "${U.s.tariffs} · ${parking.title}",
    UAdminParkingTariffPage(parking: parking),
  );

  static void parkingSubscription({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.subscriptions : "${U.s.subscriptions} · ${parking.title}",
    UAdminParkingSubscriptionPage(parking: parking),
  );

  static void parkingStaff({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.staffManagement : "${U.s.staff} · ${parking.title}",
    UAdminParkingStaffPage(parking: parking),
  );

  static void parkingPlateFlag({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.specialPlates : "${U.s.specialPlates} · ${parking.title}",
    UAdminParkingPlateFlagPage(parking: parking),
  );

  static void parkingShift({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.shift : "${U.s.shift} · ${parking.title}",
    UAdminParkingShiftPage(parking: parking),
  );

  static void users({required UAdminUsersPageArgs args}) => U.addOrSwitchTab(U.s.users, UAdminUserPage(args: args));

  static void hotelUserDetail({required UUserResponse user}) =>
      U.addOrSwitchTab("${user.firstName ?? ""} ${user.lastName ?? ""}".trim().nullIfEmpty() ?? user.userName, UAdminHotelUserDetailPage(user: user));

  static void adminUsers() => U.addOrSwitchTab(U.s.usersManagement, const UAdminUsersPage());

  static void adminUserDetail({required UUserResponse user}) => U.addOrSwitchTab(
    "${user.firstName ?? ""} ${user.lastName ?? ""}".trim().nullIfEmpty() ?? user.userName,
    UAdminUserDetailPage(user: user),
  );

  static void merchants({UUserResponse? user}) => U.addOrSwitchTab(
    user == null ? U.s.merchantsManagement : "${U.s.merchants} · ${user.displayName}",
    UAdminMerchantsPage(user: user),
  );

  static void terminals({UMerchantResponse? merchant}) => U.addOrSwitchTab(
    merchant == null ? U.s.terminalsManagement : "${U.s.terminals} · ${merchant.title}",
    UAdminTerminalsPage(merchant: merchant),
  );

  static void hotels() => U.addOrSwitchTab(U.s.hotels, const UAdminHotelPage());

  static void hotelRooms({UHotelResponse? hotel}) => U.addOrSwitchTab(hotel == null ? U.s.hotelRooms : "${U.s.rooms} · ${hotel.title}", UAdminHotelRoomPage(hotel: hotel));

  static void reservations({UHotelResponse? hotel, UHotelRoomResponse? room}) => U.addOrSwitchTab(
    room != null
        ? "${U.s.reservations} · ${room.title}"
        : hotel != null
        ? "${U.s.reservations} · ${hotel.title}"
        : U.s.reservations,
    UAdminReservationPage(hotel: hotel, room: room),
  );

  static void dormList() => U.addOrSwitchTab(U.s.dorms, const UAdminDormPage());

  static void dormRooms({UDormResponse? dorm}) => U.addOrSwitchTab(dorm == null ? U.s.dormRooms : "${U.s.rooms} · ${dorm.title}", UAdminDormRoomPage(dorm: dorm));

  static void dormBeds({UDormRoomResponse? room, UDormResponse? dorm}) => U.addOrSwitchTab(
    room != null
        ? "${U.s.beds} · ${room.title}"
        : dorm != null
        ? "${U.s.beds} · ${dorm.title}"
        : U.s.dormBeds,
    UAdminDormBedPage(room: room, dorm: dorm),
  );

  static void contracts({UDormBedResponse? bed, UUserResponse? user}) => U.addOrSwitchTab(
    bed != null
        ? "${U.s.contracts} · ${bed.title}"
        : user != null
        ? "${U.s.contracts} · ${user.displayName}"
        : U.s.contracts,
    UAdminContractPage(bed: bed, user: user),
  );

  static void invoices({UDormBedContractResponse? contract}) => U.addOrSwitchTab(
    contract == null ? U.s.invoices : "${U.s.invoices} · ${contract.user?.displayName ?? ""}",
    UAdminInvoicePage(contract: contract),
  );

  static void wallet() => U.addOrSwitchTab(U.s.walletManagement, const UAdminWalletPage());

  static void transactions() => U.addOrSwitchTab(U.s.transactions, const UAdminTransactionsPage());

  static void accounting() => U.addOrSwitchTab(U.s.accounting, const UAdminAccountingPage());

  static void settings() => U.addOrSwitchTab(U.s.settings, const UAdminSettingsPage());

  static void apiLogs() => U.addOrSwitchTab(U.s.apiRequestLogs, const UAdminApiLogPage());

  static Future<void> userCreateUpdate({UUserResponse? user}) => UAdminUserCreateUpdateDialog.show(user: user);

  static Future<void> paymentUserCreateUpdate({UUserResponse? user}) => UAdminPaymentUserCreateUpdateDialog.show(user: user);
}
