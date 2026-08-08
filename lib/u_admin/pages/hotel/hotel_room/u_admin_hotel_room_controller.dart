part of "../../../u_admin.dart";

class UAdminHotelRoomController extends UBaseController {
  List<UHotelRoomResponse> list = <UHotelRoomResponse>[];
  UHotelResponse? hotel;

  final TextEditingController titleFilter = TextEditingController();
  final TextEditingController minPriceFilter = TextEditingController();
  final TextEditingController maxPriceFilter = TextEditingController();

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
        minPrice: minPriceFilter.isNullOrEmpty() ? null : minPriceFilter.numDouble(),
        maxPrice: maxPriceFilter.isNullOrEmpty() ? null : maxPriceFilter.numDouble(),
        selectorArgs: const HotelRoomSelectorArgs(hotel: HotelSelectorArgs()),
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

  void create({required UHotelRoomCreateParams p}) => UServices.hotel.createHotelRoom(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UHotelRoomUpdateParams p}) => UServices.hotel.updateHotelRoom(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UHotelRoomResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteHotelRoom(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );

  Future<List<UHotelResponse>> readHotels(String query) async {
    final List<UHotelResponse> result = <UHotelResponse>[];
    await UServices.hotel.readHotels(
      p: UHotelReadParams(title: query, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UHotelResponse>> r) => result.addAll(r.result ?? <UHotelResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }
}
