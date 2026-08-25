import "package:u/utilities.dart";

part "params/accounting_params.dart";

part "params/address_params.dart";

part "params/api_log_params.dart";

part "params/app_settings_params.dart";

part "params/auth_params.dart";

part "params/bank_account_params.dart";

part "params/base_params.dart";

part "params/blog_params.dart";

part "params/category_params.dart";

part "params/charge_internet_params.dart";

part "params/comment_params.dart";

part "params/content_params.dart";

part "params/dashboard_analytics_params.dart";

part "params/db_admin_params.dart";

part "params/file_manager_params.dart";

part "params/follow_params.dart";

part "params/hotel_params.dart";

part "params/inquiry_params.dart";

part "params/ipg_params.dart";

part "params/media_params.dart";

part "params/merchant_params.dart";

part "params/moadi_params.dart";

part "params/notification_params.dart";

part "params/parking_params.dart";

part "params/product_params.dart";

part "params/selectors.dart";

part "params/sim_params.dart";

part "params/terminal_params.dart";

part "params/ticket_params.dart";

part "params/txn_params.dart";

part "params/user_params.dart";

part "params/vehicle_params.dart";

part "params/wallet_params.dart";

part "responses/accounting_response.dart";

part "responses/address_response.dart";

part "responses/api_log_response.dart";

part "responses/app_settings_full_response.dart";

part "responses/app_settings_response.dart";

part "responses/auth_response.dart";

part "responses/bank_account_response.dart";

part "responses/base_response.dart";

part "responses/blog_response.dart";

part "responses/category_response.dart";

part "responses/charge_internet_response.dart";

part "responses/comment_response.dart";

part "responses/content_response.dart";

part "responses/dashboard_analytics_response.dart";

part "responses/dashboard_response.dart";

part "responses/db_admin_response.dart";

part "responses/file_manager_response.dart";

part "responses/follower_following_count_response.dart";

part "responses/hotel_response.dart";

part "responses/inquiry_response.dart";

part "responses/ipg_response.dart";

part "responses/media_response.dart";

part "responses/merchant_response.dart";

part "responses/moadi_response.dart";

part "responses/notification_response.dart";

part "responses/os_metrics_response.dart";

part "responses/parking_response.dart";

part "responses/process_response.dart";

part "responses/product_response.dart";

part "responses/sim_response.dart";

part "responses/terminal_response.dart";

part "responses/ticket_response.dart";

part "responses/txn_response.dart";

part "responses/user_flow.dart";

part "responses/user_response.dart";

part "responses/vehicle_response.dart";

part "responses/wallet_response.dart";

part "services/accounting_service.dart";

part "services/address_service.dart";

part "services/app_settings_service.dart";

part "services/auth_service.dart";

part "services/bank_account_service.dart";

part "services/blog_service.dart";

part "services/category_service.dart";

part "services/charge_internet_service.dart";

part "services/comment_service.dart";

part "services/content_service.dart";

part "services/dashboard_service.dart";

part "services/db_admin_service.dart";

part "services/file_manager_service.dart";

part "services/follow_service.dart";

part "services/hotel_service.dart";

part "services/inquiry_service.dart";

part "services/ipg_service.dart";

part "services/media_service.dart";

part "services/merchant_service.dart";

part "services/moadi_service.dart";

part "services/notification_service.dart";

part "services/parking_service.dart";

part "services/pn_service.dart";

part "services/process_service.dart";

part "services/product_service.dart";

part "services/sim_service.dart";

part "services/terminal_service.dart";

part "services/ticket_service.dart";

part "services/txn_service.dart";

part "services/user_service.dart";

part "services/vehicle_service.dart";

part "services/wallet_service.dart";

part "payment/ipg_flow.dart";

part "payment/ipg_web_view_controller.dart";

part "payment/ipg_web_view_page.dart";

part "payment/payment_flow.dart";

class UServices {
  static AuthService auth = AuthService();
  static AccountingService accounting = AccountingService();
  static AppSettingsService appSettings = AppSettingsService();
  static CategoryService category = CategoryService();
  static DashboardService dashboard = DashboardService();
  static UserService user = UserService();
  static ProductService product = ProductService();
  static ContentService content = ContentService();
  static CommentService comment = CommentService();
  static FollowService follow = FollowService();
  static MediaService media = MediaService();
  static WalletService wallet = WalletService();
  static IpgService ipg = IpgService();
  static AddressService address = AddressService();
  static InquiryService inquiry = InquiryService();
  static VehicleService vehicle = VehicleService();
  static TerminalService terminal = TerminalService();
  static BankAccountService bankAccount = BankAccountService();
  static NotificationService notification = NotificationService();
  static ChargeInternetService chargeInternet = ChargeInternetService();
  static MerchantService merchant = MerchantService();
  static MoadiService moadi = MoadiService();
  static ProcessService process = ProcessService();
  static SimService sim = SimService();
  static HotelService hotel = HotelService();
  static TicketService ticket = TicketService();
  static ParkingService parking = ParkingService();
  static TxnService txn = TxnService();
  static BlogService blog = BlogService();
  static PnService pn = PnService();
  static FileManagerService fileManager = FileManagerService();
  static DbAdminService dbAdmin = DbAdminService();
}
