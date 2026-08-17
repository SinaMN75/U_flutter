import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('fa')];

  /// No description provided for @accenting.
  ///
  /// In en, this message translates to:
  /// **'Accenting'**
  String get accenting;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get accounting;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activeContract.
  ///
  /// In en, this message translates to:
  /// **'Active Contract'**
  String get activeContract;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add {item}'**
  String addItem(Object item);

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminMessage.
  ///
  /// In en, this message translates to:
  /// **'Admin message'**
  String get adminMessage;

  /// No description provided for @adminOtp.
  ///
  /// In en, this message translates to:
  /// **'Admin OTP'**
  String get adminOtp;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @agreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get agreement;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Center'**
  String get alignCenter;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align Left'**
  String get alignLeft;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Align Right'**
  String get alignRight;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @apiRequestLogs.
  ///
  /// In en, this message translates to:
  /// **'API Request Logs'**
  String get apiRequestLogs;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @architecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get architecture;

  /// No description provided for @areYouSureToDeleteThisUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to Delete this User?'**
  String get areYouSureToDeleteThisUser;

  /// No description provided for @areYouSureYouWantToApproveAndRegisterThisTaxpayerInTheNamatSystem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve and register this taxpayer in the Namat system?'**
  String get areYouSureYouWantToApproveAndRegisterThisTaxpayerInTheNamatSystem;

  /// No description provided for @areYouSureYouWantToApproveThisUserWithAllOfTheirDocuments.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this user with all of their documents?'**
  String get areYouSureYouWantToApproveThisUserWithAllOfTheirDocuments;

  /// No description provided for @areYouSureYouWantToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure You Want To Delete'**
  String get areYouSureYouWantToDelete;

  /// No description provided for @areYouSureYouWantToDeleteAllStoredDataThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all stored data? This action cannot be undone.'**
  String get areYouSureYouWantToDeleteAllStoredDataThisActionCannotBeUndone;

  /// No description provided for @areYouSureYouWantToDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this {item}?'**
  String areYouSureYouWantToDeleteItem(Object item);

  /// No description provided for @areYouSureYouWantToDeleteThisEntryThisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry? This action cannot be undone.'**
  String get areYouSureYouWantToDeleteThisEntryThisActionCannotBeUndone;

  /// No description provided for @areYouSureYouWantToLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureYouWantToLogOut;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @atLeast.
  ///
  /// In en, this message translates to:
  /// **'At least'**
  String get atLeast;

  /// No description provided for @atMost.
  ///
  /// In en, this message translates to:
  /// **'At most'**
  String get atMost;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @averageDuration.
  ///
  /// In en, this message translates to:
  /// **'Average Duration'**
  String get averageDuration;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @bankAccountid.
  ///
  /// In en, this message translates to:
  /// **'Bank Account ID'**
  String get bankAccountid;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @barcodeqrGenerator.
  ///
  /// In en, this message translates to:
  /// **'Barcode / QR generator'**
  String get barcodeqrGenerator;

  /// No description provided for @barcodeType.
  ///
  /// In en, this message translates to:
  /// **'Barcode type'**
  String get barcodeType;

  /// No description provided for @bed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get bed;

  /// No description provided for @beds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get beds;

  /// No description provided for @bedType.
  ///
  /// In en, this message translates to:
  /// **'Bed Type'**
  String get bedType;

  /// No description provided for @billId.
  ///
  /// In en, this message translates to:
  /// **'Bill ID'**
  String get billId;

  /// No description provided for @binaryFiles.
  ///
  /// In en, this message translates to:
  /// **'Binary files'**
  String get binaryFiles;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @birthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Birth Certificate'**
  String get birthCertificate;

  /// No description provided for @birthdate.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate;

  /// No description provided for @blog.
  ///
  /// In en, this message translates to:
  /// **'Blog'**
  String get blog;

  /// No description provided for @blogs.
  ///
  /// In en, this message translates to:
  /// **'Blogs'**
  String get blogs;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @bulkImportTerminals.
  ///
  /// In en, this message translates to:
  /// **'Bulk Import Terminals'**
  String get bulkImportTerminals;

  /// No description provided for @bulletedList.
  ///
  /// In en, this message translates to:
  /// **'Bulleted List'**
  String get bulletedList;

  /// No description provided for @businessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Title'**
  String get businessTitle;

  /// No description provided for @buttonLink.
  ///
  /// In en, this message translates to:
  /// **'Button Link'**
  String get buttonLink;

  /// No description provided for @buttonText.
  ///
  /// In en, this message translates to:
  /// **'Button Text'**
  String get buttonText;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache Cleared'**
  String get cacheCleared;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @changesApplyLiveAndResetToDefaultsOnServerRestart.
  ///
  /// In en, this message translates to:
  /// **'Changes apply live and reset to defaults on server restart.'**
  String get changesApplyLiveAndResetToDefaultsOnServerRestart;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get characters;

  /// No description provided for @charge.
  ///
  /// In en, this message translates to:
  /// **'Charge'**
  String get charge;

  /// No description provided for @chargeWallet.
  ///
  /// In en, this message translates to:
  /// **'Charge Wallet'**
  String get chargeWallet;

  /// No description provided for @checkedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get checkedIn;

  /// No description provided for @checkedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked Out'**
  String get checkedOut;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkInDate.
  ///
  /// In en, this message translates to:
  /// **'Check-in Date'**
  String get checkInDate;

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in Time'**
  String get checkInTime;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @checkOutDate.
  ///
  /// In en, this message translates to:
  /// **'Check-out Date'**
  String get checkOutDate;

  /// No description provided for @checkOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-out Time'**
  String get checkOutTime;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityCode.
  ///
  /// In en, this message translates to:
  /// **'City Code'**
  String get cityCode;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @clearFormatting.
  ///
  /// In en, this message translates to:
  /// **'Clear Formatting'**
  String get clearFormatting;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @codeBlock.
  ///
  /// In en, this message translates to:
  /// **'Code Block'**
  String get codeBlock;

  /// No description provided for @codeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Code Language'**
  String get codeLanguage;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @connectionToNetworkWasNotPossible.
  ///
  /// In en, this message translates to:
  /// **'Connection to Network was Not possible'**
  String get connectionToNetworkWasNotPossible;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get contents;

  /// No description provided for @contentType.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get contentType;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @contractsExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Contracts Expiring Soon'**
  String get contractsExpiringSoon;

  /// No description provided for @contractType.
  ///
  /// In en, this message translates to:
  /// **'Contract Type'**
  String get contractType;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @cores.
  ///
  /// In en, this message translates to:
  /// **'cores'**
  String get cores;

  /// No description provided for @cornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get cornerRadius;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @cpuUsage.
  ///
  /// In en, this message translates to:
  /// **'CPU Usage'**
  String get cpuUsage;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get createdDate;

  /// No description provided for @createItem.
  ///
  /// In en, this message translates to:
  /// **'Create {item}'**
  String createItem(Object item);

  /// No description provided for @creatorId.
  ///
  /// In en, this message translates to:
  /// **'Creator ID'**
  String get creatorId;

  /// No description provided for @creditor.
  ///
  /// In en, this message translates to:
  /// **'Creditor'**
  String get creditor;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @cryptoTester.
  ///
  /// In en, this message translates to:
  /// **'Crypto Tester'**
  String get cryptoTester;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dailyInOut.
  ///
  /// In en, this message translates to:
  /// **'Daily In / Out'**
  String get dailyInOut;

  /// No description provided for @dailyPenalty.
  ///
  /// In en, this message translates to:
  /// **'Daily Penalty %'**
  String get dailyPenalty;

  /// No description provided for @dailyPrice.
  ///
  /// In en, this message translates to:
  /// **'Daily Price'**
  String get dailyPrice;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @databaseConsole.
  ///
  /// In en, this message translates to:
  /// **'Database Console'**
  String get databaseConsole;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'Days Overdue'**
  String get daysOverdue;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @debtAmount.
  ///
  /// In en, this message translates to:
  /// **'Debt Amount'**
  String get debtAmount;

  /// No description provided for @decode.
  ///
  /// In en, this message translates to:
  /// **'Decode'**
  String get decode;

  /// No description provided for @decreaseIndent.
  ///
  /// In en, this message translates to:
  /// **'Decrease Indent'**
  String get decreaseIndent;

  /// No description provided for @decrypt.
  ///
  /// In en, this message translates to:
  /// **'Decrypt'**
  String get decrypt;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete {item}'**
  String deleteItem(Object item);

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @detail1.
  ///
  /// In en, this message translates to:
  /// **'Detail 1'**
  String get detail1;

  /// No description provided for @detail2.
  ///
  /// In en, this message translates to:
  /// **'Detail 2'**
  String get detail2;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @diskUsage.
  ///
  /// In en, this message translates to:
  /// **'Disk Usage'**
  String get diskUsage;

  /// No description provided for @divider.
  ///
  /// In en, this message translates to:
  /// **'Divider'**
  String get divider;

  /// No description provided for @documentInfo.
  ///
  /// In en, this message translates to:
  /// **'Document Info'**
  String get documentInfo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @dorm.
  ///
  /// In en, this message translates to:
  /// **'Dorm'**
  String get dorm;

  /// No description provided for @dormAvailable.
  ///
  /// In en, this message translates to:
  /// **'Dorm Available'**
  String get dormAvailable;

  /// No description provided for @dormBeds.
  ///
  /// In en, this message translates to:
  /// **'Dorm Beds'**
  String get dormBeds;

  /// No description provided for @dormOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Dorm Occupancy'**
  String get dormOccupancy;

  /// No description provided for @dormOccupied.
  ///
  /// In en, this message translates to:
  /// **'Dorm Occupied'**
  String get dormOccupied;

  /// No description provided for @dormRooms.
  ///
  /// In en, this message translates to:
  /// **'Dorm Rooms'**
  String get dormRooms;

  /// No description provided for @dorms.
  ///
  /// In en, this message translates to:
  /// **'Dorms'**
  String get dorms;

  /// No description provided for @dormsByCity.
  ///
  /// In en, this message translates to:
  /// **'Dorms by City'**
  String get dormsByCity;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloadData.
  ///
  /// In en, this message translates to:
  /// **'Download Data'**
  String get downloadData;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @duplicateBlock.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Block'**
  String get duplicateBlock;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @economicCode.
  ///
  /// In en, this message translates to:
  /// **'Economic Code'**
  String get economicCode;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit {item}'**
  String editItem(Object item);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @encode.
  ///
  /// In en, this message translates to:
  /// **'Encode'**
  String get encode;

  /// No description provided for @encrypt.
  ///
  /// In en, this message translates to:
  /// **'Encrypt'**
  String get encrypt;

  /// No description provided for @encryptDecryptEncodeAndHashTextLocallyNoServerCalls.
  ///
  /// In en, this message translates to:
  /// **'Encrypt, decrypt, encode and hash text locally — no server calls.'**
  String get encryptDecryptEncodeAndHashTextLocallyNoServerCalls;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @ends.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get ends;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @entityOverview.
  ///
  /// In en, this message translates to:
  /// **'Entity Overview'**
  String get entityOverview;

  /// No description provided for @entrancePrice.
  ///
  /// In en, this message translates to:
  /// **'Entrance Price'**
  String get entrancePrice;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorCorrection.
  ///
  /// In en, this message translates to:
  /// **'Error correction'**
  String get errorCorrection;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error loading video'**
  String get errorLoadingVideo;

  /// No description provided for @errorReadingData.
  ///
  /// In en, this message translates to:
  /// **'Error reading Data'**
  String get errorReadingData;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @errorSubmittingForm.
  ///
  /// In en, this message translates to:
  /// **'Error Submitting Form'**
  String get errorSubmittingForm;

  /// No description provided for @exactStatusCode.
  ///
  /// In en, this message translates to:
  /// **'Exact Status Code'**
  String get exactStatusCode;

  /// No description provided for @exception.
  ///
  /// In en, this message translates to:
  /// **'Exception'**
  String get exception;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @fatherName.
  ///
  /// In en, this message translates to:
  /// **'Father Name'**
  String get fatherName;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @fileManager.
  ///
  /// In en, this message translates to:
  /// **'File Manager'**
  String get fileManager;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterItem.
  ///
  /// In en, this message translates to:
  /// **'Filter {item}'**
  String filterItem(Object item);

  /// No description provided for @finalApproval.
  ///
  /// In en, this message translates to:
  /// **'Final Approval'**
  String get finalApproval;

  /// No description provided for @financialAndOperations.
  ///
  /// In en, this message translates to:
  /// **'Financial & Operations'**
  String get financialAndOperations;

  /// No description provided for @find.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get find;

  /// No description provided for @findAndReplace.
  ///
  /// In en, this message translates to:
  /// **'Find and Replace'**
  String get findAndReplace;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Flashlight'**
  String get flashlight;

  /// No description provided for @flipHorizontal.
  ///
  /// In en, this message translates to:
  /// **'Flip horizontal'**
  String get flipHorizontal;

  /// No description provided for @flipVertical.
  ///
  /// In en, this message translates to:
  /// **'Flip vertical'**
  String get flipVertical;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder Name'**
  String get folderName;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow us'**
  String get followUs;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @foreground.
  ///
  /// In en, this message translates to:
  /// **'Foreground'**
  String get foreground;

  /// No description provided for @framework.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get framework;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @freeMemory.
  ///
  /// In en, this message translates to:
  /// **'Free Memory'**
  String get freeMemory;

  /// No description provided for @freeway.
  ///
  /// In en, this message translates to:
  /// **'Freeway'**
  String get freeway;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @fromBirthDate.
  ///
  /// In en, this message translates to:
  /// **'From Birth Date'**
  String get fromBirthDate;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @gatewayPaymentsByType.
  ///
  /// In en, this message translates to:
  /// **'Gateway Payments by Type'**
  String get gatewayPaymentsByType;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @generateAndFullyCustomizeqrCodesAndBarcodesOfEveryKind.
  ///
  /// In en, this message translates to:
  /// **'Generate and fully customize QR codes and barcodes of every kind.'**
  String get generateAndFullyCustomizeqrCodesAndBarcodesOfEveryKind;

  /// No description provided for @generateOtp.
  ///
  /// In en, this message translates to:
  /// **'Generate OTP'**
  String get generateOtp;

  /// No description provided for @getSupportPassword.
  ///
  /// In en, this message translates to:
  /// **'Get Support Password'**
  String get getSupportPassword;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @gradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get gradient;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'Guest Name'**
  String get guestName;

  /// No description provided for @guestPhone.
  ///
  /// In en, this message translates to:
  /// **'Guest Phone'**
  String get guestPhone;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @handles.
  ///
  /// In en, this message translates to:
  /// **'Handles'**
  String get handles;

  /// No description provided for @hash.
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get hash;

  /// No description provided for @hasImage.
  ///
  /// In en, this message translates to:
  /// **'Has image'**
  String get hasImage;

  /// No description provided for @headerRow.
  ///
  /// In en, this message translates to:
  /// **'Header Row'**
  String get headerRow;

  /// No description provided for @heading1.
  ///
  /// In en, this message translates to:
  /// **'Heading 1'**
  String get heading1;

  /// No description provided for @heading2.
  ///
  /// In en, this message translates to:
  /// **'Heading 2'**
  String get heading2;

  /// No description provided for @heading3.
  ///
  /// In en, this message translates to:
  /// **'Heading 3'**
  String get heading3;

  /// No description provided for @heading4.
  ///
  /// In en, this message translates to:
  /// **'Heading 4'**
  String get heading4;

  /// No description provided for @heading5.
  ///
  /// In en, this message translates to:
  /// **'Heading 5'**
  String get heading5;

  /// No description provided for @heading6.
  ///
  /// In en, this message translates to:
  /// **'Heading 6'**
  String get heading6;

  /// No description provided for @highlightColor.
  ///
  /// In en, this message translates to:
  /// **'Highlight Color'**
  String get highlightColor;

  /// No description provided for @hotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get hotel;

  /// No description provided for @hotelAvailable.
  ///
  /// In en, this message translates to:
  /// **'Hotel Available'**
  String get hotelAvailable;

  /// No description provided for @hotelOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Hotel Occupancy'**
  String get hotelOccupancy;

  /// No description provided for @hotelOccupied.
  ///
  /// In en, this message translates to:
  /// **'Hotel Occupied'**
  String get hotelOccupied;

  /// No description provided for @hotelRooms.
  ///
  /// In en, this message translates to:
  /// **'Hotel Rooms'**
  String get hotelRooms;

  /// No description provided for @hotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get hotels;

  /// No description provided for @hotelsByCity.
  ///
  /// In en, this message translates to:
  /// **'Hotels by City'**
  String get hotelsByCity;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @hourlyPrice.
  ///
  /// In en, this message translates to:
  /// **'Hourly Price'**
  String get hourlyPrice;

  /// No description provided for @htmlSource.
  ///
  /// In en, this message translates to:
  /// **'HTML Source'**
  String get htmlSource;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageDescription.
  ///
  /// In en, this message translates to:
  /// **'Image description'**
  String get imageDescription;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @imageWidth.
  ///
  /// In en, this message translates to:
  /// **'Image Width'**
  String get imageWidth;

  /// No description provided for @imei.
  ///
  /// In en, this message translates to:
  /// **'IMEI'**
  String get imei;

  /// No description provided for @incomeByType.
  ///
  /// In en, this message translates to:
  /// **'Income by Type'**
  String get incomeByType;

  /// No description provided for @increaseIndent.
  ///
  /// In en, this message translates to:
  /// **'Increase Indent'**
  String get increaseIndent;

  /// No description provided for @inlineCode.
  ///
  /// In en, this message translates to:
  /// **'Inline Code'**
  String get inlineCode;

  /// No description provided for @inputText.
  ///
  /// In en, this message translates to:
  /// **'Input Text'**
  String get inputText;

  /// No description provided for @insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// No description provided for @insertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert Image'**
  String get insertImage;

  /// No description provided for @insertLink.
  ///
  /// In en, this message translates to:
  /// **'Insert Link'**
  String get insertLink;

  /// No description provided for @insertTable.
  ///
  /// In en, this message translates to:
  /// **'Insert Table'**
  String get insertTable;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @institutionId.
  ///
  /// In en, this message translates to:
  /// **'Institution ID'**
  String get institutionId;

  /// No description provided for @introductionCode.
  ///
  /// In en, this message translates to:
  /// **'Introduction Code'**
  String get introductionCode;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount.'**
  String get invalidAmount;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @invoiceMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Invoice marked as paid'**
  String get invoiceMarkedAsPaid;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @invoiceType.
  ///
  /// In en, this message translates to:
  /// **'Invoice Type'**
  String get invoiceType;

  /// No description provided for @ipAddress.
  ///
  /// In en, this message translates to:
  /// **'IP Address'**
  String get ipAddress;

  /// No description provided for @iran.
  ///
  /// In en, this message translates to:
  /// **'Iran'**
  String get iran;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @ivEncoding.
  ///
  /// In en, this message translates to:
  /// **'IV Encoding'**
  String get ivEncoding;

  /// No description provided for @ivInitializationVector.
  ///
  /// In en, this message translates to:
  /// **'IV (Initialization Vector)'**
  String get ivInitializationVector;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDate;

  /// No description provided for @justify.
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get justify;

  /// No description provided for @key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get key;

  /// No description provided for @keyEncoding.
  ///
  /// In en, this message translates to:
  /// **'Key Encoding'**
  String get keyEncoding;

  /// No description provided for @keySize.
  ///
  /// In en, this message translates to:
  /// **'Key Size'**
  String get keySize;

  /// No description provided for @keyValue.
  ///
  /// In en, this message translates to:
  /// **'Key-Value'**
  String get keyValue;

  /// No description provided for @landline.
  ///
  /// In en, this message translates to:
  /// **'Landline'**
  String get landline;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @leaveMaskedToKeepTheCurrentValue.
  ///
  /// In en, this message translates to:
  /// **'Leave masked to keep the current value'**
  String get leaveMaskedToKeepTheCurrentValue;

  /// No description provided for @legalEntityType.
  ///
  /// In en, this message translates to:
  /// **'Legal Entity Type'**
  String get legalEntityType;

  /// No description provided for @letter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get letter;

  /// No description provided for @licencePlate.
  ///
  /// In en, this message translates to:
  /// **'Licence Plate'**
  String get licencePlate;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @loadAverage.
  ///
  /// In en, this message translates to:
  /// **'Load Average'**
  String get loadAverage;

  /// No description provided for @logo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @machineName.
  ///
  /// In en, this message translates to:
  /// **'Machine Name'**
  String get machineName;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @markThisInvoiceAsFullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark this invoice as fully paid?'**
  String get markThisInvoiceAsFullyPaid;

  /// No description provided for @matchCase.
  ///
  /// In en, this message translates to:
  /// **'Match Case'**
  String get matchCase;

  /// No description provided for @maxDurationMs.
  ///
  /// In en, this message translates to:
  /// **'Max Duration (ms)'**
  String get maxDurationMs;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @mcc.
  ///
  /// In en, this message translates to:
  /// **'MCC'**
  String get mcc;

  /// No description provided for @memoryUsage.
  ///
  /// In en, this message translates to:
  /// **'Memory Usage'**
  String get memoryUsage;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @merchantId.
  ///
  /// In en, this message translates to:
  /// **'Merchant ID'**
  String get merchantId;

  /// No description provided for @merchants.
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get merchants;

  /// No description provided for @merchantsManagement.
  ///
  /// In en, this message translates to:
  /// **'Merchants Management'**
  String get merchantsManagement;

  /// No description provided for @metaDescription.
  ///
  /// In en, this message translates to:
  /// **'Meta Description'**
  String get metaDescription;

  /// No description provided for @metaTitle.
  ///
  /// In en, this message translates to:
  /// **'Meta Title'**
  String get metaTitle;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @minDurationMs.
  ///
  /// In en, this message translates to:
  /// **'Min Duration (ms)'**
  String get minDurationMs;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @moduleShape.
  ///
  /// In en, this message translates to:
  /// **'Module shape'**
  String get moduleShape;

  /// No description provided for @moneyIn.
  ///
  /// In en, this message translates to:
  /// **'Money In'**
  String get moneyIn;

  /// No description provided for @moneyOut.
  ///
  /// In en, this message translates to:
  /// **'Money Out'**
  String get moneyOut;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @monthlyRevenueDebtPaidPenalty.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue (Debt / Paid / Penalty)'**
  String get monthlyRevenueDebtPaidPenalty;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @mostFailingPaths.
  ///
  /// In en, this message translates to:
  /// **'Most Failing Paths'**
  String get mostFailingPaths;

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveDown;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move To'**
  String get moveTo;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get moveUp;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nationalCardBack.
  ///
  /// In en, this message translates to:
  /// **'National Card (Back)'**
  String get nationalCardBack;

  /// No description provided for @nationalCardFront.
  ///
  /// In en, this message translates to:
  /// **'National Card (Front)'**
  String get nationalCardFront;

  /// No description provided for @nationalCode.
  ///
  /// In en, this message translates to:
  /// **'National Code'**
  String get nationalCode;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get needsReview;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @new_.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get new_;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New Folder'**
  String get newFolder;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New Name'**
  String get newName;

  /// No description provided for @next30Days.
  ///
  /// In en, this message translates to:
  /// **'Next 30 Days'**
  String get next30Days;

  /// No description provided for @nights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get nights;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No {items} found'**
  String noItemsFound(Object items);

  /// No description provided for @noMerchantSelected.
  ///
  /// In en, this message translates to:
  /// **'No Merchant Selected'**
  String get noMerchantSelected;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @normalText.
  ///
  /// In en, this message translates to:
  /// **'Normal Text'**
  String get normalText;

  /// No description provided for @noShow.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get noShow;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactions;

  /// No description provided for @notUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not Uploaded'**
  String get notUploaded;

  /// No description provided for @number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get number;

  /// No description provided for @numberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered List'**
  String get numberedList;

  /// No description provided for @numberOfGuests.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests'**
  String get numberOfGuests;

  /// No description provided for @occupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get occupancy;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupied;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @onlyErrors.
  ///
  /// In en, this message translates to:
  /// **'Only Errors'**
  String get onlyErrors;

  /// No description provided for @onlyExceptions.
  ///
  /// In en, this message translates to:
  /// **'Only Exceptions'**
  String get onlyExceptions;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in Browser'**
  String get openInBrowser;

  /// No description provided for @openThisPageInSafariThenAddItToYourHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Open this page in Safari, then add it to your Home Screen'**
  String get openThisPageInSafariThenAddItToYourHomeScreen;

  /// No description provided for @operatingSystem.
  ///
  /// In en, this message translates to:
  /// **'Operating System'**
  String get operatingSystem;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options:'**
  String get options;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @osMetrics.
  ///
  /// In en, this message translates to:
  /// **'OS Metrics'**
  String get osMetrics;

  /// No description provided for @otpCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get otpCode;

  /// No description provided for @otpIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'OTP is invalid'**
  String get otpIsInvalid;

  /// No description provided for @otpIsValid.
  ///
  /// In en, this message translates to:
  /// **'OTP is valid'**
  String get otpIsValid;

  /// No description provided for @otpLength.
  ///
  /// In en, this message translates to:
  /// **'OTP Length'**
  String get otpLength;

  /// No description provided for @otpTools.
  ///
  /// In en, this message translates to:
  /// **'OTP Tools'**
  String get otpTools;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @overdueInvoices.
  ///
  /// In en, this message translates to:
  /// **'Overdue Invoices'**
  String get overdueInvoices;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @ownerMobile.
  ///
  /// In en, this message translates to:
  /// **'Owner Mobile'**
  String get ownerMobile;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @ownerNationalCode.
  ///
  /// In en, this message translates to:
  /// **'Owner National Code'**
  String get ownerNationalCode;

  /// No description provided for @ownerPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Owner Phone Number'**
  String get ownerPhoneNumber;

  /// No description provided for @package.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get package;

  /// No description provided for @padding.
  ///
  /// In en, this message translates to:
  /// **'Padding'**
  String get padding;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @paragraph.
  ///
  /// In en, this message translates to:
  /// **'Paragraph'**
  String get paragraph;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @parkingManagement.
  ///
  /// In en, this message translates to:
  /// **'Parking Management'**
  String get parkingManagement;

  /// No description provided for @parkingReport.
  ///
  /// In en, this message translates to:
  /// **'Parking Report'**
  String get parkingReport;

  /// No description provided for @parkingReports.
  ///
  /// In en, this message translates to:
  /// **'Parking Reports'**
  String get parkingReports;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @pathContains.
  ///
  /// In en, this message translates to:
  /// **'Path Contains'**
  String get pathContains;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @payInvoice.
  ///
  /// In en, this message translates to:
  /// **'Pay Invoice'**
  String get payInvoice;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed.'**
  String get paymentFailed;

  /// No description provided for @paymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get paymentId;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentWasSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment was successful.'**
  String get paymentWasSuccessful;

  /// No description provided for @penalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty'**
  String get penalty;

  /// No description provided for @penaltyAmount.
  ///
  /// In en, this message translates to:
  /// **'Penalty Amount'**
  String get penaltyAmount;

  /// No description provided for @penColor.
  ///
  /// In en, this message translates to:
  /// **'Pen color'**
  String get penColor;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerification;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @persian.
  ///
  /// In en, this message translates to:
  /// **'Persian'**
  String get persian;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @placeTheBarcodeInsideTheFrame.
  ///
  /// In en, this message translates to:
  /// **'Place the barcode inside the frame'**
  String get placeTheBarcodeInsideTheFrame;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @pleaseAddYourSignatureFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add your signature first'**
  String get pleaseAddYourSignatureFirst;

  /// No description provided for @pleaseEnterSomeInputText.
  ///
  /// In en, this message translates to:
  /// **'Please enter some input text.'**
  String get pleaseEnterSomeInputText;

  /// No description provided for @pleaseSelectA.
  ///
  /// In en, this message translates to:
  /// **'Please select a {item}'**
  String pleaseSelectA(Object item);

  /// No description provided for @pnapiTester.
  ///
  /// In en, this message translates to:
  /// **'Pn API Tester'**
  String get pnapiTester;

  /// No description provided for @policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policies;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @previewNotAvailableForThisFileType.
  ///
  /// In en, this message translates to:
  /// **'Preview not available for this file type'**
  String get previewNotAvailableForThisFileType;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceNight.
  ///
  /// In en, this message translates to:
  /// **'Price / Night'**
  String get priceNight;

  /// No description provided for @pricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per Night'**
  String get pricePerNight;

  /// No description provided for @printDate.
  ///
  /// In en, this message translates to:
  /// **'Print date'**
  String get printDate;

  /// No description provided for @process.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// No description provided for @processUptime.
  ///
  /// In en, this message translates to:
  /// **'Process Uptime'**
  String get processUptime;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @propertyDashboard.
  ///
  /// In en, this message translates to:
  /// **'Property Dashboard'**
  String get propertyDashboard;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @queryString.
  ///
  /// In en, this message translates to:
  /// **'Query String'**
  String get queryString;

  /// No description provided for @quietZone.
  ///
  /// In en, this message translates to:
  /// **'Quiet zone'**
  String get quietZone;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @readingTime.
  ///
  /// In en, this message translates to:
  /// **'Reading Time'**
  String get readingTime;

  /// No description provided for @reasonForRejecting.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejecting {item}'**
  String reasonForRejecting(Object item);

  /// No description provided for @receiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// No description provided for @recentContracts.
  ///
  /// In en, this message translates to:
  /// **'Recent Contracts'**
  String get recentContracts;

  /// No description provided for @recentlyJoined.
  ///
  /// In en, this message translates to:
  /// **'Recently Joined'**
  String get recentlyJoined;

  /// No description provided for @recentlyOnboardedMerchants.
  ///
  /// In en, this message translates to:
  /// **'Recently Onboarded Merchants'**
  String get recentlyOnboardedMerchants;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @recentWalletTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Wallet Transactions'**
  String get recentWalletTransactions;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registrationDate.
  ///
  /// In en, this message translates to:
  /// **'Registration Date'**
  String get registrationDate;

  /// No description provided for @registrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration Number'**
  String get registrationNumber;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectDocuments.
  ///
  /// In en, this message translates to:
  /// **'Reject Documents'**
  String get rejectDocuments;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeBlock.
  ///
  /// In en, this message translates to:
  /// **'Remove Block'**
  String get removeBlock;

  /// No description provided for @removeColumn.
  ///
  /// In en, this message translates to:
  /// **'Remove Column'**
  String get removeColumn;

  /// No description provided for @removeRow.
  ///
  /// In en, this message translates to:
  /// **'Remove Row'**
  String get removeRow;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace All'**
  String get replaceAll;

  /// No description provided for @replaced.
  ///
  /// In en, this message translates to:
  /// **'Replaced'**
  String get replaced;

  /// No description provided for @replaceWith.
  ///
  /// In en, this message translates to:
  /// **'Replace With'**
  String get replaceWith;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @requestBody.
  ///
  /// In en, this message translates to:
  /// **'Request Body'**
  String get requestBody;

  /// No description provided for @requestHeaders.
  ///
  /// In en, this message translates to:
  /// **'Request Headers'**
  String get requestHeaders;

  /// No description provided for @requestsAndResponseDurationTrend.
  ///
  /// In en, this message translates to:
  /// **'Requests & Response Duration Trend'**
  String get requestsAndResponseDurationTrend;

  /// No description provided for @requestSize.
  ///
  /// In en, this message translates to:
  /// **'Request Size'**
  String get requestSize;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @reservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get reservation;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @responseBody.
  ///
  /// In en, this message translates to:
  /// **'Response Body'**
  String get responseBody;

  /// No description provided for @responseHeaders.
  ///
  /// In en, this message translates to:
  /// **'Response Headers'**
  String get responseHeaders;

  /// No description provided for @responseSize.
  ///
  /// In en, this message translates to:
  /// **'Response Size'**
  String get responseSize;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @rial.
  ///
  /// In en, this message translates to:
  /// **'Rial'**
  String get rial;

  /// No description provided for @richTextEditor.
  ///
  /// In en, this message translates to:
  /// **'Rich Text Editor'**
  String get richTextEditor;

  /// No description provided for @roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get roles;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @roomNumber.
  ///
  /// In en, this message translates to:
  /// **'Room Number'**
  String get roomNumber;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @rotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get rotateLeft;

  /// No description provided for @rotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get rotateRight;

  /// No description provided for @rows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get rows;

  /// No description provided for @saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get saturation;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveSignature.
  ///
  /// In en, this message translates to:
  /// **'Save signature'**
  String get saveSignature;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @scanFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Scan from Gallery'**
  String get scanFromGallery;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @scrollDownAndTapAddToHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Scroll down and tap \"Add to Home Screen\"'**
  String get scrollDownAndTapAddToHomeScreen;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchAndSelect.
  ///
  /// In en, this message translates to:
  /// **'Search and Select'**
  String get searchAndSelect;

  /// No description provided for @searchCountryCodeOrDialCode.
  ///
  /// In en, this message translates to:
  /// **'Search country, code, or dial code'**
  String get searchCountryCodeOrDialCode;

  /// No description provided for @secretKey.
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get secretKey;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectA.
  ///
  /// In en, this message translates to:
  /// **'Select a {item}'**
  String selectA(Object item);

  /// No description provided for @selectAUserToManageTheirWallet.
  ///
  /// In en, this message translates to:
  /// **'Select a user to manage their wallet'**
  String get selectAUserToManageTheirWallet;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @serial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serial;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @showValue.
  ///
  /// In en, this message translates to:
  /// **'Show value'**
  String get showValue;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @simCardNumber.
  ///
  /// In en, this message translates to:
  /// **'SIM Card Number'**
  String get simCardNumber;

  /// No description provided for @simCardSerial.
  ///
  /// In en, this message translates to:
  /// **'SIM Card Serial'**
  String get simCardSerial;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @slowestPaths.
  ///
  /// In en, this message translates to:
  /// **'Slowest Paths'**
  String get slowestPaths;

  /// No description provided for @slowestRequests.
  ///
  /// In en, this message translates to:
  /// **'Slowest Requests'**
  String get slowestRequests;

  /// No description provided for @slug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get slug;

  /// No description provided for @socialMedia.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get socialMedia;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @spendingByType.
  ///
  /// In en, this message translates to:
  /// **'Spending by Type'**
  String get spendingByType;

  /// No description provided for @square.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get square;

  /// No description provided for @stackTrace.
  ///
  /// In en, this message translates to:
  /// **'Stack Trace'**
  String get stackTrace;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Start Invoice Number'**
  String get startInvoiceNumber;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @storageManager.
  ///
  /// In en, this message translates to:
  /// **'Storage Manager'**
  String get storageManager;

  /// No description provided for @strikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get strikethrough;

  /// No description provided for @strokeWidth.
  ///
  /// In en, this message translates to:
  /// **'Stroke width'**
  String get strokeWidth;

  /// No description provided for @subAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sub Admin'**
  String get subAdmin;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @subscript.
  ///
  /// In en, this message translates to:
  /// **'Subscript'**
  String get subscript;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get subtitle;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @successErrorDistribution.
  ///
  /// In en, this message translates to:
  /// **'Success / Error Distribution'**
  String get successErrorDistribution;

  /// No description provided for @superscript.
  ///
  /// In en, this message translates to:
  /// **'Superscript'**
  String get superscript;

  /// No description provided for @supportPassword.
  ///
  /// In en, this message translates to:
  /// **'Support Password'**
  String get supportPassword;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch Camera'**
  String get switchCamera;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @systemUptime.
  ///
  /// In en, this message translates to:
  /// **'System Uptime'**
  String get systemUptime;

  /// No description provided for @systemWideReport.
  ///
  /// In en, this message translates to:
  /// **'System-wide report'**
  String get systemWideReport;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @tapAddInTheTopRightCorner.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add\" in the top-right corner'**
  String get tapAddInTheTopRightCorner;

  /// No description provided for @tapTheShareButtonInSafarisToolbar.
  ///
  /// In en, this message translates to:
  /// **'Tap the Share button in Safari\'s toolbar'**
  String get tapTheShareButtonInSafarisToolbar;

  /// No description provided for @taxpayerName.
  ///
  /// In en, this message translates to:
  /// **'Taxpayer Name'**
  String get taxpayerName;

  /// No description provided for @taxpayerRequests.
  ///
  /// In en, this message translates to:
  /// **'Taxpayer Requests'**
  String get taxpayerRequests;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @terminalId.
  ///
  /// In en, this message translates to:
  /// **'Terminal ID'**
  String get terminalId;

  /// No description provided for @terminals.
  ///
  /// In en, this message translates to:
  /// **'Terminals'**
  String get terminals;

  /// No description provided for @terminalsByType.
  ///
  /// In en, this message translates to:
  /// **'Terminals by Type'**
  String get terminalsByType;

  /// No description provided for @terminalsManagement.
  ///
  /// In en, this message translates to:
  /// **'Terminals Management'**
  String get terminalsManagement;

  /// No description provided for @textColor.
  ///
  /// In en, this message translates to:
  /// **'Text Color'**
  String get textColor;

  /// No description provided for @textFiles.
  ///
  /// In en, this message translates to:
  /// **'Text files'**
  String get textFiles;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textSpacing.
  ///
  /// In en, this message translates to:
  /// **'Text spacing'**
  String get textSpacing;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @theVideoMustBeAtLeast4Seconds.
  ///
  /// In en, this message translates to:
  /// **'The video must be at least 4 seconds'**
  String get theVideoMustBeAtLeast4Seconds;

  /// No description provided for @thisFieldIsInvalid.
  ///
  /// In en, this message translates to:
  /// **'This field is invalid.'**
  String get thisFieldIsInvalid;

  /// No description provided for @thisFieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get thisFieldIsRequired;

  /// No description provided for @thisFolderIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get thisFolderIsEmpty;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @toBirthDate.
  ///
  /// In en, this message translates to:
  /// **'To Birth Date'**
  String get toBirthDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @topMerchants.
  ///
  /// In en, this message translates to:
  /// **'Top Merchants'**
  String get topMerchants;

  /// No description provided for @topMerchantsByTerminalCount.
  ///
  /// In en, this message translates to:
  /// **'Top Merchants (by terminal count)'**
  String get topMerchantsByTerminalCount;

  /// No description provided for @totalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total Debt'**
  String get totalDebt;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get totalItems;

  /// No description provided for @totalMemory.
  ///
  /// In en, this message translates to:
  /// **'Total Memory'**
  String get totalMemory;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @totalPenalty.
  ///
  /// In en, this message translates to:
  /// **'Total Penalty'**
  String get totalPenalty;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @totalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Total Remaining'**
  String get totalRemaining;

  /// No description provided for @totalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get totalRequests;

  /// No description provided for @totalResults.
  ///
  /// In en, this message translates to:
  /// **'Total Results'**
  String get totalResults;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total size'**
  String get totalSize;

  /// No description provided for @traceId.
  ///
  /// In en, this message translates to:
  /// **'Trace Id'**
  String get traceId;

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number'**
  String get trackingNumber;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transactionsByMethod.
  ///
  /// In en, this message translates to:
  /// **'Transactions by Method'**
  String get transactionsByMethod;

  /// No description provided for @transactionsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Transactions by Status'**
  String get transactionsByStatus;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transferFunds.
  ///
  /// In en, this message translates to:
  /// **'Transfer Funds'**
  String get transferFunds;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @unassignedTerminals.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Terminals'**
  String get unassignedTerminals;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unexpectedErrorPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unexpected Error, Please try again'**
  String get unexpectedErrorPleaseTryAgain;

  /// No description provided for @uniqueTaxCode.
  ///
  /// In en, this message translates to:
  /// **'Unique Tax Code'**
  String get uniqueTaxCode;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @unpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublish;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @useOutputAsInput.
  ///
  /// In en, this message translates to:
  /// **'Use output as input'**
  String get useOutputAsInput;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @userCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User created successfully'**
  String get userCreatedSuccessfully;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get userDetails;

  /// No description provided for @userDocuments.
  ///
  /// In en, this message translates to:
  /// **'User Documents'**
  String get userDocuments;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmail;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @userIp.
  ///
  /// In en, this message translates to:
  /// **'User / IP'**
  String get userIp;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @usersManagement.
  ///
  /// In en, this message translates to:
  /// **'Users Management'**
  String get usersManagement;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @videoAvailable.
  ///
  /// In en, this message translates to:
  /// **'Video available'**
  String get videoAvailable;

  /// No description provided for @viewItem.
  ///
  /// In en, this message translates to:
  /// **'View {item}'**
  String viewItem(Object item);

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit website'**
  String get visitWebsite;

  /// No description provided for @visualAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Visual Authentication'**
  String get visualAuthentication;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @walletManagement.
  ///
  /// In en, this message translates to:
  /// **'Wallet Management'**
  String get walletManagement;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @words.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get words;

  /// No description provided for @writeSomething.
  ///
  /// In en, this message translates to:
  /// **'Write something...'**
  String get writeSomething;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @youHaveNotSubmittedAnyTaxpayerRequestYet.
  ///
  /// In en, this message translates to:
  /// **'You have not submitted any taxpayer request yet.'**
  String get youHaveNotSubmittedAnyTaxpayerRequestYet;

  /// No description provided for @yourSessionHasExpiredPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get yourSessionHasExpiredPleaseSignInAgain;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCode;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
