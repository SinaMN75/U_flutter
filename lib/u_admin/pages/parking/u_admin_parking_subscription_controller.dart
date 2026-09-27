part of "../../u_admin.dart";

class UAdminParkingSubscriptionController extends UBaseController {
  List<UParkingSubscriptionResponse> list = <UParkingSubscriptionResponse>[];
  UParkingResponse? parking;
  final URxnBool isActive = URxnBool(true);
  final TextEditingController controllerQuery = TextEditingController();

  late final TextEditingController name = fields.text();
  late final TextEditingController phone = fields.text();
  late final TextEditingController price = fields.text();
  String plate = "";
  TagVehicle vehicleType = TagVehicle.car;
  TagParkingSubscription duration = TagParkingSubscription.monthly;

  Future<void> init({UParkingResponse? parking}) {
    this.parking = parking;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.parking.readParkingSubscription(
      p: UParkingSubscriptionReadParams(
        parkingId: parking?.id,
        query: controllerQuery.trimmedLatin().nullIfEmpty(),
        isActive: isActive.value == true ? true : null,
        isExpired: isActive.value == false ? true : null,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingSubscriptionSelectorArgs(vehicle: UVehicleSelectorArgs(), creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingSubscriptionResponse>> r) {
        list = r.result ?? <UParkingSubscriptionResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void loadForm() {
    name.clear();
    phone.clear();
    price.clear();
    plate = "";
    vehicleType = TagVehicle.car;
    duration = TagParkingSubscription.monthly;
  }

  Future<bool> save() async {
    if (plate.length < 6) return false;
    final dynamic ok = await submit(
      UServices.parking.createParkingSubscription(
        p: UParkingSubscriptionCreateParams(
          parkingId: parking?.id ?? "",
          licencePlate: plate,
          vehicleType: vehicleType.number,
          tags: <int>[duration.number],
          customerName: name.text.nullIfEmpty(),
          customerPhoneNumber: phone.trimmedLatin().nullIfEmpty(),
          price: numOf(price) ?? 0,
        ),
      ),
      read,
    );
    return ok != null;
  }

  void renew(UParkingSubscriptionResponse i) {
    final TagParkingSubscription d = TagParkingSubscription.values.firstWhereOrNull((TagParkingSubscription t) => i.tags.contains(t.number)) ?? TagParkingSubscription.monthly;
    final int days = switch (d) {
      TagParkingSubscription.weekly => 7,
      TagParkingSubscription.quarterly => 90,
      _ => 30,
    };
    final DateTime base = i.expiryDate.isAfter(DateTime.now()) ? i.expiryDate : DateTime.now();
    submit(UServices.parking.updateParkingSubscription(p: UParkingSubscriptionUpdateParams(id: i.id, expiryDate: base.add(Duration(days: days)))), read);
  }

  void delete(UParkingSubscriptionResponse i) => confirmAction(() => UServices.parking.deleteParkingSubscription(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    controllerQuery.dispose();
    isActive.dispose();
    super.dispose();
  }
}
