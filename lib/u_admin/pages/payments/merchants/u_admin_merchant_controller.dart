part of "../../../u_admin.dart";

class UAdminMerchantController extends UBaseController {
  List<UMerchantResponse> list = <UMerchantResponse>[];

  final Rxn<UBusinessCategory> businessCategory = Rxn<UBusinessCategory>();
  final Rxn<UProvince> selectedProvince = Rxn<UProvince>();
  final Rxn<UCity> selectedCity = Rxn<UCity>();
  final Rxn<UUserResponse> user = Rxn<UUserResponse>();

  final TextEditingController titleFilter = TextEditingController();
  final TextEditingController nationalCodeFilter = TextEditingController();
  final TextEditingController phoneNumberFilter = TextEditingController();
  final TextEditingController zipCodeFilter = TextEditingController();
  final TextEditingController landlineFilter = TextEditingController();
  final TextEditingController merchantIdFilter = TextEditingController();
  final TextEditingController bankAccountIdFilter = TextEditingController();
  final TextEditingController fromCreatedController = TextEditingController();
  final TextEditingController toCreatedController = TextEditingController();

  Future<void> init({UUserResponse? user}) {
    if (user != null) this.user.value = user;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.merchant.read(
      p: UMerchantReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        nationalCode: nationalCodeFilter.text.nullIfEmpty(),
        phoneNumber: phoneNumberFilter.text.nullIfEmpty(),
        mcc: businessCategory.value?.code,
        cityCode: selectedCity.value?.code,
        zipCode: zipCodeFilter.text.nullIfEmpty(),
        landline: landlineFilter.text.nullIfEmpty(),
        merchantId: merchantIdFilter.text.nullIfEmpty(),
        userId: user.value?.id,
        bankAccountId: bankAccountIdFilter.text.nullIfEmpty(),
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
      ),
      onOk: (UResponse<List<UMerchantResponse>> r) {
        list = r.result ?? <UMerchantResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    titleFilter.clear();
    nationalCodeFilter.clear();
    phoneNumberFilter.clear();
    businessCategory.value = null;
    selectedCity.value = null;
    selectedProvince.value = null;
    zipCodeFilter.clear();
    landlineFilter.clear();
    merchantIdFilter.clear();
    user.value = null;
    bankAccountIdFilter.clear();
    fromCreatedController.clear();
    toCreatedController.clear();
    fromCreatedAt = null;
    toCreatedAt = null;
    reloadFirstPage(read);
  }

  void create({required UMerchantCreateParams p}) {
    ULoading.show();
    UServices.merchant.create(
      p: p,
      onOk: (UResponse<String> r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        errorCallBack(U.s.errorSubmittingForm, read);
      },
    );
  }

  void delete(UMerchantResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.merchant.delete(
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

  Future<List<UUserResponse>> readUsers(String query) async {
    final List<UUserResponse> result = <UUserResponse>[];
    await UServices.user.read(
      p: UUserReadParams(query: query, pageSize: 100, pageNumber: 1),
      onOk: (UResponse<List<UUserResponse>> r) => result.addAll(r.result ?? <UUserResponse>[]),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }
}
