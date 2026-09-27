part of "../../u_admin.dart";

/// Tariffs are one row per parking + vehicle type, carrying both the hourly rates and the
/// subscription prices, so the list is short and edited in place.
class UAdminParkingTariffController extends UBaseController {
  List<UParkingTariffResponse> list = <UParkingTariffResponse>[];
  UParkingResponse? parking;

  String parkingId = "";
  late final TextEditingController entrance = fields.text();
  late final TextEditingController dayHourly = fields.text();
  late final TextEditingController nightHourly = fields.text();
  late final TextEditingController dailyCap = fields.text();
  late final TextEditingController weekly = fields.text();
  late final TextEditingController monthly = fields.text();
  late final TextEditingController quarterly = fields.text();
  late final TextEditingController freeMinutes = fields.text();
  TagVehicle vehicleType = TagVehicle.car;
  bool roundToFullHour = false;
  bool perMinuteAfterFirstHour = true;

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingTariff(
      p: UParkingTariffReadParams(
        parkingId: parking?.id,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingTariffSelectorArgs(creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingTariffResponse>> r) {
        list = r.result ?? <UParkingTariffResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm(UParkingTariffResponse? t) {
    parkingId = t?.parkingId ?? parking?.id ?? "";
    entrance.text = t?.entrancePrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    dayHourly.text = t?.dayHourlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    nightHourly.text = t?.nightHourlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    dailyCap.text = t?.dailyCap.toStringAsSmartRound(maxPrecision: 0) ?? "";
    weekly.text = t?.weeklyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    monthly.text = t?.monthlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    quarterly.text = t?.quarterlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    freeMinutes.text = (t?.freeMinutes ?? 0).toString();
    vehicleType = TagVehicle.values.fromNumber(t?.vehicleType ?? TagVehicle.car.number) ?? TagVehicle.car;
    roundToFullHour = t?.roundToFullHour ?? false;
    perMinuteAfterFirstHour = t?.perMinuteAfterFirstHour ?? true;
  }

  Future<bool> save() async {
    final dynamic ok = await submit(
      UServices.parking.createParkingTariff(
        p: UParkingTariffCreateParams(
          parkingId: parkingId,
          vehicleType: vehicleType.number,
          tags: <int>[TagParkingTariff.hourly.number, TagParkingTariff.subscription.number],
          entrancePrice: numOf(entrance) ?? 0,
          dayHourlyPrice: numOf(dayHourly) ?? 0,
          nightHourlyPrice: numOf(nightHourly) ?? 0,
          dailyCap: numOf(dailyCap) ?? 0,
          weeklyPrice: numOf(weekly) ?? 0,
          monthlyPrice: numOf(monthly) ?? 0,
          quarterlyPrice: numOf(quarterly) ?? 0,
          freeMinutes: intOf(freeMinutes) ?? 0,
          roundToFullHour: roundToFullHour,
          perMinuteAfterFirstHour: perMinuteAfterFirstHour,
        ),
      ),
      read,
    );
    return ok != null;
  }

  void delete(UParkingTariffResponse i) => confirmAction(() => UServices.parking.deleteParkingTariff(p: UIdParams(id: i.id)), read);
}
