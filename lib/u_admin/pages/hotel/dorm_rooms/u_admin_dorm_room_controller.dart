part of "../../../u_admin.dart";

class UAdminDormRoomController extends UBaseController {
  List<UDormRoomResponse> list = <UDormRoomResponse>[];
  UDormResponse? dorm;
  late final TextEditingController titleFilter = fields.text();

  // ---------------------------------------------------------------- form (create and edit)

  UDormRoomResponse? editing;
  UDormResponse? formDorm;
  late final TextEditingController title = fields.text();
  late final TextEditingController description = fields.text();
  late final TextEditingController capacity = fields.text();
  late final TextEditingController floor = fields.text();
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
        title: titleFilter.valueOrNull(),
        selectorArgs: const UDormRoomSelectorArgs(dorm: UDormSelectorArgs(), beds: UDormBedSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormRoomResponse>> r) {
        list = r.result ?? <UDormRoomResponse>[];
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
    reloadFirstPage(read);
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
    title.text = r?.title ?? "";
    description.text = r?.jsonData.description ?? "";
    capacity.text = r?.capacity.toString() ?? "";
    floor.text = r?.jsonData.floor?.toString() ?? "";
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
      title: title.text.trim(),
      dormId: dormId,
      description: description.text.nullIfEmpty(),
      capacity: intOf(capacity) ?? 0,
      floor: intOf(floor),
    );
    final dynamic ok = await submit(
      editing == null ? UServices.hotel.createDormRoom(p: UDormRoomCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateDormRoom(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, dormRoomId: editing?.id ?? ok.result);
    unawaited(read());
    return true;
  }

  void delete(UDormRoomResponse i) => confirmAction(() => UServices.hotel.deleteDormRoom(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    photos.dispose();
    super.dispose();
  }
}
