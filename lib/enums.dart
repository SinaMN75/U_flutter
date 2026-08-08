import "package:u/utilities.dart";

enum Usc with NumericIdentifiable {
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

enum TagOrderBy with NumericIdentifiable {
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

enum TagSmsPanel with NumericIdentifiable {
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

enum TagUser with NumericIdentifiable {
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

enum TagCategory with NumericIdentifiable {
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

enum TagMedia with NumericIdentifiable {
  image("تصویر", "Image", 101),
  profile("پروفایل", "Profile", 102);

  const TagMedia(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagProduct with NumericIdentifiable {
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

enum TagComment with NumericIdentifiable {
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

enum TagReaction with NumericIdentifiable {
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

enum TagFollow with NumericIdentifiable {
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

enum TagContent with NumericIdentifiable {
  aboutUs("درباره ما", "About Us", 101),
  terms("قوانین و مقررات", "Terms", 102),
  contactUs("تماس با ما", "Contact Us", 103),
  homeSlider1("اسلایدر اصلی ۱", "Home Slider 1", 201),
  homeSlider2("اسلایدر اصلی ۲", "Home Slider 2", 202),
  aboutSection("بخش درباره ما", "About Section", 301),
  servicesCarousel("اسلایدر خدمات", "Services Carousel", 302),
  heroBanner("بنر اصلی", "Hero Banner", 303),
  footer("فوتر", "Footer", 304),
  latestBlogPosts("آخرین مطالب بلاگ", "Latest Blog Posts", 305);

  const TagContent(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTicket with NumericIdentifiable {
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

enum TagTxn with NumericIdentifiable {
  creditCard("کارت اعتباری", "Credit Card", 101),
  cash("نقدی", "Cash", 102),
  pending("در انتظار", "Pending", 201),
  paid("پرداخت شده", "Paid", 202),
  failed("ناموفق", "Failed", 203),
  refunded("بازگشت داده شده", "Refunded", 204),
  chargeWallet("شارژ کیف پول", "Charge Wallet", 301),
  merchantCreationFee("هزینه ایجاد پذیرنده", "Merchant Creation Fee", 302),
  dormInvoice("پرداخت قبض خوابگاه", "Dorm Invoice", 303);

  const TagTxn(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParking with NumericIdentifiable {
  test("تست", "Test", 999);

  const TagParking(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagVehicle with NumericIdentifiable {
  motorcycle("موتورسیکلت", "Motorcycle", 101),
  car("سواری", "Car", 102),
  van("ون", "Van", 103),
  truck("کامیون", "Truck", 104),
  bus("اتوبوس", "Bus", 105);

  const TagVehicle(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagParkingReport with NumericIdentifiable {
  test("تست", "Test", 999);

  const TagParkingReport(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagAddress with NumericIdentifiable {
  verified("تایید شده", "Verified", 101);

  const TagAddress(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagWallet with NumericIdentifiable {
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
enum TagWalletTxn with NumericIdentifiable {
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

enum TagTerminal with NumericIdentifiable {
  atm("خودپرداز", "ATM", 101),
  wallCashless("پرداخت بدون پول نقد دیواری", "Wall Cashless", 102),
  deskCashless("پرداخت بدون پول نقد میز", "Desk Cashless", 103);

  const TagTerminal(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagBankAccount with NumericIdentifiable {
  verified("تایید شده", "Verified", 101);

  const TagBankAccount(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagIpg with NumericIdentifiable {
  pn("پی ان", "Pn", 101);

  const TagIpg(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagMpg with NumericIdentifiable {
  pn("پی ان", "Pn", 101);

  const TagMpg(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagPayment with NumericIdentifiable {
  chargeWallet("شارژ کیف پول", "Charge Wallet", 101);

  const TagPayment(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagInquiryHistory with NumericIdentifiable {
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

enum TagNotification with NumericIdentifiable {
  test("تست", "Test", 999);

  const TagNotification(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagTxnErrorCodes with NumericIdentifiable {
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

enum TagVas with NumericIdentifiable {
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

enum TagSimOperator with NumericIdentifiable {
  iranCell("ایرانسل", "Iran Cell", 1),
  hamrahAvval("همراه اول", "Hamrah Avval", 2),
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

enum TagMerchant with NumericIdentifiable {
  normal("معمولی", "Normal", 101);

  const TagMerchant(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagMoadi with NumericIdentifiable {
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

enum TagFieldType with NumericIdentifiable {
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

enum TagTextFieldType with NumericIdentifiable {
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

enum TagFileFieldType with NumericIdentifiable {
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
enum TagProcessStatus with NumericIdentifiable {
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

enum TagProcessStepStatus with NumericIdentifiable {
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

enum TagDormBedContract with NumericIdentifiable {
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

enum TagDormBedInvoice with NumericIdentifiable {
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

enum TagBed with NumericIdentifiable {
  test("تست", "Test", 999);

  const TagBed(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagHotel with NumericIdentifiable {
  hotel("هتل", "Hotel", 101),
  featured("ویژه", "Featured", 201),
  active("فعال", "Active", 202),
  inactive("غیرفعال", "Inactive", 203);

  const TagHotel(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagHotelReservation with NumericIdentifiable {
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

enum TagHotelInvoice with NumericIdentifiable {
  full("کامل", "Full", 101),
  paid("پرداخت شده", "Paid", 201),
  paidOnline("پرداخت آنلاین", "Paid Online", 202),
  paidManual("پرداخت دستی", "Paid Manual", 203),
  notPaid("پرداخت نشده", "Not Paid", 204);

  const TagHotelInvoice(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagBlog with NumericIdentifiable {
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

enum TagDorm with NumericIdentifiable {
  girls("دختران", "Girls", 101),
  boys("پسران", "Boys", 102);

  const TagDorm(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagRoom with NumericIdentifiable {
  single("یک تخته", "Single", 101),
  double_("دو تخته", "Double", 102),
  triple("سه تخته", "Triple", 103),
  twin("دو تخته توئین", "Twin", 104),
  suite("سوئیت", "Suite", 105),
  family("خانوادگی", "Family", 106),
  deluxe("دلوکس", "Deluxe", 107),
  available("در دسترس", "Available", 201),
  outOfService("خارج از سرویس", "Out Of Service", 202);

  const TagRoom(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDormRoom with NumericIdentifiable {
  single("تک نفره", "Single", 101),
  double_("دو نفره", "Double", 102),
  dorm("خوابگاهی", "Dorm", 103);

  const TagDormRoom(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagDormBed with NumericIdentifiable {
  single("تک نفره", "Single", 101),
  double_("دو نفره", "Double", 102);

  const TagDormBed(this.titleFa, this.titleEn, this.number);

  @override
  final String titleFa;
  @override
  final String titleEn;
  @override
  final int number;
}

enum TagApiLog with NumericIdentifiable {
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

mixin NumericIdentifiable {
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

  T? fromNumber(final int id) {
    try {
      return firstWhere((final dynamic element) => (element as dynamic).number == id);
    } catch (e) {
      return null;
    }
  }

  T fromNumericIdOrThrow(final int id) {
    final dynamic result = fromNumber(id);
    if (result == null) {
      throw ArgumentError.value(id, "id", 'No ${T.toString().split('.').first} found with numericId $id');
    }
    return result;
  }
}
