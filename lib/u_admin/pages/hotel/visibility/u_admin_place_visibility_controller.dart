part of "../../../u_admin.dart";

/// One hotel or dorm row of the "Featured, verified & visibility" page.
class UAdminPlaceRow {
  UAdminPlaceRow({required this.id, required this.isHotel, required this.title, required this.cityCode, required this.tags, required this.coverUrl});

  final String id;
  final bool isHotel;
  final String title;
  final String cityCode;
  final List<int> tags;
  final String? coverUrl;

  int get featuredTag => isHotel ? TagHotel.featured.number : TagDorm.featured.number;

  int get verifiedTag => isHotel ? TagHotel.verified.number : TagDorm.verified.number;

  /// Hotels are shown when they have the "active" tag; dorms are shown unless they have the "inactive" tag.
  bool get visible => isHotel ? tags.contains(TagHotel.active.number) : !tags.contains(TagDorm.inactive.number);

  bool get featured => tags.contains(featuredTag);

  bool get verified => tags.contains(verifiedTag);
}

class UAdminPlaceVisibilityController extends UBaseController {
  List<UAdminPlaceRow> list = <UAdminPlaceRow>[];

  void init() => read();

  Future<void> read() async {
    state.loading();
    final List<UAdminPlaceRow> rows = <UAdminPlaceRow>[];
    bool failed = false;

    await UServices.hotel.readHotels(
      p: UHotelReadParams(pageSize: 200, selectorArgs: const HotelSelectorArgs(media: MediaSelectorArgs())),
      onOk: (UResponse<List<UHotelResponse>> r) => rows.addAll((r.result ?? <UHotelResponse>[]).map((UHotelResponse h) => UAdminPlaceRow(id: h.id, isHotel: true, title: h.title, cityCode: h.cityCode, tags: h.tags, coverUrl: (h.media ?? <UMediaResponse>[]).sortedForGallery().firstOrNull?.url))),
      onError: (UEmptyResponse e) => failed = true,
      onException: (String e) => failed = true,
    );
    await UServices.hotel.readDorms(
      p: UDormReadParams(pageSize: 200, selectorArgs: const DormSelectorArgs(media: MediaSelectorArgs())),
      onOk: (UResponse<List<UDormResponse>> r) => rows.addAll((r.result ?? <UDormResponse>[]).map((UDormResponse d) => UAdminPlaceRow(id: d.id, isHotel: false, title: d.title, cityCode: d.cityCode, tags: d.tags, coverUrl: (d.media ?? <UMediaResponse>[]).sortedForGallery().firstOrNull?.url))),
      onError: (UEmptyResponse e) => failed = true,
      onException: (String e) => failed = true,
    );

    if (failed && rows.isEmpty) return setError();
    list = rows;
    setListState(isEmpty: list.isEmpty);
  }

  /// Turns one tag of a place on or off, then reloads.
  Future<void> setTag(UAdminPlaceRow row, int tag, {required bool on}) async {
    final List<int> add = on ? <int>[tag] : <int>[];
    final List<int> remove = on ? <int>[] : <int>[tag];
    if (row.isHotel) {
      await UServices.hotel.updateHotel(
        p: UHotelUpdateParams(id: row.id, addTags: add, removeTags: remove),
        onOk: (UEmptyResponse r) => read(),
        onError: (UEmptyResponse r) => errorCallBack(r.message, read),
        onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
      );
    } else {
      await UServices.hotel.updateDorm(
        p: UDormUpdateParams(id: row.id, addTags: add, removeTags: remove),
        onOk: (UEmptyResponse r) => read(),
        onError: (UEmptyResponse r) => errorCallBack(r.message, read),
        onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
      );
    }
  }

  /// Show / hide: hotels use the "active" tag, dorms use the "inactive" tag.
  Future<void> setVisible(UAdminPlaceRow row, {required bool visible}) => row.isHotel
      ? setTag(row, TagHotel.active.number, on: visible)
      : setTag(row, TagDorm.inactive.number, on: !visible);
}
