part of "../data.dart";

abstract class UAppPrices {
  static UApiCallCosts? _costs;

  static Future<UApiCallCosts?> costs() async {
    if (_costs != null) return _costs;
    final Completer<UApiCallCosts?> completer = Completer<UApiCallCosts?>();
    await UServices.appSettings.read(
      p: UAppSettingsReadParams(),
      onOk: (UResponse<UAppSettingsResponse> r) {
        _costs = r.result?.apiCallCosts;
        completer.complete(_costs);
      },
      onError: (UEmptyResponse e) => completer.complete(null),
      onException: (String e) => completer.complete(null),
    );
    return completer.future;
  }
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
