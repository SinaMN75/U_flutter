part of "../../u_admin.dart";

class UAdminPaymentMerchantController extends UBaseController {
  List<UMerchantResponse> list = <UMerchantResponse>[];

  UUserResponse? user;
  UBusinessCategory? businessCategory;
  UProvince? province;
  UCity? city;
  final TextEditingController titleFilterController = TextEditingController();
  final TextEditingController nationalCodeFilterController = TextEditingController();
  final TextEditingController phoneNumberFilterController = TextEditingController();
  final TextEditingController zipCodeFilterController = TextEditingController();
  final TextEditingController landlineFilterController = TextEditingController();
  final TextEditingController merchantIdFilterController = TextEditingController();
  final TextEditingController bankAccountIdFilterController = TextEditingController();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController businessTitleController = TextEditingController();
  final TextEditingController nationalCodeController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController landlineController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController cityCodeController = TextEditingController();
  final TextEditingController mccController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerPhoneNumberController = TextEditingController();

  Future<void> init({UUserResponse? user}) {
    this.user = user;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.merchant.read(
      p: UMerchantReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilterController.text.nullIfEmpty(),
        nationalCode: nationalCodeFilterController.text.nullIfEmpty(),
        phoneNumber: phoneNumberFilterController.text.nullIfEmpty(),
        mcc: businessCategory?.code,
        cityCode: city?.code,
        zipCode: zipCodeFilterController.text.nullIfEmpty(),
        landline: landlineFilterController.text.nullIfEmpty(),
        merchantId: merchantIdFilterController.text.nullIfEmpty(),
        userId: user?.id,
        bankAccountId: bankAccountIdFilterController.text.nullIfEmpty(),
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
      ),
      onOk: (UResponse<List<UMerchantResponse>> r) {
        list = r.result ?? <UMerchantResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    for (final TextEditingController t in <TextEditingController>[
      titleFilterController,
      nationalCodeFilterController,
      phoneNumberFilterController,
      zipCodeFilterController,
      landlineFilterController,
      merchantIdFilterController,
      bankAccountIdFilterController,
    ]) {
      t.clear();
    }
    user = null;
    businessCategory = null;
    province = null;
    city = null;
    clearDates();
    pageNumber(1);
    read();
  }

  void loadForm() {
    for (final TextEditingController t in <TextEditingController>[
      titleController,
      businessTitleController,
      nationalCodeController,
      phoneNumberController,
      landlineController,
      zipCodeController,
      cityCodeController,
      mccController,
      addressController,
      ownerNameController,
      ownerPhoneNumberController,
    ]) {
      t.clear();
    }
  }

  Future<bool> save() async =>
      await submit(
        UServices.merchant.create(
          p: UMerchantCreateParams(
            tags: <int>[TagMerchant.normal.number],
            title: titleController.text,
            businessTitle: businessTitleController.text.nullIfEmpty(),
            nationalCode: nationalCodeController.numString(),
            phoneNumber: phoneNumberController.trimmedLatin(),
            landline: landlineController.trimmedLatin(),
            zipCode: zipCodeController.numString(),
            cityCode: cityCodeController.numString(),
            mcc: mccController.numString(),
            ownerName: ownerNameController.text,
            ownerPhoneNumber: ownerPhoneNumberController.trimmedLatin(),
            address: addressController.text,
          ),
        ),
        read,
      ) !=
      null;

  void delete(UMerchantResponse i) => confirmAction(() => UServices.merchant.delete(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    nationalCodeFilterController.dispose();
    phoneNumberFilterController.dispose();
    zipCodeFilterController.dispose();
    landlineFilterController.dispose();
    merchantIdFilterController.dispose();
    bankAccountIdFilterController.dispose();
    titleController.dispose();
    businessTitleController.dispose();
    nationalCodeController.dispose();
    phoneNumberController.dispose();
    landlineController.dispose();
    zipCodeController.dispose();
    cityCodeController.dispose();
    mccController.dispose();
    addressController.dispose();
    ownerNameController.dispose();
    ownerPhoneNumberController.dispose();
    super.dispose();
  }
}
