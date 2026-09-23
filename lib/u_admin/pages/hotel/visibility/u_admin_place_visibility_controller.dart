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

  int get activeTag => isHotel ? TagHotel.active.number : TagDorm.active.number;

  int get inactiveTag => isHotel ? TagHotel.inactive.number : TagDorm.inactive.number;

  /// Hotels and dorms are shown to the public when they have the "active" tag.
  bool get visible => tags.contains(activeTag);

  bool get featured => tags.contains(featuredTag);
}

class UAdminPlaceVisibilityController extends UBaseController {
  List<UAdminPlaceRow> list = <UAdminPlaceRow>[];

  void init() => read();

  Future<void> read() async {
    state.loading();
    final List<UAdminPlaceRow> rows = <UAdminPlaceRow>[];
    bool failed = false;

    await UServices.hotel.readHotels(
      p: UHotelReadParams(pageSize: 200, selectorArgs: const UHotelSelectorArgs(media: UMediaSelectorArgs())),
      onOk: (UResponse<List<UHotelResponse>> r) => rows.addAll((r.result ?? <UHotelResponse>[]).map((UHotelResponse h) => UAdminPlaceRow(id: h.id, isHotel: true, title: h.title, cityCode: h.cityCode, tags: h.tags, coverUrl: (h.media ?? <UMediaResponse>[]).sortedForGallery().firstOrNull?.url))),
      onError: (UEmptyResponse e) => failed = true,
      onException: (String e) => failed = true,
    );
    await UServices.hotel.readDorms(
      p: UDormReadParams(pageSize: 200, selectorArgs: const UDormSelectorArgs(media: UMediaSelectorArgs())),
      onOk: (UResponse<List<UDormResponse>> r) => rows.addAll((r.result ?? <UDormResponse>[]).map((UDormResponse d) => UAdminPlaceRow(id: d.id, isHotel: false, title: d.title, cityCode: d.cityCode, tags: d.tags, coverUrl: (d.media ?? <UMediaResponse>[]).sortedForGallery().firstOrNull?.url))),
      onError: (UEmptyResponse e) => failed = true,
      onException: (String e) => failed = true,
    );

    if (failed && rows.isEmpty) return setError();
    list = rows;
    setListState(isEmpty: list.isEmpty);
  }

  /// Turns one tag of a place on or off, then reloads.
  Future<void> setTag(UAdminPlaceRow row, int tag, {required bool on}) => _update(row, add: on ? <int>[tag] : <int>[], remove: on ? <int>[] : <int>[tag]);

  /// Show / hide: "active" and "inactive" are switched together, so a place never has both.
  Future<void> setVisible(UAdminPlaceRow row, {required bool visible}) => _update(
    row,
    add: <int>[if (visible) row.activeTag else row.inactiveTag],
    remove: <int>[if (visible) row.inactiveTag else row.activeTag],
  );

  Future<void> _update(UAdminPlaceRow row, {required List<int> add, required List<int> remove}) async {
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
}
