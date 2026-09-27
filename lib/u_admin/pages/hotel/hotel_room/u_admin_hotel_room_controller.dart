part of "../../../u_admin.dart";

class UAdminHotelRoomController extends UBaseController {
  List<UHotelRoomResponse> list = <UHotelRoomResponse>[];
  UHotelResponse? hotel;

  late final TextEditingController titleFilter = fields.text();
  late final TextEditingController minPriceFilter = fields.text();
  late final TextEditingController maxPriceFilter = fields.text();

  // ---------------------------------------------------------------- form (create and edit)

  UHotelRoomResponse? editing;
  UHotelResponse? formHotel;
  late final TextEditingController title = fields.text();
  late final TextEditingController capacity = fields.text();
  late final TextEditingController price = fields.text();
  late final TextEditingController description = fields.text();
  late final TextEditingController roomNumber = fields.text();
  late final TextEditingController quantity = fields.text();
  late final TextEditingController bedType = fields.text();
  late final TextEditingController size = fields.text();
  late final TextEditingController floor = fields.text();
  late final TextEditingController extraGuestCapacity = fields.text();
  late final TextEditingController extraGuestPrice = fields.text();
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
        title: titleFilter.valueOrNull(),
        minPrice: numOf(minPriceFilter),
        maxPrice: numOf(maxPriceFilter),
        selectorArgs: const UHotelRoomSelectorArgs(hotel: UHotelSelectorArgs()),
      ),
      onOk: (UResponse<List<UHotelRoomResponse>> r) {
        list = r.result ?? <UHotelRoomResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    titleFilter.clear();
    minPriceFilter.clear();
    maxPriceFilter.clear();
    reloadFirstPage(read);
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
    title.text = r?.title ?? "";
    capacity.text = r?.capacity.toString() ?? "";
    price.text = r?.pricePerNight.toInt().toString() ?? "";
    description.text = d?.description ?? d?.detail1 ?? "";
    roomNumber.text = r?.roomNumber ?? "";
    quantity.text = (r?.quantity ?? 1).toString();
    bedType.text = d?.bedType ?? "";
    size.text = d?.sizeSquareMeters?.toInt().toString() ?? "";
    floor.text = d?.floor?.toString() ?? "";
    extraGuestCapacity.text = d?.extraGuestCapacity?.toString() ?? "";
    extraGuestPrice.text = d?.extraGuestPrice?.toInt().toString() ?? "";
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
      title: title.text.trim(),
      capacity: intOf(capacity),
      pricePerNight: numOf(price),
      hotelId: hotelId,
      roomNumber: roomNumber.text.nullIfEmpty(),
      quantity: intOf(quantity) ?? 1,
      isAvailable: isAvailable,
      description: description.text.nullIfEmpty(),
      bedType: bedType.text.nullIfEmpty(),
      sizeSquareMeters: numOf(size),
      floor: intOf(floor),
      extraGuestCapacity: intOf(extraGuestCapacity),
      extraGuestPrice: numOf(extraGuestPrice),
    );
    final dynamic ok = await submit(
      editing == null ? UServices.hotel.createHotelRoom(p: UHotelRoomCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateHotelRoom(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, hotelRoomId: editing?.id ?? ok.result);
    unawaited(read());
    return true;
  }

  void delete(UHotelRoomResponse i) => confirmAction(() => UServices.hotel.deleteHotelRoom(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    photos.dispose();
    super.dispose();
  }
}
