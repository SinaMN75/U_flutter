part of "../../u_admin.dart";

class UAdminParkingSubscriptionController extends UAdminBaseController {
  List<UParkingSubscriptionResponse> list = <UParkingSubscriptionResponse>[];
  UParkingResponse? parking;
  bool isActive = true;
  final TextEditingController queryController = TextEditingController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
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
        query: queryController.trimmedLatin().nullIfEmpty(),
        isActive: isActive ? true : null,
        isExpired: isActive ? null : true,
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        selectorArgs: const UParkingSubscriptionSelectorArgs(vehicle: UVehicleSelectorArgs(), creator: UUserSelectorArgs()),
      ),
      onOk: (UResponse<List<UParkingSubscriptionResponse>> r) {
        list = r.result ?? <UParkingSubscriptionResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    queryController.clear();
    isActive = true;
    pageNumber(1);
    read();
  }

  void loadForm() {
    nameController.clear();
    phoneController.clear();
    priceController.clear();
    plate = "";
    vehicleType = TagVehicle.car;
    duration = TagParkingSubscription.monthly;
  }

  Future<bool> save() async {
    if (plate.length < 6) return false;
    return await submit(
      UServices.parking.createParkingSubscription(
        p: UParkingSubscriptionCreateParams(
          parkingId: parking?.id ?? "",
          licencePlate: plate,
          vehicleType: vehicleType.number,
          tags: <int>[duration.number],
          customerName: nameController.text.nullIfEmpty(),
          customerPhoneNumber: phoneController.trimmedLatin().nullIfEmpty(),
          price: numOf(priceController) ?? 0,
        ),
      ),
      read,
    ) !=
        null;
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
    queryController.dispose();
    nameController.dispose();
    phoneController.dispose();
    priceController.dispose();
    super.dispose();
  }
}
