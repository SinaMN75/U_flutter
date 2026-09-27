part of "../../u_admin.dart";

/// Tariffs are one row per parking + vehicle type, carrying both the hourly rates and the
/// subscription prices, so the list is short and edited in place.
class UAdminParkingTariffController extends UAdminBaseController {
  List<UParkingTariffResponse> list = <UParkingTariffResponse>[];
  UParkingResponse? parking;

  String parkingId = "";
  final TextEditingController entranceController = TextEditingController();
  final TextEditingController dayHourlyController = TextEditingController();
  final TextEditingController nightHourlyController = TextEditingController();
  final TextEditingController dailyCapController = TextEditingController();
  final TextEditingController weeklyController = TextEditingController();
  final TextEditingController monthlyController = TextEditingController();
  final TextEditingController quarterlyController = TextEditingController();
  final TextEditingController freeMinutesController = TextEditingController();
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
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm(UParkingTariffResponse? t) {
    parkingId = t?.parkingId ?? parking?.id ?? "";
    entranceController.text = t?.entrancePrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    dayHourlyController.text = t?.dayHourlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    nightHourlyController.text = t?.nightHourlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    dailyCapController.text = t?.dailyCap.toStringAsSmartRound(maxPrecision: 0) ?? "";
    weeklyController.text = t?.weeklyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    monthlyController.text = t?.monthlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    quarterlyController.text = t?.quarterlyPrice.toStringAsSmartRound(maxPrecision: 0) ?? "";
    freeMinutesController.text = (t?.freeMinutes ?? 0).toString();
    vehicleType = TagVehicle.values.fromNumber(t?.vehicleType ?? TagVehicle.car.number) ?? TagVehicle.car;
    roundToFullHour = t?.roundToFullHour ?? false;
    perMinuteAfterFirstHour = t?.perMinuteAfterFirstHour ?? true;
  }

  Future<bool> save() async =>
      await submit(
        UServices.parking.createParkingTariff(
          p: UParkingTariffCreateParams(
            parkingId: parkingId,
            vehicleType: vehicleType.number,
            tags: <int>[TagParkingTariff.hourly.number, TagParkingTariff.subscription.number],
            entrancePrice: numOf(entranceController) ?? 0,
            dayHourlyPrice: numOf(dayHourlyController) ?? 0,
            nightHourlyPrice: numOf(nightHourlyController) ?? 0,
            dailyCap: numOf(dailyCapController) ?? 0,
            weeklyPrice: numOf(weeklyController) ?? 0,
            monthlyPrice: numOf(monthlyController) ?? 0,
            quarterlyPrice: numOf(quarterlyController) ?? 0,
            freeMinutes: intOf(freeMinutesController) ?? 0,
            roundToFullHour: roundToFullHour,
            perMinuteAfterFirstHour: perMinuteAfterFirstHour,
          ),
        ),
        read,
      ) !=
      null;

  void delete(UParkingTariffResponse i) => confirmAction(() => UServices.parking.deleteParkingTariff(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    entranceController.dispose();
    dayHourlyController.dispose();
    nightHourlyController.dispose();
    dailyCapController.dispose();
    weeklyController.dispose();
    monthlyController.dispose();
    quarterlyController.dispose();
    freeMinutesController.dispose();
    super.dispose();
  }
}
