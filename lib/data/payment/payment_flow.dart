part of "../data.dart";

abstract class UAppPrices {
  static UAppSettingsResponse? _settings;

  static Future<UAppSettingsResponse?> settings() async {
    if (_settings != null) return _settings;
    final Completer<UAppSettingsResponse?> completer = Completer<UAppSettingsResponse?>();
    await UServices.appSettings.read(
      p: UAppSettingsReadParams(),
      onOk: (UResponse<UAppSettingsResponse> r) {
        _settings = r.result;
        completer.complete(_settings);
      },
      onError: (UEmptyResponse e) => completer.complete(null),
      onException: (String e) => completer.complete(null),
    );
    return completer.future;
  }

  static Future<UApiCallCosts?> costs() async => (await settings())?.apiCallCosts;

  static Future<UChargeInternet?> chargeInternet(TagSimOperator operator) async => (await settings())?.chargeInternet.firstWhereOrNull((UChargeInternet e) => e.operator == operator.number);

  static Future<double> chargeTaxPercent() async => (await settings())?.chargeInternetTaxPercent ?? 0;

  // The server debits the nominal price plus the tax percent, so the app must show and send the very same numbers.
  static int payableChargeAmount(int nominalAmount, double taxPercent) => (nominalAmount + nominalAmount * taxPercent / 100).round();
}

class UPaymentLine {
  const UPaymentLine(this.label, this.value);

  final String label;
  final String value;
}

class UPaymentRequest {
  UPaymentRequest({
    required this.title,
    required this.amount,
    required this.onPay,
    this.lines = const <UPaymentLine>[],
  });

  final String title;
  final List<UPaymentLine> lines;
  final int amount;
  final Future<bool> Function() onPay;
}
