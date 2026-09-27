part of "../../u_admin.dart";

class UAdminHotelDormBedController extends UAdminBaseController {
  List<UDormBedResponse> list = <UDormBedResponse>[];
  UDormRoomResponse? room;
  UDormResponse? dorm;
  final TextEditingController titleFilterController = TextEditingController();

  // ---------------------------------------------------------------- form (create and edit)

  UDormBedResponse? editing;
  UDormRoomResponse? formRoom;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<int> tags = <int>[];
  List<UMediaResponse> media = <UMediaResponse>[];
  UFilePickerController photos = UFilePickerController();

  void init({UDormRoomResponse? room, UDormResponse? dorm}) {
    this.room = room;
    this.dorm = dorm;
    read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readDormBeds(
      p: UDormBedReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        roomId: room?.id,
        dormId: dorm?.id,
        title: titleFilterController.valueOrNull(),
        selectorArgs: const UDormBedSelectorArgs(contract: UDormBedContractSelectorArgs(), room: UDormRoomSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormBedResponse>> r) {
        list = r.result ?? <UDormBedResponse>[];
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

  /// A bed is free when none of its contracts is active.
  bool isFree(UDormBedResponse i) => !(i.contracts?.any((UDormBedContractResponse c) => c.isActive) ?? false);

  Future<List<UDormRoomResponse>> searchRooms(String query) async =>
      (await UServices.hotel.readDormRooms(
        p: UDormRoomReadParams(title: query, dormId: dorm?.id, pageSize: 100, pageNumber: 1),
      )).$1?.result ??
      <UDormRoomResponse>[];

  /// Fills the form: empty for [item] == null, otherwise with the full bed (photos included).
  Future<void> loadForm(UDormBedResponse? item) async {
    final UDormBedResponse? b = item == null
        ? null
        : (await UServices.hotel.readDormBedById(
                p: UIdParams(
                  id: item.id,
                  selectorArgs: const UDormBedSelectorArgs(media: UMediaSelectorArgs()),
                ),
              )).$1?.result ??
              item;
    editing = b;
    formRoom = b?.room ?? item?.room ?? room;
    titleController.text = b?.title ?? "";
    depositController.text = b?.deposit.toInt().toString() ?? "";
    rentController.text = b?.monthlyRent.toInt().toString() ?? "";
    descriptionController.text = b?.jsonData.description ?? b?.jsonData.detail1 ?? "";
    tags = List<int>.from(b?.tags ?? <int>[TagDormBed.single.number]);
    media = (b?.media ?? <UMediaResponse>[]).sortedForGallery();
    photos.dispose();
    photos = UFilePickerController.fromMedia(media);
  }

  /// Creates or updates the bed, then saves its photos. Returns true when the dialog can close.
  Future<bool> save() async {
    final String? roomId = formRoom?.id ?? editing?.roomId;
    if (roomId == null) {
      UToast.error(message: U.s.pleaseSelectAItem(U.s.room));
      return false;
    }
    final UDormBedUpdateParams p = UDormBedUpdateParams(
      id: editing?.id ?? "",
      tags: tags,
      title: titleController.text.trim(),
      deposit: numOf(depositController),
      monthlyRent: numOf(rentController),
      roomId: roomId,
      description: descriptionController.text.nullIfEmpty(),
    );
    final Object? ok = await submit(
      editing == null ? UServices.hotel.createDormBed(p: UDormBedCreateParams.fromMap(p.toMap()..remove("id"))) : UServices.hotel.updateDormBed(p: p),
      () {},
    );
    if (ok == null) return false;
    await UServices.media.syncGallery(photos, existing: media, dormBedId: editing?.id ?? (ok as UResponse<String>).result);
    unawaited(read());
    return true;
  }

  void delete(UDormBedResponse i) => confirmAction(() => UServices.hotel.deleteDormBed(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    titleController.dispose();
    depositController.dispose();
    rentController.dispose();
    descriptionController.dispose();
    photos.dispose();
    super.dispose();
  }
}
