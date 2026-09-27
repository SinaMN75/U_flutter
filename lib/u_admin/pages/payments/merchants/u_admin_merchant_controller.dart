part of "../../../u_admin.dart";

class UAdminMerchantController extends UBaseController {
  List<UMerchantResponse> list = <UMerchantResponse>[];

  UUserResponse? user;
  UBusinessCategory? businessCategory;
  UProvince? province;
  UCity? city;
  late final TextEditingController titleFilter = fields.text();
  late final TextEditingController nationalCodeFilter = fields.text();
  late final TextEditingController phoneNumberFilter = fields.text();
  late final TextEditingController zipCodeFilter = fields.text();
  late final TextEditingController landlineFilter = fields.text();
  late final TextEditingController merchantIdFilter = fields.text();
  late final TextEditingController bankAccountIdFilter = fields.text();

  late final TextEditingController title = fields.text();
  late final TextEditingController businessTitle = fields.text();
  late final TextEditingController nationalCode = fields.text();
  late final TextEditingController phoneNumber = fields.text();
  late final TextEditingController landline = fields.text();
  late final TextEditingController zipCode = fields.text();
  late final TextEditingController cityCode = fields.text();
  late final TextEditingController mcc = fields.text();
  late final TextEditingController address = fields.text();
  late final TextEditingController ownerName = fields.text();
  late final TextEditingController ownerPhoneNumber = fields.text();

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
        title: titleFilter.text.nullIfEmpty(),
        nationalCode: nationalCodeFilter.text.nullIfEmpty(),
        phoneNumber: phoneNumberFilter.text.nullIfEmpty(),
        mcc: businessCategory?.code,
        cityCode: city?.code,
        zipCode: zipCodeFilter.text.nullIfEmpty(),
        landline: landlineFilter.text.nullIfEmpty(),
        merchantId: merchantIdFilter.text.nullIfEmpty(),
        userId: user?.id,
        bankAccountId: bankAccountIdFilter.text.nullIfEmpty(),
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
      ),
      onOk: (UResponse<List<UMerchantResponse>> r) {
        list = r.result ?? <UMerchantResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    for (final TextEditingController t in <TextEditingController>[
      titleFilter,
      nationalCodeFilter,
      phoneNumberFilter,
      zipCodeFilter,
      landlineFilter,
      merchantIdFilter,
      bankAccountIdFilter,
    ]) {
      t.clear();
    }
    user = null;
    businessCategory = null;
    province = null;
    city = null;
    clearDates();
    reloadFirstPage(read);
  }

  void loadForm() {
    for (final TextEditingController t in <TextEditingController>[
      title,
      businessTitle,
      nationalCode,
      phoneNumber,
      landline,
      zipCode,
      cityCode,
      mcc,
      address,
      ownerName,
      ownerPhoneNumber,
    ]) {
      t.clear();
    }
  }

  Future<bool> save() async {
    final dynamic ok = await submit(
      UServices.merchant.create(
        p: UMerchantCreateParams(
          tags: <int>[TagMerchant.normal.number],
          title: title.text,
          businessTitle: businessTitle.text.nullIfEmpty(),
          nationalCode: nationalCode.numString(),
          phoneNumber: phoneNumber.trimmedLatin(),
          landline: landline.trimmedLatin(),
          zipCode: zipCode.numString(),
          cityCode: cityCode.numString(),
          mcc: mcc.numString(),
          ownerName: ownerName.text,
          ownerPhoneNumber: ownerPhoneNumber.trimmedLatin(),
          address: address.text,
        ),
      ),
      read,
    );
    return ok != null;
  }

  void delete(UMerchantResponse i) => confirmAction(() => UServices.merchant.delete(p: UIdParams(id: i.id)), read);
}
