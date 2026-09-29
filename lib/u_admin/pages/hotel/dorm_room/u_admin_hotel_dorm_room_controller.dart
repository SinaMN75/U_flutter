part of "../../../u_admin.dart";

class UAdminHotelDormRoomController extends UBaseController {
  List<UDormRoomResponse> list = <UDormRoomResponse>[];
  UDormResponse? dorm;
  final TextEditingController titleFilterController = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  UDormRoomResponse? editing;
  UDormResponse? formDorm;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController capacityController = TextEditingController();
  final TextEditingController floorController = TextEditingController();
  List<int> tags = <int>[];
  List<UMediaResponse> media = <UMediaResponse>[];
  UFilePickerController photos = UFilePickerController();

  void init({UDormResponse? dorm}) {
    this.dorm = dorm;
    read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormRooms(
      p: UDormRoomReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        dormId: dorm?.id,
        title: titleFilterController.valueOrNull(),
        selectorArgs: const UDormRoomSelectorArgs(dorm: UDormSelectorArgs(), beds: UDormBedSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormRoomResponse>> r) {
        list = r.result ?? <UDormRoomResponse>[];
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
    pageNumber(1);
    read();
  }

  Future<List<UDormResponse>> searchDorms(String query) async => (await UServices.hotel.readDorms(p: UDormReadParams(title: query, pageSize: 100, pageNumber: 1))).$1?.result ?? <UDormResponse>[];

  /// Fills the form: empty for [item] == null, otherwise with the full room (photos included).
  Future<void> loadForm(UDormRoomResponse? item) async {
    final UDormRoomResponse? r = item == null
        ? null
        : (await UServices.hotel.readDormRoomById(
                p: UIdParams(
                  id: item.id,
                  selectorArgs: const UDormRoomSelectorArgs(media: UMediaSelectorArgs()),
                ),
              )).$1?.result ??
              item;
    editing = r;
    formDorm = r?.dorm ?? item?.dorm ?? dorm;
    titleController.text = r?.title ?? "";
    descriptionController.text = r?.jsonData.description ?? "";
    capacityController.text = r?.capacity.toString() ?? "";
    floorController.text = r?.jsonData.floor?.toString() ?? "";
    tags = List<int>.from(r?.tags ?? <int>[TagDormRoom.dorm.number]);
    media = (r?.media ?? <UMediaResponse>[]).sortedForGallery();
    photos.dispose();
    photos = UFilePickerController.fromMedia(media);
  }

  /// Creates or updates the room, then saves its photos. Returns true when the dialog can close.
  Future<bool> save() async {
    final String? dormId = formDorm?.id ?? editing?.dormId;
    if (dormId == null) {
      UToast.error(message: U.s.pleaseSelectAItem(U.s.dorm));
      return false;
    }
    final UDormRoomUpdateParams p = UDormRoomUpdateParams(
      id: editing?.id ?? "",
      tags: tags,
      title: titleController.text.trim(),
      dormId: dormId,
      description: descriptionController.text.nullIfEmpty(),
      capacity: intOf(capacityController) ?? 0,
      floor: intOf(floorController),
    );
    final Object? ok = await send(
      editing == null ? UServices.hotel.createDormRoom(p: UDormRoomCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateDormRoom(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, dormRoomId: editing?.id ?? (ok as UResponse<String>).result);
    unawaited(read());
    return true;
  }

  void delete(UDormRoomResponse i) => confirmAction(() => UServices.hotel.deleteDormRoom(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    capacityController.dispose();
    floorController.dispose();
    photos.dispose();
    super.dispose();
  }
}
