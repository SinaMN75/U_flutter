part of "../data.dart";

abstract class UReceiptKeyValues {
  static const String bed = "bed";
  static const String billId = "billId";
  static const String billType = "billType";
  static const String chargePin = "chargePin";
  static const String checkInDate = "checkInDate";
  static const String checkOutDate = "checkOutDate";
  static const String contract = "contract";
  static const String dorm = "dorm";
  static const String drivingLicenseNumber = "drivingLicenseNumber";
  static const String goldWeight = "goldWeight";
  static const String hotel = "hotel";
  static const String iBan = "iBan";
  static const String internetPackage = "internetPackage";
  static const String invoiceId = "invoiceId";
  static const String licencePlate = "licencePlate";
  static const String nationalCode = "nationalCode";
  static const String numberOfNights = "numberOfNights";
  static const String simOperator = "operator";
  static const String orderId = "orderId";
  static const String paymentId = "paymentId";
  static const String penalty = "penalty";
  static const String period = "period";
  static const String phoneNumber = "phoneNumber";
  static const String reference = "reference";
  static const String refundAmount = "refundAmount";
  static const String reservationId = "reservationId";
  static const String room = "room";
  static const String trackingNumber = "trackingNumber";
  static const String unitPrice = "unitPrice";
  static const String zipCode = "zipCode";

  static const Set<String> _money = <String>{penalty, refundAmount, unitPrice};
  static const Set<String> _dates = <String>{checkInDate, checkOutDate};
  static const Set<String> _copyable = <String>{
    billId,
    chargePin,
    contract,
    iBan,
    invoiceId,
    orderId,
    paymentId,
    reference,
    reservationId,
    trackingNumber,
  };

  static String label(String key) {
    switch (key) {
      case bed:
        return U.s.bed;
      case billId:
        return U.s.billId;
      case billType:
        return U.s.billType;
      case chargePin:
        return U.s.chargePin;
      case checkInDate:
        return U.s.checkInDate;
      case checkOutDate:
        return U.s.checkOutDate;
      case contract:
        return U.s.contract;
      case dorm:
        return U.s.dorm;
      case drivingLicenseNumber:
        return U.s.drivingLicenseNumber;
      case goldWeight:
        return U.s.goldWeight;
      case hotel:
        return U.s.hotel;
      case iBan:
        return U.s.iBan;
      case internetPackage:
        return U.s.internetPackage;
      case invoiceId:
        return U.s.invoiceId;
      case licencePlate:
        return U.s.licencePlate;
      case nationalCode:
        return U.s.nationalCode;
      case numberOfNights:
        return U.s.numberOfNights;
      case simOperator:
        return U.s.operator;
      case orderId:
        return U.s.orderId;
      case paymentId:
        return U.s.paymentId;
      case penalty:
        return U.s.penalty;
      case period:
        return U.s.period;
      case phoneNumber:
        return U.s.phoneNumber;
      case reference:
        return U.s.reference;
      case refundAmount:
        return U.s.refundAmount;
      case reservationId:
        return U.s.reservationId;
      case room:
        return U.s.room;
      case trackingNumber:
        return U.s.trackingNumber;
      case unitPrice:
        return U.s.unitPrice;
      case zipCode:
        return U.s.zipCode;
      default:
        return key;
    }
  }

  static String value(String key, String raw) {
    if (raw.isEmpty) return "---";
    if (_money.contains(key)) return (double.tryParse(raw) ?? 0).rial();
    if (_dates.contains(key)) return _date(raw);
    if (key == period) return raw.split("|").map(_date).join(" - ");
    if (key == simOperator) return TagSimOperator.values.fromNumber(int.tryParse(raw) ?? 0)?.localizedTitle ?? raw;
    if (key == goldWeight) return "$raw ${U.s.gram}";
    return raw;
  }

  static String _date(String raw) {
    final DateTime? parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : parsed.toJalaliDate();
  }

  static Future<List<UReceiptRow>> latestWalletTxnRows() async {
    List<UReceiptRow> result = <UReceiptRow>[];
    await UServices.wallet.readTxn(
      p: UWalletTxnReadParams(userId: U.user.id, pageNumber: 1, pageSize: 1, orderBy: TagOrderBy.createdAtDescending.number),
      onOk: (UResponse<List<UWalletTxnResponse>> r) => result = rows(r.result?.firstOrNull?.jsonData.keyValues ?? <UKeyValueData>[]),
    );
    return result;
  }

  static List<UReceiptRow> rows(List<UKeyValueData> keyValues) => keyValues
      .where((UKeyValueData i) => i.key.isNotEmpty)
      .map((UKeyValueData i) => UReceiptRow(label: label(i.key), value: value(i.key, i.value), copyable: _copyable.contains(i.key)))
      .toList();
}

extension UWalletTxnReceiptExtension on UWalletTxnResponse {
  List<UReceiptRow> get receiptRows => UReceiptKeyValues.rows(jsonData.keyValues);
}

extension UTxnReceiptExtension on UTxnResponse {
  List<UReceiptRow> get receiptRows => UReceiptKeyValues.rows(jsonData.keyValues);
}
