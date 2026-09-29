part of "../../../u_admin.dart";

class UAdminHotelRoomController extends UBaseController {
  List<UHotelRoomResponse> list = <UHotelRoomResponse>[];
  UHotelResponse? hotel;

  final TextEditingController titleFilterController = TextEditingController();
  final TextEditingController minPriceFilterController = TextEditingController();
  final TextEditingController maxPriceFilterController = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  UHotelRoomResponse? editing;
  UHotelResponse? formHotel;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController roomNumberController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController bedTypeController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  final TextEditingController extraGuestCapacityController = TextEditingController();
  final TextEditingController extraGuestPriceController = TextEditingController();
  bool isAvailable = true;
  List<int> tags = <int>[];
  List<UMediaResponse> media = <UMediaResponse>[];
  UFilePickerController photos = UFilePickerController();

  void init({UHotelResponse? hotel}) {
    this.hotel = hotel;
    read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readHotelRooms(
      p: UHotelRoomReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        hotelId: hotel?.id,
        title: titleFilterController.valueOrNull(),
        minPrice: numOf(minPriceFilterController),
        maxPrice: numOf(maxPriceFilterController),
        selectorArgs: const UHotelRoomSelectorArgs(hotel: UHotelSelectorArgs()),
      ),
      onOk: (UResponse<List<UHotelRoomResponse>> r) {
        list = r.result ?? <UHotelRoomResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    titleFilterController.clear();
    minPriceFilterController.clear();
    maxPriceFilterController.clear();
    pageNumber(1);
    read();
  }

  Future<List<UHotelResponse>> searchHotels(String query) async => (await UServices.hotel.readHotels(p: UHotelReadParams(title: query, pageSize: 100, pageNumber: 1))).$1?.result ?? <UHotelResponse>[];

  /// Fills the form: empty for [item] == null, otherwise with the full room (photos included).
  Future<void> loadForm(UHotelRoomResponse? item) async {
    final UHotelRoomResponse? r = item == null
        ? null
        : (await UServices.hotel.readHotelRoomById(
                p: UIdParams(
                  id: item.id,
                  selectorArgs: const UHotelRoomSelectorArgs(media: UMediaSelectorArgs()),
                ),
              )).$1?.result ??
              item;
    final UHotelRoomJson? d = r?.jsonData;
    editing = r;
    formHotel = r?.hotel ?? item?.hotel ?? hotel;
    titleController.text = r?.title ?? "";
    capacityController.text = r?.capacity.toString() ?? "";
    priceController.text = r?.pricePerNight.toInt().toString() ?? "";
    descriptionController.text = d?.description ?? d?.detail1 ?? "";
    roomNumberController.text = r?.roomNumber ?? "";
    quantityController.text = (r?.quantity ?? 1).toString();
    bedTypeController.text = d?.bedType ?? "";
    sizeController.text = d?.sizeSquareMeters?.toInt().toString() ?? "";
    floorController.text = d?.floor?.toString() ?? "";
    extraGuestCapacityController.text = d?.extraGuestCapacity?.toString() ?? "";
    extraGuestPriceController.text = d?.extraGuestPrice?.toInt().toString() ?? "";
    isAvailable = r?.isAvailable ?? true;
    tags = List<int>.from(r?.tags ?? <int>[TagRoom.double_.number]);
    media = (r?.media ?? <UMediaResponse>[]).sortedForGallery();
    photos.dispose();
    photos = UFilePickerController.fromMedia(media);
  }

  /// Creates or updates the room, then saves its photos. Returns true when the dialog can close.
  Future<bool> save() async {
    final String? hotelId = formHotel?.id ?? editing?.hotelId;
    if (hotelId == null) {
      UToast.error(message: U.s.pleaseSelectAItem(U.s.hotel));
      return false;
    }
    final UHotelRoomUpdateParams p = UHotelRoomUpdateParams(
      id: editing?.id ?? "",
      tags: tags,
      title: titleController.text.trim(),
      capacity: intOf(capacityController),
      pricePerNight: numOf(priceController),
      hotelId: hotelId,
      roomNumber: roomNumberController.text.nullIfEmpty(),
      quantity: intOf(quantityController) ?? 1,
      isAvailable: isAvailable,
      description: descriptionController.text.nullIfEmpty(),
      bedType: bedTypeController.text.nullIfEmpty(),
      sizeSquareMeters: numOf(sizeController),
      floor: intOf(floorController),
      extraGuestCapacity: intOf(extraGuestCapacityController),
      extraGuestPrice: numOf(extraGuestPriceController),
    );
    final Object? ok = await send(
      editing == null ? UServices.hotel.createHotelRoom(p: UHotelRoomCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateHotelRoom(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, hotelRoomId: editing?.id ?? (ok as UResponse<String>).result);
    unawaited(read());
    return true;
  }

  void delete(UHotelRoomResponse i) => confirmAction(() => UServices.hotel.deleteHotelRoom(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    minPriceFilterController.dispose();
    maxPriceFilterController.dispose();
    titleController.dispose();
    capacityController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    roomNumberController.dispose();
    quantityController.dispose();
    bedTypeController.dispose();
    sizeController.dispose();
    floorController.dispose();
    extraGuestCapacityController.dispose();
    extraGuestPriceController.dispose();
    photos.dispose();
    super.dispose();
  }
}
