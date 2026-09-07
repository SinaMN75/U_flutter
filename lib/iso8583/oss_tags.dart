import "package:u/utilities.dart";

/// Top-level TLV tags carried in ISO field 63.
abstract class PrimitiveTags {
  static const int posSerial = 0xC0;
  static const int appVersion = 0xC1;
  static const int logonKeyLength = 0xC2;
  static const int pan = 0xC3;
  static const int pan2 = 0xC4;
  static const int track2 = 0xC5;
  static const int ksn = 0xC6;
  static const int localDateYear = 0xC7;
  static const int dualApprovalCode = 0xC8;
  static const int manualReference = 0xC9;
  static const int errorMessage = 0xCA;
  static const int language = 0xCB;
  static const int issuerName = 0xCC;
  static const int issuerName2 = 0xCD;
  static const int serverDateTime = 0xCE;
  static const int reasonCode = 0xCF;
  static const int posSerial2 = 0xD0;
  static const int nationalIdPin = 0xD1;
  static const int mobileNumber = 0xD2;
  static const int cardApproved = 0xD3;
  static const int customerName = 0xD4;
  static const int merchantScore = 0xD5;
  static const int nationalId = 0xD6;
  static const int centerTerminalId = 0xD7;
  static const int relatedOtp = 0xD8;
  static const int refundKey = 0xD9;
  static const int logonMacKeyIndex = 0xDA;
  static const int receivingIin = 0xDB;
  static const int issuerDiscount = 0xDC;
  static const int newPin = 0xDD;
  static const int maskPan1 = 0xDF01;
  static const int maskPan2 = 0xDF02;
  static const int terminalLogonGroup = 0xDF03;
  static const int functionCode = 0xDF04;
  static const int originalTxnId = 0xDF06;
  static const int originalTxnDate = 0xDF07;
  static const int originalTerminalId = 0xDF08;
  static const int cvv2 = 0xDF0A;
  static const int accountId1Host = 0xDF0B;
  static const int accountId2Host = 0xDF0D;
  static const int accountId1 = 0xDF0C;
  static const int accountId2 = 0xDF0E;
  static const int locationLat = 0xDF10;
  static const int locationLong = 0xDF11;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _key(posSerial): AsciiValuePackager.instance,
    _key(track2): BinaryValuePackager.instance,
    _key(pan): BinaryValuePackager.instance,
    _key(pan2): BinaryValuePackager.instance,
    _key(logonKeyLength): BcdValuePackager.rightPadF,
    _key(appVersion): AsciiValuePackager.instance,
    _key(localDateYear): BcdValuePackager.rightPadF,
    _key(ksn): BinaryValuePackager.instance,
    _key(dualApprovalCode): AsciiValuePackager.instance,
    _key(manualReference): AsciiValuePackager.instance,
    _key(errorMessage): AsciiValuePackager.instance,
    _key(language): AsciiValuePackager.instance,
    _key(issuerName): AsciiValuePackager.instance,
    _key(issuerName2): AsciiValuePackager.instance,
    _key(serverDateTime): BcdValuePackager.rightPadF,
    _key(reasonCode): BcdValuePackager.rightPadF,
    _key(posSerial2): AsciiValuePackager.instance,
    _key(nationalIdPin): BinaryValuePackager.instance,
    _key(mobileNumber): BcdValuePackager.rightPadF,
    _key(cardApproved): BcdValuePackager.rightPadF,
    _key(customerName): AsciiValuePackager.instance,
    _key(merchantScore): AsciiValuePackager.instance,
    _key(nationalId): AsciiValuePackager.instance,
    _key(centerTerminalId): AsciiValuePackager.instance,
    _key(relatedOtp): BcdValuePackager.rightPadF,
    _key(refundKey): AsciiValuePackager.instance,
    _key(logonMacKeyIndex): AsciiValuePackager.instance,
    _key(receivingIin): AsciiValuePackager.instance,
    _key(issuerDiscount): BcdValuePackager.rightPadF,
    _key(newPin): BinaryValuePackager.instance,
    _key(maskPan1): AsciiValuePackager.instance,
    _key(maskPan2): AsciiValuePackager.instance,
    _key(terminalLogonGroup): AsciiValuePackager.instance,
    _key(functionCode): BcdValuePackager.rightPadF,
    _key(originalTxnId): AsciiValuePackager.instance,
    _key(originalTxnDate): BcdValuePackager.rightPadF,
    _key(originalTerminalId): AsciiValuePackager.instance,
    _key(cvv2): BcdValuePackager.rightPadF,
    _key(accountId1): AsciiValuePackager.instance,
    _key(accountId2): AsciiValuePackager.instance,
    _key(accountId1Host): AsciiValuePackager.instance,
    _key(accountId2Host): AsciiValuePackager.instance,
    _key(locationLat): BcdValuePackager.rightPadF,
    _key(locationLong): BcdValuePackager.rightPadF,
  };

  static String _key(int tag) => TlvMsg.tagString(tag);
}

String _path(List<int> tags) => tags.map(TlvMsg.tagString).join(".");

/// E0 — session keys returned by logon.
abstract class SessionKeyTags {
  static const int root = 0xE0;
  static const int keyValue = 0x81;
  static const int keyKvc = 0x82;
  static const int keyType = 0x83;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, keyValue]): BinaryValuePackager.instance,
    _path(<int>[root, keyType]): BcdValuePackager.rightPadF,
    _path(<int>[root, keyKvc]): BinaryValuePackager.instance,
  };
}

/// E2 — value added services, with E2.E0 items.
abstract class VasKeyTags {
  static const int root = 0xE2;
  static const int vasId = 0xC0;
  static const int vasName = 0xC1;
  static const int vasOrgType = 0xC2;
  static const int vasAuthCode = 0xC3;
  static const int vasOrgCode = 0xC4;
  static const int vasOrgUnitCode = 0xC5;
  static const int vasOrgName = 0xC6;
  static const int items = 0xE0;

  static const int itemId = 0x81;
  static const int itemValue = 0x82;
  static const int itemType = 0x83;
  static const int itemName = 0x84;
  static const int itemValueSecure = 0x85;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, vasId]): BcdValuePackager.rightPadF,
    _path(<int>[root, vasName]): AsciiValuePackager.instance,
    _path(<int>[root, vasOrgType]): BcdValuePackager.rightPadF,
    _path(<int>[root, vasAuthCode]): AsciiValuePackager.instance,
    _path(<int>[root, vasOrgCode]): AsciiValuePackager.instance,
    _path(<int>[root, vasOrgUnitCode]): AsciiValuePackager.instance,
    _path(<int>[root, vasOrgName]): AsciiValuePackager.instance,
    _path(<int>[root, items, itemId]): BcdValuePackager.rightPadF,
    _path(<int>[root, items, itemValue]): AsciiValuePackager.instance,
    _path(<int>[root, items, itemType]): BcdValuePackager.rightPadF,
    _path(<int>[root, items, itemName]): AsciiValuePackager.instance,
    _path(<int>[root, items, itemValueSecure]): BcdValuePackager.rightPadF,
  };
}

/// E4 — a basket order, with E4.E0 good items.
abstract class OrderKeyTags {
  static const int root = 0xE4;
  static const int orderId = 0xC0;
  static const int totalPayDiscount = 0xC1;
  static const int totalCredit = 0xC2;
  static const int userType = 0xC3;
  static const int saleCondition = 0xC4;
  static const int goodsUpdateVer = 0xC5;
  static const int queueNo = 0xC6;
  static const int fraudAlertSupport = 0xCA;
  static const int goodItems = 0xE0;

  static const int goodId = 0x81;
  static const int goodCount = 0x82;
  static const int goodType = 0x83;
  static const int goodName = 0x84;
  static const int localPrice = 0x85;
  static const int discount = 0x86;
  static const int centerPrice = 0x87;
  static const int goodImageUrl = 0x88;
  static const int goodValue = 0x89;
  static const int goodValueUnit = 0x8A;
  static const int categoryId = 0x8B;
  static const int reserve1String = 0xC0;
  static const int reserve2String = 0xC1;
  static const int reserve3String = 0xC2;
  static const int reserve4String = 0xC3;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, orderId]): AsciiValuePackager.instance,
    _path(<int>[root, totalPayDiscount]): BcdValuePackager.rightPadF,
    _path(<int>[root, totalCredit]): BcdValuePackager.rightPadF,
    _path(<int>[root, userType]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleCondition]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodsUpdateVer]): AsciiValuePackager.instance,
    _path(<int>[root, queueNo]): BcdValuePackager.rightPadF,
    _path(<int>[root, fraudAlertSupport]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, goodId]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, goodCount]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, goodType]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, goodName]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, localPrice]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, discount]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, centerPrice]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, goodImageUrl]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, goodValue]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, goodValueUnit]): BcdValuePackager.rightPadF,
    _path(<int>[root, goodItems, reserve1String]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, reserve2String]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, reserve3String]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, reserve4String]): AsciiValuePackager.instance,
    _path(<int>[root, goodItems, categoryId]): AsciiValuePackager.instance,
  };
}

/// E3 — card acceptor details, settlement accounts and terminal settings.
abstract class AcceptorKeyTags {
  static const int root = 0xE3;
  static const int name = 0x81;
  static const int fName = 0x82;
  static const int tel = 0x83;
  static const int postalCode = 0x84;
  static const int settlementAccounts = 0xE0;
  static const int terminalSetting = 0xE1;

  static const int accountId = 0xC0;
  static const int accountTitle = 0xC2;
  static const int accountAmount = 0xC3;
  static const int accountCurrency = 0xC4;
  static const int accountType = 0xC6;

  static const int pcposHome = 0x81;
  static const int commEnable = 0x82;
  static const int httpEnable = 0x83;
  static const int kahrobaEnable = 0x84;
  static const int homeMenus = 0x85;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, name]): AsciiValuePackager.instance,
    _path(<int>[root, fName]): AsciiValuePackager.instance,
    _path(<int>[root, tel]): BcdValuePackager.rightPadF,
    _path(<int>[root, postalCode]): BcdValuePackager.rightPadF,
    _path(<int>[root, settlementAccounts, accountId]): AsciiValuePackager.instance,
    _path(<int>[root, settlementAccounts, accountAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, settlementAccounts, accountCurrency]): BcdValuePackager.rightPadF,
    _path(<int>[root, settlementAccounts, accountTitle]): AsciiValuePackager.instance,
    _path(<int>[root, settlementAccounts, accountType]): BcdValuePackager.rightPadF,
    _path(<int>[root, terminalSetting, pcposHome]): BcdValuePackager.rightPadF,
    _path(<int>[root, terminalSetting, commEnable]): BcdValuePackager.rightPadF,
    _path(<int>[root, terminalSetting, httpEnable]): BcdValuePackager.rightPadF,
    _path(<int>[root, terminalSetting, kahrobaEnable]): BcdValuePackager.rightPadF,
    _path(<int>[root, terminalSetting, homeMenus]): BcdValuePackager.rightPadF,
  };
}

/// E1 — club/CIS credit info. Shares its root with [StatementKeyTags], which is
/// merged later and therefore wins on E1.81.
abstract class CisKeyTags {
  static const int root = 0xE1;
  static const int totalCredit = 0x81;
  static const int count = 0x82;
  static const int availableCredit = 0x83;
  static const int freePrice = 0x84;
  static const int payMethod = 0x85;
  static const int productType = 0x86;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, totalCredit]): AsciiValuePackager.instance,
    _path(<int>[root, count]): AsciiValuePackager.instance,
    _path(<int>[root, availableCredit]): AsciiValuePackager.instance,
    _path(<int>[root, freePrice]): AsciiValuePackager.instance,
    _path(<int>[root, payMethod]): AsciiValuePackager.instance,
    _path(<int>[root, productType]): AsciiValuePackager.instance,
  };
}

/// E7 — sale report totals, with E7.E0 per-good rows.
abstract class ReportSaleTags {
  static const int root = 0xE7;
  static const int reportFromDate = 0xC0;
  static const int reportToDate = 0xC1;
  static const int firstTransactionDate = 0xC2;
  static const int lastTransactionDate = 0xC3;
  static const int totalDiscountAmount = 0xC4;
  static const int totalPaymentAmount = 0xC5;
  static const int customerTotalNumber = 0xC6;
  static const int customerTotalAmount = 0xC7;
  static const int legalCustomerTotalNumber = 0xC8;
  static const int legalCustomerTotalAmount = 0xC9;
  static const int settlementDate = 0xCA;
  static const int settlementAmount = 0xCB;
  static const int totalAmount = 0xCC;
  static const int lastModifiedDate = 0xCD;
  static const int saleGoods = 0xE0;

  static const int goodId = 0x81;
  static const int goodName = 0x82;
  static const int goodTotalDiscountAmount = 0x83;
  static const int goodTotalPaymentAmount = 0x84;
  static const int goodTotalAmount = 0x85;
  static const int goodLastModifiedDate = 0x86;
  static const int goodCount = 0x87;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, reportFromDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, reportToDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, firstTransactionDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, lastTransactionDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, totalDiscountAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, totalPaymentAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, customerTotalNumber]): BcdValuePackager.rightPadF,
    _path(<int>[root, legalCustomerTotalNumber]): BcdValuePackager.rightPadF,
    _path(<int>[root, settlementAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, customerTotalAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, legalCustomerTotalAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, settlementDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, totalAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, lastModifiedDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleGoods, goodId]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleGoods, goodName]): AsciiValuePackager.instance,
    _path(<int>[root, saleGoods, goodCount]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleGoods, goodTotalDiscountAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleGoods, goodTotalPaymentAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleGoods, goodTotalAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, saleGoods, goodLastModifiedDate]): BcdValuePackager.rightPadF,
  };
}

/// E8 — club services, with E8.E0 service items.
abstract class ServiceKeyTags {
  static const int root = 0xE8;
  static const int serviceItems = 0xE0;
  static const int clubCode = 0xC0;
  static const int clubName = 0xC1;
  static const int orderId = 0xC2;
  static const int totalDiscount = 0xC3;
  static const int customerId = 0xC4;
  static const int customerName = 0xC5;
  static const int registerDate = 0xC6;
  static const int customerMobile = 0xC7;
  static const int authorizeCode = 0xC8;

  static const int serviceCode = 0x81;
  static const int serviceName = 0x82;
  static const int servicePrice = 0x83;
  static const int discountAmount = 0x84;
  static const int discountReason = 0x85;
  static const int serviceType = 0x86;
  static const int countableType = 0x87;
  static const int priceStrategy = 0x88;
  static const int quantity = 0x89;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, clubCode]): BcdValuePackager.rightPadF,
    _path(<int>[root, clubName]): AsciiValuePackager.instance,
    _path(<int>[root, orderId]): AsciiValuePackager.instance,
    _path(<int>[root, totalDiscount]): BcdValuePackager.rightPadF,
    _path(<int>[root, customerId]): AsciiValuePackager.instance,
    _path(<int>[root, customerName]): AsciiValuePackager.instance,
    _path(<int>[root, registerDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, customerMobile]): BcdValuePackager.rightPadF,
    _path(<int>[root, authorizeCode]): AsciiValuePackager.instance,
    _path(<int>[root, serviceItems, serviceCode]): AsciiValuePackager.instance,
    _path(<int>[root, serviceItems, serviceName]): AsciiValuePackager.instance,
    _path(<int>[root, serviceItems, servicePrice]): BcdValuePackager.rightPadF,
    _path(<int>[root, serviceItems, discountAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, serviceItems, discountReason]): AsciiValuePackager.instance,
    _path(<int>[root, serviceItems, serviceType]): AsciiValuePackager.instance,
    _path(<int>[root, serviceItems, countableType]): BcdValuePackager.rightPadF,
    _path(<int>[root, serviceItems, priceStrategy]): BcdValuePackager.rightPadF,
    _path(<int>[root, serviceItems, quantity]): AsciiValuePackager.instance,
  };
}

/// EA — loans, with EA.E0 installments.
abstract class LoanKeyTags {
  static const int root = 0xEA;
  static const int loanId = 0xC0;
  static const int installmentCount = 0xC1;
  static const int installments = 0xE0;

  static const int installmentId = 0x81;
  static const int installmentDate = 0x82;
  static const int installmentAmount = 0x83;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, loanId]): AsciiValuePackager.instance,
    _path(<int>[root, installmentCount]): BcdValuePackager.rightPadF,
    _path(<int>[root, installments, installmentId]): BcdValuePackager.rightPadF,
    _path(<int>[root, installments, installmentDate]): BcdValuePackager.rightPadF,
    _path(<int>[root, installments, installmentAmount]): BcdValuePackager.rightPadF,
  };
}

/// E9 — cardholder account info, with E9.E0 accounts and E9.E1 coupons.
abstract class CardHolderAccountInfoTags {
  static const int root = 0xE9;
  static const int vasOrgCode = 0xC1;
  static const int vasOrgUnitCode = 0xC2;
  static const int vasOrgName = 0xC3;
  static const int familyMemberCount = 0xC4;
  static const int accountInfo = 0xE0;
  static const int couponItems = 0xE1;

  static const int accountId = 0xC0;
  static const int accountHostId = 0xC1;
  static const int accountTitle = 0xC2;
  static const int debitAmount = 0xC3;
  static const int debitCurrency = 0xC4;
  static const int addAmounts = 0xC5;
  static const int accountType = 0xC6;
  static const int accountTypeCode = 0xC7;
  static const int darikId = 0x81;
  static const int darikBalance = 0x82;
  static const int darikBaseAmount = 0x83;
  static const int darikMaxInstallmentCount = 0x84;
  static const int darikTitle = 0x85;
  static const int darikInstallmentType = 0x86;
  static const int darikDownPaymentRateType = 0x87;
  static const int darikDownPaymentRate = 0x88;
  static const int darikInstallmentCount = 0x89;

  static const int couponId = 0x81;
  static const int couponCode = 0x82;
  static const int couponName = 0x83;
  static const int couponDesc = 0x84;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, vasOrgCode]): AsciiValuePackager.instance,
    _path(<int>[root, vasOrgUnitCode]): AsciiValuePackager.instance,
    _path(<int>[root, vasOrgName]): AsciiValuePackager.instance,
    _path(<int>[root, familyMemberCount]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, accountId]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, accountHostId]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, debitAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, debitCurrency]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, accountTitle]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, addAmounts]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, accountType]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, accountTypeCode]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, darikId]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, darikBalance]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, darikBaseAmount]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, darikMaxInstallmentCount]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, darikTitle]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, darikInstallmentType]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, darikDownPaymentRateType]): AsciiValuePackager.instance,
    _path(<int>[root, accountInfo, darikDownPaymentRate]): BcdValuePackager.rightPadF,
    _path(<int>[root, accountInfo, darikInstallmentCount]): BcdValuePackager.rightPadF,
    _path(<int>[root, couponItems, couponId]): BcdValuePackager.rightPadF,
    _path(<int>[root, couponItems, couponCode]): BcdValuePackager.rightPadF,
    _path(<int>[root, couponItems, couponName]): AsciiValuePackager.instance,
    _path(<int>[root, couponItems, couponDesc]): AsciiValuePackager.instance,
  };
}

/// E1 — account statement rows. Merged after [CisKeyTags], so E1.81 resolves to
/// BCD here, matching the Java merge order.
abstract class StatementKeyTags {
  static const int root = 0xE1;
  static const int dateTime = 0x81;
  static const int amount = 0x82;
  static const int balance = 0x83;
  static const int description = 0x84;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, dateTime]): BcdValuePackager.rightPadF,
    _path(<int>[root, balance]): AsciiValuePackager.instance,
    _path(<int>[root, amount]): AsciiValuePackager.instance,
    _path(<int>[root, description]): AsciiValuePackager.instance,
  };
}

/// E5 — offline and TMS transactions: file transfer, notify, my goods.
abstract class OfflineOrTmsTxnKeyTags {
  static const int root = 0xE5;
  static const int batchId = 0xC1;
  static const int samId = 0xC2;
  static const int offlineChannel = 0xC3;
  static const int goodItems = 0xE0;
  static const int fileTransfer = 0xE1;
  static const int notify = 0xE2;
  static const int myGoodItems = 0xE3;

  static const int sessionId = 0xC1;
  static const int fileContentSegment = 0xC2;
  static const int totalSegment = 0xC3;
  static const int currentSegment = 0xC4;
  static const int fileName = 0xC5;
  static const int fileDateTime = 0xC6;
  static const int fileTag1 = 0xC7;
  static const int fileTag2 = 0xC8;
  static const int fileTag3 = 0xC9;

  static const int notifyType = 0xC1;
  static const int notifyContentType = 0xC2;
  static const int notifyContent = 0xC3;

  static const int myGoodId = 0x81;
  static const int myGoodName = 0x82;
  static const int myGoodImageUrl = 0x83;

  static Map<String, ValuePackager> get tagFormatMap => <String, ValuePackager>{
    _path(<int>[root, batchId]): AsciiValuePackager.instance,
    _path(<int>[root, samId]): BcdValuePackager.rightPadF,
    _path(<int>[root, offlineChannel]): BcdValuePackager.rightPadF,
    _path(<int>[root, fileTransfer, sessionId]): AsciiValuePackager.instance,
    _path(<int>[root, fileTransfer, fileContentSegment]): BinaryValuePackager.instance,
    _path(<int>[root, fileTransfer, totalSegment]): BcdValuePackager.rightPadF,
    _path(<int>[root, fileTransfer, currentSegment]): BcdValuePackager.rightPadF,
    _path(<int>[root, fileTransfer, fileName]): AsciiValuePackager.instance,
    _path(<int>[root, fileTransfer, fileDateTime]): BcdValuePackager.rightPadF,
    _path(<int>[root, fileTransfer, fileTag1]): AsciiValuePackager.instance,
    _path(<int>[root, fileTransfer, fileTag2]): AsciiValuePackager.instance,
    _path(<int>[root, fileTransfer, fileTag3]): AsciiValuePackager.instance,
    _path(<int>[root, notify, notifyType]): AsciiValuePackager.instance,
    _path(<int>[root, notify, notifyContentType]): AsciiValuePackager.instance,
    _path(<int>[root, notify, notifyContent]): BinaryValuePackager.instance,
    _path(<int>[root, myGoodItems, myGoodId]): BcdValuePackager.rightPadF,
    _path(<int>[root, myGoodItems, myGoodName]): AsciiValuePackager.instance,
    _path(<int>[root, myGoodItems, myGoodImageUrl]): AsciiValuePackager.instance,
  };
}
