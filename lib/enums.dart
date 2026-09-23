import "package:u/utilities.dart";

mixin UNumericIdentifiable {
  int get number;

  String get titleFa;

  String get titleEn;

  String get localizedTitle => UApp.locale() == "fa" ? titleFa : titleEn;
}

extension NumericEnumExtension<T extends Enum> on Iterable<T> {
  List<int> get numbers => map((dynamic e) => (e as dynamic).number as int).toList();

  List<String> get titlesFa => map((dynamic e) => (e as dynamic).titleFa as String).toList();

  List<String> get titlesEn => map((dynamic e) => (e as dynamic).titleEn as String).toList();

  List<Map<String, dynamic>> toMapList() => map(
        (dynamic e) => <String, dynamic>{
      "number": (e as dynamic).number,
      "titleFa": (e as dynamic).titleFa,
      "titleEn": (e as dynamic).titleEn,
    },
  ).toList();

  T? fromNumber(int id) {
    try {
      return firstWhere((dynamic element) => (element as dynamic).number == id);
    } catch (e) {
      return null;
    }
  }

  T fromNumericIdOrThrow(int id) {
    final dynamic result = fromNumber(id);
    if (result == null) {
      throw ArgumentError.value(
        id,
        "id",
        'No ${T.toString().split('.').first} found with numericId $id',
      );
    }
    return result;
  }

  List<T> fromNumbers(Iterable<int> numbers) => numbers.map(fromNumber).whereType<T>().toList();

  /// The values of one hundred-group, e.g. `TagHotel.values.group(500)` = the hotel amenities (501, 502...).
  List<T> group(int hundred) => where((dynamic e) => (e as dynamic).number ~/ 100 == hundred ~/ 100).toList();

  List<String> titlesFromNumbers(
      Iterable<int> numbers, {
        bool localized = true,
      }) => numbers
      .map(fromNumber)
      .whereType<T>()
      .map(
        (dynamic e) => localized ? (e as dynamic).localizedTitle as String : (e as dynamic).titleEn as String,
  )
      .toList();
}

enum Usc with UNumericIdentifiable {
  success("موفقیت", "Success", 200),
  created("ایجاد شده", "Created", 201),
  deleted("حذف شده", "Deleted", 211),
  processCompleted("پردازش کامل شد", "Process Completed", 212),
  badRequest("درخواست نامعتبر", "Bad Request", 400),
  unAuthorized("احراز هویت نشده", "Unauthorized", 401),
  forbidden("دسترسی ممنوع", "Forbidden", 403),
  notFound("یافت نشد", "Not Found", 404),
  conflict("تداخل", "Conflict", 409),
  payloadTooLarge("حجم بار بیش از حد", "Payload Too Large", 413),
  tooManyRequests("تعداد درخواست‌ها بیش از حد مجاز", "Too Many Requests", 429),
  mediaTypeNotSupported("نوع رسانه پشتیبانی نمی‌شود", "Media Type Not Supported", 451),
  securityError("خطای امنیتی", "Security Error", 452),
  internalServerError("خطای داخلی سرور", "Internal Server Error", 500),
  thirdPartyError("خطای شخص ثالث", "Third Party Error", 600),
  wrongVerificationCode("کد تایید اشتباه", "Wrong Verification Code", 601),
  maximumLimitReached("حداکثر تعداد رسیده", "Maximum Limit Reached", 602),
  userNotFound("کاربر یافت نشد", "User Not Found", 603),
  expiredToken("توکن منقضی شده", "Expired Token", 604),
  shahkarException("استثنای شهکار", "Shahkar Exception", 605),
  shahkarError("خطای شهکار", "Shahkar Error", 606),
  expiredRefreshToken("نشست منقضی شده", "Expired Refresh Token", 607),
  balanceIsLow("موجودی کم است", "Balance Is Low", 701),
  inquiryNotCached("استعلام قبلی موجود نیست", "Inquiry Not Cached", 702);

  const Usc(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagOrderBy with UNumericIdentifiable {
  createdAt("تاریخ ایجاد", "Created At", 101),
  cardNumber("شماره کارت", "Card Number", 102),
  zipCode("کد پستی", "Zip Code", 103),
  order("ترتیب", "Order", 104),
  title("عنوان", "Title", 105),
  capacity("ظرفیت", "Capacity", 106),
  city("شهر", "City", 107),
  isAvailable("در دسترس", "Is Available", 108),
  startDate("تاریخ شروع", "Start Date", 109),
  endDate("تاریخ پایان", "End Date", 110),
  dueDate("تاریخ سررسید", "Due Date", 111),
  mcc("کد بازرگانی", "Mcc", 112),
  code("کد", "Code", 113),
  amount("مبلغ", "Amount", 114),
  userName("نام کاربری", "User Name", 115),
  brand("برند", "Brand", 116),
  balance("موجودی", "Balance", 117),
  durationMs("مدت", "Duration", 118),
  createdAtDescending("تاریخ ایجاد (نزولی)", "Created At Descending", 201),
  cardNumberDescending("شماره کارت (نزولی)", "Card Number Descending", 202),
  zipCodeDescending("کد پستی (نزولی)", "Zip Code Descending", 203),
  orderDescending("ترتیب (نزولی)", "Order Descending", 204),
  titleDescending("عنوان (نزولی)", "Title Descending", 205),
  capacityDescending("ظرفیت (نزولی)", "Capacity Descending", 206),
  cityDescending("شهر (نزولی)", "City Descending", 207),
  isAvailableDescending("در دسترس (نزولی)", "Is Available Descending", 208),
  startDateDescending("تاریخ شروع (نزولی)", "Start Date Descending", 209),
  endDateDescending("تاریخ پایان (نزولی)", "End Date Descending", 210),
  dueDateDescending("تاریخ سررسید (نزولی)", "Due Date Descending", 211),
  mccDescending("کد بازرگانی (نزولی)", "Mcc Descending", 212),
  codeDescending("کد (نزولی)", "Code Descending", 213),
  amountDescending("مبلغ (نزولی)", "Amount Descending", 214),
  userNameDescending("نام کاربری (نزولی)", "User Name Descending", 215),
  brandDescending("برند (نزولی)", "Brand Descending", 216),
  balanceDescending("موجودی (نزولی)", "Balance Descending", 217),
  durationMsDescending("مدت (نزولی)", "Duration Descending", 218);

  const TagOrderBy(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagSmsPanel with UNumericIdentifiable {
  nikSms("نیک اس ام اس", "Nik Sms", 101),
  ghasedak("قاصدک", "Ghasedak", 102),
  kavenegar("کاوه نگار", "Kavenegar", 103);

  const TagSmsPanel(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagUser with UNumericIdentifiable {
  male("مرد", "Male", 101),
  female("زن", "Female", 102),
  unspecified("نامشخص", "Unspecified", 103),
  superAdmin("سوپر ادمین", "Super Admin", 201),
  guest("مهمان", "Guest", 202),
  systemAdmin("سیستم ادمین", "System Admin", 203),
  systemUser("کاربر سیستمی", "System User", 204),
  sunUser("کاربر سان", "Sun User", 205),
  subAdmin("زیرمجموعه ادمین", "Sub Admin", 206),
  awaitingVerification("در انتظار تایید", "Awaiting Verification", 301),
  verified("تایید شده", "Verified", 302),
  nationalCardFrontVerified("کارت ملی جلو تایید شده", "National Card Front Verified", 401),
  nationalCardBackVerified("کارت ملی پشت تایید شده", "National Card Back Verified", 402),
  birthCertificateFirstVerified("شناسنامه صفحه اول تایید شده", "Birth Certificate First Verified", 403),
  birthCertificateSecondVerified("شناسنامه صفحه دوم تایید شده", "Birth Certificate Second Verified", 404),
  birthCertificateThirdVerified("شناسنامه صفحه سوم تایید شده", "Birth Certificate Third Verified", 405),
  birthCertificateForthVerified("شناسنامه صفحه چهارم تایید شده", "Birth Certificate Forth Verified", 406),
  birthCertificateFifthVerified("شناسنامه صفحه پنجم تایید شده", "Birth Certificate Fifth Verified", 407),
  visualAuthenticationVerified("احراز هویت تصویری تایید شده", "Visual Authentication Verified", 408),
  eSignatureVerified("امضای الکترونیکی تایید شده", "E-Signature Verified", 409),
  nationalCardFrontAwaitingVerification("کارت ملی جلو در انتظار تایید", "National Card Front Awaiting Verification", 501),
  nationalCardBackAwaitingVerification("کارت ملی پشت در انتظار تایید", "National Card Back Awaiting Verification", 502),
  birthCertificateFirstAwaitingVerification("شناسنامه صفحه اول در انتظار تایید", "Birth Certificate First Awaiting Verification", 503),
  birthCertificateSecondAwaitingVerification("شناسنامه صفحه دوم در انتظار تایید", "Birth Certificate Second Awaiting Verification", 504),
  birthCertificateThirdAwaitingVerification("شناسنامه صفحه سوم در انتظار تایید", "Birth Certificate Third Awaiting Verification", 505),
  birthCertificateForthAwaitingVerification("شناسنامه صفحه چهارم در انتظار تایید", "Birth Certificate Forth Awaiting Verification", 506),
  birthCertificateFifthAwaitingVerification("شناسنامه صفحه پنجم در انتظار تایید", "Birth Certificate Fifth Awaiting Verification", 507),
  visualAuthenticationAwaitingVerification("احراز هویت تصویری در انتظار تایید", "Visual Authentication Awaiting Verification", 508),
  eSignatureAwaitingVerification("امضای الکترونیکی در انتظار تایید", "E-Signature Awaiting Verification", 509),

  // ---- Granular admin-panel permissions (only enforced for non-full-admins, e.g. subAdmin) ----
  permissionManageHotels("مدیریت هتل‌ها", "Manage Hotels", 601),
  permissionDeleteHotels("حذف هتل‌ها", "Delete Hotels", 602),
  permissionManageDorms("مدیریت خوابگاه‌ها", "Manage Dorms", 603),
  permissionDeleteDorms("حذف خوابگاه‌ها", "Delete Dorms", 604),
  permissionManageContracts("مدیریت قراردادها", "Manage Contracts", 605),
  permissionDeleteContracts("حذف قراردادها", "Delete Contracts", 606),
  permissionManageInvoices("مدیریت فاکتورها", "Manage Invoices", 607),
  permissionDeleteInvoices("حذف فاکتورها", "Delete Invoices", 608),
  permissionPayInvoices("ثبت پرداخت فاکتور", "Pay Invoices", 609),
  permissionManageUsers("مدیریت کاربران", "Manage Users", 610),
  permissionDeleteUsers("حذف کاربران", "Delete Users", 611),
  permissionManageReservations("مدیریت رزروها", "Manage Reservations", 612),
  permissionDeleteReservations("حذف رزروها", "Delete Reservations", 613);

  const TagUser(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;

  bool isMale() => this == TagUser.male;

  /// Permission tags that a full admin can grant to a subAdmin to unlock a specific restricted action.
  static const List<TagUser> permissions = <TagUser>[
    permissionManageHotels,
    permissionDeleteHotels,
    permissionManageDorms,
    permissionDeleteDorms,
    permissionManageContracts,
    permissionDeleteContracts,
    permissionManageInvoices,
    permissionDeleteInvoices,
    permissionPayInvoices,
    permissionManageUsers,
    permissionDeleteUsers,
    permissionManageReservations,
    permissionDeleteReservations,
  ];
}

enum TagCategory with UNumericIdentifiable {
  category("دسته‌بندی", "Category", 101),
  exam("پرسشنامه", "Exam", 102),
  user("کاربران", "User", 103),
  menu("منو", "Menu", 104),
  speciality("تخصص", "Speciality", 105),
  dorm("خوابگاه", "Dorm", 106),
  room("اتاق", "Room", 107),
  bed("تخت", "Bed", 108),
  enabled("فعال", "Enabled", 201),
  disabled("غیر فعال", "Disabled", 202),
  hidden("مخفی", "Hidden", 203);

  const TagCategory(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagMedia with UNumericIdentifiable {
  image("تصویر", "Image", 101),
  profile("پروفایل", "Profile", 102),

  /// The main photo of a hotel / dorm / room (shown first).
  cover("عکس اصلی", "Cover", 201),

  /// Gallery categories of hotel and dorm photos.
  exterior("نما و محوطه", "Exterior", 301),
  interior("فضای داخلی", "Interior", 302),
  room("اتاق‌ها", "Rooms", 303),
  bathroom("سرویس بهداشتی", "Bathroom", 304),
  dining("غذاخوری", "Dining", 305),
  facility("امکانات", "Facilities", 306),
  surroundings("اطراف", "Surroundings", 307);

  const TagMedia(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagProduct with UNumericIdentifiable {
  product("محصول", "Product", 101),
  content("محتوا", "Content", 102),
  blog("وبلاگ", "Blog", 103),
  case_("کیس", "Case", 104),
  dorm("خوابگاه", "Dorm", 105),
  room("اتاق", "Room", 106),
  bed("تخت", "Bed", 107),
  new_("جدید", "New", 201),
  kindOfNew("نو", "Kind of New", 202),
  used("دست دوم", "Used", 203),
  released("منتشر شده", "Released", 301),
  expired("منقضی شده", "Expired", 302),
  inQueue("در حال بررسی", "In Queue", 303),
  deleted("حذف شده", "Deleted", 304),
  notAccepted("تایید نشده", "Not Accepted", 305),
  awaitingPayment("در انتظار پرداخت", "Awaiting Payment", 306),
  room1("اتاق ۱ تخته", "1 Bed Room", 401),
  room2("اتاق ۲ تخته", "2 Bed Room", 402),
  room3("اتاق ۳ تخته", "3 Bed Room", 403),
  room4("اتاق ۴ تخته", "4 Bed Room", 404),
  room5("اتاق ۵ تخته", "5 Bed Room", 405),
  room6("اتاق ۶ تخته", "6 Bed Room", 406),
  room7("اتاق ۷ تخته", "7 Bed Room", 407),
  room8("اتاق ۸ تخته", "8 Bed Room", 408),
  room9("اتاق ۹ تخته", "9 Bed Room", 409),
  room10("اتاق ۱۰ تخته", "10 Bed Room", 410);

  const TagProduct(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagComment with UNumericIdentifiable {
  released("منتشر شده", "Released", 101),
  inQueue("در حال بررسی", "In Queue", 102),
  rejected("رد شده", "Rejected", 103),
  private("خصوصی", "Private", 201);

  const TagComment(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagReaction with UNumericIdentifiable {
  like("پسندیدن", "Like", 101),
  dislike("نپسندیدن", "Dislike", 102);

  const TagReaction(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagFollow with UNumericIdentifiable {
  user("کاربر", "User", 101),
  product("محصول", "Product", 102),
  category("دسته‌بندی", "Category", 103),
  blog("وبلاگ", "Blog", 104);

  const TagFollow(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagContent with UNumericIdentifiable {
  aboutUs("درباره ما", "About Us", 101),
  terms("قوانین و مقررات", "Terms", 102),
  contactUs("تماس با ما", "Contact Us", 103),
  qa("سوالات متداول", "Q&A", 104),
  blog("بلاگ", "Blog", 105),
  dorms("خوابگاه‌ها", "Dorms", 106),
  hotels("هتل‌ها", "Hotels", 107),
  aboutStats("آمار درباره ما", "About Stats", 108),

  homeSlider1("اسلایدر اصلی ۱", "Home Slider 1", 201),
  homeSlider2("اسلایدر اصلی ۲", "Home Slider 2", 202),
  homeBanner1("بنر اصلی ۱", "Home Banner 1", 203),
  homeBanner2("بنر اصلی ۲", "Home Banner 2", 204),
  homeBanner3("بنر اصلی ۳", "Home Banner 3", 205),
  homeHero("هیرو صفحه اصلی", "Home Hero", 206),
  homeStats("آمار صفحه اصلی", "Home Stats", 207),
  homeMarquee("نوار متحرک صفحه اصلی", "Home Marquee", 208),
  homeReasons("چرا ما (صفحه اصلی)", "Home Reasons", 209),
  homeApp("بنر اپلیکیشن (صفحه اصلی)", "Home App", 210),

  menu1("منو ۱", "Menu 1", 401),
  menu2("منو ۲", "Menu 2", 402),
  footer1("فوتر ۱", "Footer 1", 403),
  footer2("فوتر ۲", "Footer 2", 404),

  services1("خدمات ۱", "Services 1", 501),
  services2("خدمات ۲", "Services 2", 502);

  const TagContent(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTicket with UNumericIdentifiable {
  superAdmin("سوپر ادمین", "Super Admin", 101),
  admin("ادمین", "Admin", 102);

  const TagTicket(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTxn with UNumericIdentifiable {
  creditCard("کارت اعتباری", "Credit Card", 101),
  cash("نقدی", "Cash", 102),
  pending("در انتظار", "Pending", 201),
  paid("پرداخت شده", "Paid", 202),
  failed("ناموفق", "Failed", 203),
  refunded("بازگشت داده شده", "Refunded", 204),
  chargeWallet("شارژ کیف پول", "Charge Wallet", 301),
  merchantCreationFee("هزینه ایجاد پذیرنده", "Merchant Creation Fee", 302),
  dormInvoice("پرداخت قبض خوابگاه", "Dorm Invoice", 303),
  hotelInvoice("پرداخت فاکتور هتل", "Hotel Invoice", 304),
  billPayment("پرداخت قبض", "Bill Payment", 305),
  topUp("شارژ مستقیم", "Top Up", 306),
  multiplexedSale("پرداخت تسهیمی", "Multiplexed Sale", 307);

  const TagTxn(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParking with UNumericIdentifiable {
  disabled("غیرفعال", "Disabled", 101),
  active("فعال", "Active", 102),
  test("تست", "Test", 999);

  const TagParking(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagVehicle with UNumericIdentifiable {
  motorcycle("موتورسیکلت", "Motorcycle", 101),
  car("سواری", "Car", 102),
  van("ون", "Van", 103),
  truck("کامیونت", "Truck", 104),
  bus("اتوبوس", "Bus", 105),
  pickup("وانت", "Pickup", 106),
  electric("برقی", "Electric", 107);

  const TagVehicle(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingReport with UNumericIdentifiable {
  open("باز", "Open", 101),
  closed("بسته", "Closed", 102),
  offline("آفلاین", "Offline", 103),
  test("تست", "Test", 999);

  const TagParkingReport(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingTariff with UNumericIdentifiable {
  hourly("ساعتی", "Hourly", 101),
  subscription("اشتراک", "Subscription", 102);

  const TagParkingTariff(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingSubscription with UNumericIdentifiable {
  weekly("هفتگی", "Weekly", 101),
  monthly("ماهانه", "Monthly", 102),
  quarterly("فصلی", "Quarterly", 103),
  cancelled("لغو شده", "Cancelled", 104);

  const TagParkingSubscription(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingPlateFlag with UNumericIdentifiable {
  debt("بدهی", "Debt", 101),
  banned("ممنوع", "Banned", 102),
  warning("هشدار", "Warning", 103),
  reservation("رزرو", "Reservation", 104);

  const TagParkingPlateFlag(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingStaff with UNumericIdentifiable {
  registerEntryExit("ثبت ورود و خروج", "Register entry and exit", 101),
  applyManualDiscount("اعمال تخفیف دستی", "Apply manual discount", 102),
  manageSubscriptions("ثبت و تمدید اشتراک", "Manage subscriptions", 103),
  changeTariff("تغییر تعرفه", "Change tariff", 104),
  viewFinancialReports("مشاهده گزارش‌های مالی", "View financial reports", 105),
  disabled("غیرفعال", "Disabled", 106);

  const TagParkingStaff(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingShift with UNumericIdentifiable {
  open("باز", "Open", 101),
  closed("بسته", "Closed", 102);

  const TagParkingShift(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingPayment with UNumericIdentifiable {
  card("کارت بانکی", "Bank card", 101),
  ipg("درگاه پرداخت", "Payment gateway", 102),
  cash("نقدی", "Cash", 103),
  subscription("اشتراک", "Subscription", 104),
  free("رایگان", "Free", 105);

  const TagParkingPayment(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagAddress with UNumericIdentifiable {
  verified("تایید شده", "Verified", 101);

  const TagAddress(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagWallet with UNumericIdentifiable {
  primary("اصلی", "Primary", 101);

  const TagWallet(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

// Polished fa/en titles so each tag reads as a clean transaction title in the wallet list/receipt (shown via localizedTitle).
enum TagWalletTxn with UNumericIdentifiable {
  charge("شارژ کیف پول", "Wallet Top-up", 101),
  transfer("انتقال وجه", "Money Transfer", 102),
  mobileAndNationalCodeVerification("اعتبارسنجی موبایل و کد ملی", "Mobile & National ID Match", 201),
  zipCodeToAddressDetail("استعلام کد پستی", "Postal Code to Address", 202),
  vehicleViolationsDetail("استعلام خلافی خودرو", "Vehicle Violations", 203),
  drivingLicenceStatus("استعلام وضعیت گواهینامه", "Driving Licence Status", 204),
  licencePlateDetail("استعلام سوابق پلاک", "Licence Plate History", 205),
  drivingLicenceNegativePoint("استعلام نمره منفی گواهینامه", "Licence Negative Points", 206),
  iBanToBankAccountDetail("استعلام شبا به حساب بانکی", "IBAN to Bank Account", 207),
  freewayTolls("استعلام عوارض آزادراه", "Freeway Tolls", 208),
  merchantCreationFee("هزینه ایجاد پذیرنده", "Merchant Creation Fee", 209),
  dormBedInvoice("پرداخت فاکتور خوابگاه", "Dorm Invoice", 210),
  hotelReservation("پرداخت رزرو هتل", "Hotel Reservation", 211),
  hotelReservationRefund("استرداد رزرو هتل", "Hotel Reservation Refund", 212),
  goldPurchase("خرید طلا", "Gold Purchase", 213),
  goldSale("فروش طلا", "Gold Sale", 214),
  goldPurchaseRefund("استرداد خرید طلا", "Gold Purchase Refund", 215),
  chargeSimPin("خرید شارژ پین سیم‌کارت", "SIM Charge (PIN)", 301),
  chargeSimTopup("شارژ مستقیم سیم‌کارت", "SIM Top-up", 302),
  internetSim("خرید بسته اینترنت", "Internet Package", 303);

  const TagWalletTxn(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTerminal with UNumericIdentifiable {
  notAssigned("تخصیص داده نشده", "Not Assigned", 101),
  pendingApproval("در انتظار تایید", "Pending Approval", 102),
  approved("تایید شده", "Approved", 103),
  rejected("رد شده", "Rejected", 104);

  const TagTerminal(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTerminalBrand with UNumericIdentifiable {
  atm("خودپرداز", "ATM", 101),
  wallCashless("خودپرداز غیر نقد", "Wall Cashless", 102),
  deskCashless("خودپرداز رومیزی", "Desk Cashless", 103),
  simCard("سیمکارت", "SIM CARD", 201),
  wifi("وای‌فای", "WIFI", 202);

  const TagTerminalBrand(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTerminalBroker with UNumericIdentifiable {
  test("تست", "Test", 999);

  const TagTerminalBroker(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagBankAccount with UNumericIdentifiable {
  verified("تایید شده", "Verified", 101);

  const TagBankAccount(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagIpg with UNumericIdentifiable {
  pn("پی ان", "Pn", 101);

  const TagIpg(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagInquiryHistory with UNumericIdentifiable {
  validateNationalCodeAndPhoneNumber("اعتبارسنجی کد ملی و شماره تلفن", "Validate National Code And Phone Number", 101),
  zipCodeToAddressDetail("کد پستی به آدرس", "Zip Code To Address Detail", 201),
  vehicleViolationsDetail("جزئیات تخلفات وسیله نقلیه", "Vehicle Violations Detail", 301),
  drivingLicenceDetail("جزئیات گواهینامه", "Driving Licence Detail", 302),
  licencePlateDetail("جزئیات پلاک", "Licence Plate Detail", 303),
  drivingLicenceNegativePoint("امتیاز منفی گواهینامه", "Driving Licence Negative Point", 304),
  freewayTolls("عوارض آزادراه", "Freeway Tolls", 305),
  iBanToBankAccountDetail("IBan به جزئیات حساب بانکی", "IBan To Bank Account Detail", 501),
  verified("تایید شده", "Verified", 601),
  notVerified("تایید نشده", "Not Verified", 602),
  error("خطا", "Error", 603),
  itHub("آی تی هاب", "It Hub", 701);

  const TagInquiryHistory(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagNotification with UNumericIdentifiable {
  general("عمومی", "General", 101),
  reservationCreated("ثبت رزرو", "Reservation Created", 102),
  reservationConfirmed("تایید رزرو", "Reservation Confirmed", 103),
  reservationCancelled("لغو رزرو", "Reservation Cancelled", 104),
  invoiceIssued("صدور فاکتور", "Invoice Issued", 105),
  invoiceDue("سررسید فاکتور", "Invoice Due", 106),
  invoiceOverdue("فاکتور معوق", "Invoice Overdue", 107),
  invoicePaid("پرداخت فاکتور", "Invoice Paid", 108),
  unread("خوانده نشده", "Unread", 201),
  read("خوانده شده", "Read", 202),
  test("تست", "Test", 999);

  const TagNotification(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTxnErrorCodes with UNumericIdentifiable {
  lowBalance("موجودی کم", "Low Balance", 101),
  unauthorized("غیرمجاز", "Unauthorized", 102),
  senderWalletNotFound("کیف پول فرستنده یافت نشد", "Sender Wallet Not Found", 103),
  receiverWalletNotFound("کیف پول گیرنده یافت نشد", "Receiver Wallet Not Found", 104),
  securityError("خطای امنیتی", "Security Error", 105),
  ok("تایید", "Ok", 201);

  const TagTxnErrorCodes(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagVas with UNumericIdentifiable {
  water("آب", "Water", 101),
  chargeTopup("شارژ مستقیم", "Charge Topup", 201),
  chargePin("شارژ با پین", "Charge Pin", 202),
  internetPackage("بسته اینترنت", "Internet Package", 203);

  const TagVas(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagSimOperator with UNumericIdentifiable {
  hamrahAvval("همراه اول", "Hamrah Avval", 1),
  iranCell("ایرانسل", "Iran Cell", 2),
  rigthel("رایتل", "Rigthel", 3),
  shatel("شاتل", "Shatel", 5);

  const TagSimOperator(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagMerchant with UNumericIdentifiable {
  normal("معمولی", "Normal", 101);

  const TagMerchant(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagMoadi with UNumericIdentifiable {
  pending("در انتظار تایید", "Pending", 101),
  approved("تایید شده", "Approved", 102),
  rejected("رد شده", "Rejected", 103);

  const TagMoadi(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagFieldType with UNumericIdentifiable {
  text("متن", "Text", 101),
  dropDown("لیست کشویی", "Drop Down", 102),
  file("فایل", "File", 103),
  eSignature("امضای الکترونیکی", "E-Signature", 105);

  const TagFieldType(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTextFieldType with UNumericIdentifiable {
  text("متن", "Text", 101),
  multilineText("متن چند خطی", "Multiline Text", 102),
  numberDecimal("عدد اعشاری", "Number Decimal", 201),
  phoneNumber("شماره تلفن", "Phone Number", 301),
  phoneNumberWithCountryCode("شماره تلفن با کد کشور", "Phone Number With Country Code", 302),
  date("تاریخ", "Date", 401),
  dateTime("تاریخ و زمان", "DateTime", 402),
  persianDate("تاریخ شمسی", "Persian Date", 403),
  persianDateTime("تاریخ و زمان شمسی", "Persian DateTime", 404);

  const TagTextFieldType(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagFileFieldType with UNumericIdentifiable {
  image("تصویر", "Image", 101),
  video("ویدئو", "Video", 102),
  pdf("پی دی اف", "Pdf", 103),
  text("متن", "Text", 104);

  const TagFileFieldType(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

// NOTE: TagProcessStatus has no counterpart in the C# source — left as-is.
enum TagProcessStatus with UNumericIdentifiable {
  available("موجود", "Available", 101),
  comingSoon("به زودی", "Coming Soon", 102),
  disabled("غیر فعال", "Disabled", 103),
  hidden("مخفی", "Hidden", 104);

  const TagProcessStatus(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagProcessStepStatus with UNumericIdentifiable {
  notStarted("شروع نشده", "Not Started", 101),
  current("در حال انجام", "Current", 102),
  awaitingVerification("در انتظار تایید", "Awaiting Verification", 103),
  verified("تایید شده", "Verified", 104);

  const TagProcessStepStatus(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDormBedContract with UNumericIdentifiable {
  daily("روزانه", "Daily", 101),
  weekly("هفتگی", "Weekly", 102),
  monthly("ماهانه", "Monthly", 103),
  yearly("سالانه", "Yearly", 104),
  singleInvoice("فاکتور تکی", "Single Invoice", 201);

  const TagDormBedContract(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDormBedInvoice with UNumericIdentifiable {
  deposit("ودیعه", "Deposit", 101),
  rent("اجاره", "Rent", 102),
  paid("پرداخت شده", "Paid", 201),
  paidOnline("پرداخت آنلاین", "Paid Online", 202),
  paidManual("پرداخت دستی", "Paid Manual", 203),
  notPaid("پرداخت نشده", "Not Paid", 204);

  const TagDormBedInvoice(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagBed with UNumericIdentifiable {
  test("تست", "Test", 999);

  const TagBed(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagHotel with UNumericIdentifiable {
  // Type
  hotel("هتل", "Hotel", 101),
  boutique("بوتیک‌هتل", "Boutique hotel", 102),
  resort("ریزورت", "Resort", 103),
  guesthouse("مهمان‌پذیر", "Guest house", 104),
  apartment("هتل‌آپارتمان", "Apartment hotel", 105),
  traditional("اقامتگاه سنتی", "Traditional stay", 106),
  hostel("هاستل", "Hostel", 107),
  villa("ویلا", "Villa", 108),

  // Status (the public only sees active hotels)
  featured("ویژه", "Featured", 201),
  active("فعال", "Active", 202),
  inactive("غیرفعال", "Inactive", 203),

  // Policies
  petsAllowed("پذیرش حیوان خانگی", "Pets allowed", 301),
  smokingAllowed("مجاز به استعمال دخانیات", "Smoking allowed", 302),
  childrenAllowed("پذیرش کودک", "Children welcome", 303),
  extraBedAvailable("امکان تخت اضافه", "Extra bed available", 304),
  priceIncludesTax("قیمت شامل مالیات", "Price includes tax", 305),

  // Approval
  pendingApproval("در انتظار تأیید", "Pending approval", 401),
  approved("تأیید شده", "Approved", 402),
  rejected("رد شده", "Rejected", 403),

  // Amenities
  wifi("وای‌فای رایگان", "Free Wi-Fi", 501),
  parking("پارکینگ", "Parking", 502),
  elevator("آسانسور", "Elevator", 503),
  reception24("پذیرش ۲۴ ساعته", "24-hour reception", 504),
  restaurant("رستوران", "Restaurant", 505),
  cafe("کافه", "Café", 506),
  roomService("روم‌سرویس", "Room service", 507),
  laundry("خشکشویی", "Laundry", 508),
  luggageStorage("انبار چمدان", "Luggage storage", 509),
  airportShuttle("ترانسفر فرودگاهی", "Airport transfer", 510),
  pool("استخر", "Swimming pool", 511),
  gym("باشگاه ورزشی", "Gym", 512),
  sauna("سونا و جکوزی", "Sauna & jacuzzi", 513),
  spa("اسپا و ماساژ", "Spa & massage", 514),
  garden("باغ و حیاط", "Garden & courtyard", 515),
  meetingRoom("سالن جلسات", "Meeting room", 516),
  prayerRoom("نمازخانه", "Prayer room", 517),
  playground("فضای بازی کودکان", "Kids' play area", 518),
  wheelchair("مناسب افراد دارای معلولیت", "Wheelchair accessible", 519),
  cctv("دوربین مداربسته", "CCTV", 520),

  // Meal plans
  roomOnly("فقط اتاق", "Room only", 601),
  breakfast("با صبحانه", "Breakfast included", 602),
  halfBoard("نیم‌پانسیون", "Half board", 603),
  fullBoard("پانسیون کامل", "Full board", 604),
  allInclusive("همه‌چیز شامل", "All inclusive", 605);

  const TagHotel(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagHotelReservation with UNumericIdentifiable {
  pending("در انتظار", "Pending", 101),
  confirmed("تایید شده", "Confirmed", 102),
  checkedIn("پذیرش شده", "Checked In", 103),
  checkedOut("تسویه شده", "Checked Out", 104),
  cancelled("لغو شده", "Cancelled", 201),
  noShow("عدم حضور", "No Show", 202);

  const TagHotelReservation(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagHotelInvoice with UNumericIdentifiable {
  full("کامل", "Full", 101),
  paid("پرداخت شده", "Paid", 201),
  paidOnline("پرداخت آنلاین", "Paid Online", 202),
  paidManual("پرداخت دستی", "Paid Manual", 203),
  notPaid("پرداخت نشده", "Not Paid", 204),
  refunded("مسترد شده", "Refunded", 205);

  const TagHotelInvoice(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagBlog with UNumericIdentifiable {
  draft("پیش‌نویس", "Draft", 101),
  published("منتشر شده", "Published", 102),
  archived("بایگانی شده", "Archived", 103),
  featured("ویژه", "Featured", 201),
  pinned("سنجاق شده", "Pinned", 202);

  const TagBlog(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDorm with UNumericIdentifiable {
  // Residents
  girls("دختران", "Girls", 101),
  boys("پسران", "Boys", 102),

  // Status (the public only sees active dorms)
  featured("ویژه", "Featured", 201),
  active("فعال", "Active", 202),
  inactive("غیرفعال", "Inactive", 203),

  // Accepted residents
  bachelor("دانشجوی کارشناسی", "Bachelor's students", 301),
  master("دانشجوی ارشد", "Master's students", 302),
  phd("دانشجوی دکتری", "PhD students", 303),
  staff("کارمند و هیئت علمی", "Staff & faculty", 304),

  // Approval
  pendingApproval("در انتظار تأیید", "Pending approval", 401),
  approved("تأیید شده", "Approved", 402),
  rejected("رد شده", "Rejected", 403),

  // Amenities
  wifi("وای‌فای", "Wi-Fi", 501),
  parking("پارکینگ", "Parking", 502),
  elevator("آسانسور", "Elevator", 503),
  sharedKitchen("آشپزخانه مشترک", "Shared kitchen", 504),
  selfService("سلف‌سرویس", "Self-service dining", 505),
  laundry("لباسشویی", "Laundry", 506),
  studyRoom("اتاق مطالعه", "Study room", 507),
  library("کتابخانه", "Library", 508),
  prayerRoom("نمازخانه", "Prayer room", 509),
  gym("باشگاه ورزشی", "Gym", 510),
  lounge("سالن نشیمن مشترک", "Common room", 511),
  garden("حیاط و فضای سبز", "Garden & courtyard", 512),
  lockers("کمد شخصی", "Personal lockers", 513),
  cctv("دوربین مداربسته", "CCTV", 514),
  securityGuard("نگهبان ۲۴ ساعته", "24h security", 515),
  supervisor("سرپرست مقیم", "Resident supervisor", 516),
  shuttle("سرویس رفت‌وآمد", "Shuttle service", 517),
  bikeParking("پارکینگ دوچرخه و موتور", "Bike parking", 518),

  // Meals
  breakfast("صبحانه", "Breakfast", 601),
  lunch("ناهار", "Lunch", 602),
  dinner("شام", "Dinner", 603),

  // Included in the rent
  internetIncluded("اینترنت", "Internet", 701),
  utilitiesIncluded("آب، برق و گاز", "Water, power & gas", 702),
  cleaningIncluded("نظافت", "Cleaning", 703);

  const TagDorm(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagRoom with UNumericIdentifiable {
  // Type
  single("یک تخته", "Single", 101),
  double_("دو تخته", "Double", 102),
  triple("سه تخته", "Triple", 103),
  twin("دو تخته توئین", "Twin", 104),
  suite("سوئیت", "Suite", 105),
  family("خانوادگی", "Family", 106),
  deluxe("دلوکس", "Deluxe", 107),

  // Status
  available("در دسترس", "Available", 201),
  outOfService("خارج از سرویس", "Out Of Service", 202),

  // Policies
  nonRefundable("غیرقابل استرداد", "Non-refundable", 301),
  breakfastIncluded("با صبحانه", "Breakfast included", 302),

  // View
  cityView("منظره شهر", "City view", 401),
  gardenView("منظره باغ", "Garden view", 402),
  courtyardView("رو به حیاط", "Courtyard view", 403),
  seaView("منظره دریا", "Sea view", 404),
  mountainView("منظره کوه", "Mountain view", 405),
  poolView("رو به استخر", "Pool view", 406),

  // Amenities
  privateBathroom("سرویس بهداشتی اختصاصی", "Private bathroom", 501),
  bathtub("وان", "Bathtub", 502),
  airConditioning("تهویه مطبوع", "Air conditioning", 503),
  heating("گرمایش", "Heating", 504),
  tv("تلویزیون", "TV", 505),
  minibar("مینی‌بار", "Minibar", 506),
  fridge("یخچال", "Refrigerator", 507),
  kettle("کتری برقی و چای‌ساز", "Kettle & tea set", 508),
  safeBox("صندوق امانات", "In-room safe", 509),
  desk("میز کار", "Work desk", 510),
  balcony("بالکن", "Balcony", 511),
  hairDryer("سشوار", "Hair dryer", 512),
  kitchenette("آشپزخانه اختصاصی", "Kitchenette", 513),
  wardrobe("کمد لباس", "Wardrobe", 514);

  const TagRoom(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDormRoom with UNumericIdentifiable {
  // Type
  single("تک نفره", "Single", 101),
  double_("دو نفره", "Double", 102),
  dorm("خوابگاهی", "Dorm", 103),

  // Features
  furnished("مبله", "Furnished", 301),

  // Amenities
  privateBathroom("سرویس بهداشتی اختصاصی", "Private bathroom", 501),
  airConditioning("تهویه مطبوع", "Air conditioning", 502),
  heating("گرمایش", "Heating", 503),
  fridge("یخچال", "Refrigerator", 504),
  tv("تلویزیون", "TV", 505),
  balcony("بالکن", "Balcony", 506),
  wardrobe("کمد لباس", "Wardrobe", 507),
  desk("میز مطالعه", "Desk", 508);

  const TagDormRoom(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDormBed with UNumericIdentifiable {
  // Type
  single("تک نفره", "Single", 101),
  double_("دو نفره", "Double", 102),

  // Bunk level
  bunkBottom("تخت پایین", "Bottom bunk", 201),
  bunkTop("تخت بالا", "Top bunk", 202),

  // Amenities
  desk("میز مطالعه", "Desk", 501),
  locker("قفسه شخصی", "Locker", 502),
  readingLamp("چراغ مطالعه", "Reading lamp", 503),
  privacyCurtain("پرده حریم", "Privacy curtain", 504),
  powerOutlet("پریز برق", "Power outlet", 505),
  shelf("طبقه", "Shelf", 506);

  const TagDormBed(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagApiLog with UNumericIdentifiable {
  get_("GET", "GET", 101),
  post("POST", "POST", 102),
  put("PUT", "PUT", 103),
  patch("PATCH", "PATCH", 104),
  delete("DELETE", "DELETE", 105),
  other("سایر", "Other", 106),
  success("موفق", "Success", 201),
  clientError("خطای کلاینت", "Client Error", 202),
  serverError("خطای سرور", "Server Error", 203),
  hasException("دارای استثنا", "Has Exception", 301);

  const TagApiLog(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagGoldAsset with UNumericIdentifiable {
  gold18("طلای ۱۸ عیار", "Gold 18K", 101),
  irr("ریال", "Rial", 102);

  const TagGoldAsset(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagGoldOrderSide with UNumericIdentifiable {
  buy("خرید", "Buy", 101),
  sell("فروش", "Sell", 102);

  const TagGoldOrderSide(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagGoldOrderStatus with UNumericIdentifiable {
  filled("انجام‌شده", "Filled", 101),
  pending("در انتظار", "Pending", 102),
  failed("ناموفق", "Failed", 103),
  cancelled("لغوشده", "Cancelled", 104);

  const TagGoldOrderStatus(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagGoldTxn with UNumericIdentifiable {
  buy("خرید طلا", "Buy Gold", 101),
  sell("فروش طلا", "Sell Gold", 102),
  pending("در انتظار", "Pending", 201),
  filled("انجام‌شده", "Filled", 202),
  failed("ناموفق", "Failed", 203),
  cancelled("لغوشده", "Cancelled", 204);

  const TagGoldTxn(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagIpgPayment with UNumericIdentifiable {
  normalSale("خرید عادی", "Normal Sale", 101),
  bill("پرداخت قبض", "Bill", 102),
  topUp("شارژ مستقیم", "Top Up", 103),
  multiplexedSale("پرداخت تسهیمی", "Multiplexed Sale", 104);

  const TagIpgPayment(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}
