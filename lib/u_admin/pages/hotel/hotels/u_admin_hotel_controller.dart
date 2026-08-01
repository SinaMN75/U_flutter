part of "../../../u_admin.dart";

class UAdminHotelController extends UBaseController {
  List<UHotelResponse> list = <UHotelResponse>[];
  final GlobalKey<FormState> filterFormKey = GlobalKey<FormState>();

  final TextEditingController titleFilter = TextEditingController();
  UProvince cityFilter = UCountries.iran().provinces.first;
  UCountry countryFilter = UCountries.iran();

  Future<void> init() async {
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.hotel.readHotels(
      p: UHotelReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.valueOrNull(),
      ),
      onOk: (UResponse<List<UHotelResponse>> r) {
        list = r.result ?? <UHotelResponse>[];
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

  void create({required UHotelCreateParams p}) => UServices.hotel.createHotel(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UHotelUpdateParams p}) => UServices.hotel.updateHotel(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UHotelResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.hotel.deleteHotel(
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
}
