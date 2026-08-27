import "package:u/utilities.dart";

class UAdminMerchantsPage extends StatefulWidget {
  const UAdminMerchantsPage({super.key, this.user, this.actions});

  final UUserResponse? user;
  final UAdminActionBuilder<UMerchantResponse>? actions;

  @override
  State<UAdminMerchantsPage> createState() => _MerchantsPageState();
}

class _MerchantsPageState extends State<UAdminMerchantsPage> {
  final UAdminMerchantController c = UAdminMerchantController();

  @override
  void initState() {
    c.init(user: widget.user);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.merchantsManagement,
    onFilter: _showFilterDialog,
    onCreate: _showCreateDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  Widget _list() => UAdminListView<UMerchantResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.merchant),
    desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.nationalCode, U.s.phoneNumber, U.s.mcc, U.s.merchantId, U.s.createdAt, U.s.operations]),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _itemDesktop(UMerchantResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.nationalCode),
      UAdminTable.cell(i.phoneNumber),
      UAdminTable.cell(BusinessCategories.categories.firstWhereOrNull((UBusinessCategory j) => j.code == i.mcc)?.localizedName() ?? i.mcc),
      UAdminTable.cell(i.merchantId ?? U.s.unassigned),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UMerchantResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.storefront_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.nationalCode, i.nationalCode),
      UAdminField(U.s.phoneNumber, i.phoneNumber),
      UAdminField(U.s.mcc, BusinessCategories.categories.firstWhereOrNull((UBusinessCategory j) => j.code == i.mcc)?.localizedName() ?? i.mcc),
      UAdminField(U.s.merchantId, i.merchantId ?? U.s.unassigned),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  // Built-in operations; the app can override them via UAdminMerchantsPage(actions: ...).
  Widget _menu(UMerchantResponse i) => UAdminOps.menu<UMerchantResponse>(
    context,
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UMerchantResponse>(onDelete: c.delete, onDetail: _showDetailDialog),
    fallback: (UAdminActionContext<UMerchantResponse> ctx) => <UAdminAction>[
      UAdminLinks.merchantTerminals(ctx.item),
      ctx.detail(),
      ctx.delete(),
    ],
  );

  void _showDetailDialog(UMerchantResponse i) => UNavigator.dialog(
    AlertDialog(
      title: Text(i.title),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _kv(U.s.businessTitle, i.jsonData.businessTitle ?? "-"),
              _kv(U.s.ownerName, i.jsonData.ownerName ?? "-"),
              _kv(U.s.ownerPhoneNumber, i.jsonData.ownerPhoneNumber ?? "-"),
              _kv(U.s.nationalCode, i.nationalCode),
              _kv(U.s.phoneNumber, i.phoneNumber),
              _kv(U.s.landline, i.landline),
              _kv(U.s.zipCode, i.zipCode),
              _kv(U.s.cityCode, i.cityCode),
              _kv(U.s.mcc, i.mcc),
              _kv(U.s.address, i.jsonData.address ?? "-"),
              _kv(U.s.merchantId, i.merchantId ?? U.s.unassigned),
              _kv(U.s.institutionId, i.insId ?? U.s.unassigned),
              UButton(type: UButtonType.text, title: U.s.ok, onTap: UNavigator.back),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _kv(String k, String v) => URow(
    crossAxisAlignment: CrossAxisAlignment.start,
    margin: const EdgeInsets.symmetric(vertical: 6),
    children: <Widget>[
      SizedBox(width: 130, child: UTextBodySmall(k, color: UAdminTheme.grey)),
      Expanded(child: UTextBodyMedium(v, fontWeight: FontWeight.w500)),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.merchant)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextFieldAutoCompleteAsync<UUserResponse>(
                labelBuilder: (UUserResponse i) => "${i.firstName} ${i.lastName} ${i.nationalCode}",
                onChanged: c.user.call,
                selectedItem: c.user.value,
                fetchData: c.readUsers,
                hintText: U.s.user,
              ).pSymmetric(vertical: 6),
              Obx(
                () => UTextFieldAutoComplete<UBusinessCategory?>(
                  items: BusinessCategories.categories,
                  labelBuilder: (UBusinessCategory? i) => i?.localizedName() ?? i?.code ?? "",
                  onChanged: c.businessCategory.call,
                  selectedItem: c.businessCategory.value,
                  hintText: U.s.businessTitle,
                ),
              ).pSymmetric(vertical: 6),
              URow(
                margin: const EdgeInsets.symmetric(vertical: 6),
                children: <Widget>[
                  Obx(
                    () => UTextFieldAutoComplete<UProvince?>(
                      title: U.s.province,
                      items: UCountries.iranProvinces,
                      labelBuilder: (UProvince? i) => i?.nameFa ?? "",
                      selectedItem: c.selectedProvince.value,
                      onChanged: (UProvince? i) {
                        c.selectedProvince(i);
                        c.selectedCity(i!.cities.first);
                      },
                    ),
                  ).expanded(),
                  const SizedBox(width: 8),
                  Obx(
                    () => UTextFieldAutoComplete<UCity?>(
                      title: U.s.city,
                      items: c.selectedProvince.value?.cities ?? <UCity>[],
                      labelBuilder: (UCity? i) => i?.nameFa ?? "",
                      selectedItem: c.selectedCity.value,
                      onChanged: c.selectedCity.call,
                    ),
                  ).expanded(),
                ],
              ),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.fromCreatedController,
                labelText: U.s.fromDate,
                onChange: (DateTime d, Jalali j) {
                  c.fromCreatedController.text = j.formatCompactDate();
                  c.fromCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.toCreatedController,
                labelText: U.s.toDate,
                onChange: (DateTime d, Jalali j) {
                  c.toCreatedController.text = j.formatCompactDate();
                  c.toCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextField(controller: c.titleFilter, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.nationalCodeFilter, labelText: U.s.nationalCode, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.phoneNumberFilter, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.landlineFilter, labelText: U.s.landline, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.zipCodeFilter, labelText: U.s.zipCode, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.merchantIdFilter, labelText: U.s.merchantId, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.bankAccountIdFilter, labelText: U.s.bankAccountid, margin: const EdgeInsets.symmetric(vertical: 6)),
              const SizedBox(height: 20),
              UButtonSubmitCancel(
                submitTitle: U.s.filter,
                cancelTitle: U.s.clearFilters,
                onSubmit: () {
                  c.applyFilters();
                  UNavigator.back();
                },
                onCancel: () {
                  c.clearFilters();
                  UNavigator.back();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _showCreateDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController();
    final TextEditingController businessTitle = TextEditingController();
    final TextEditingController nationalCode = TextEditingController();
    final TextEditingController phoneNumber = TextEditingController();
    final TextEditingController landline = TextEditingController();
    final TextEditingController zipCode = TextEditingController();
    final TextEditingController cityCode = TextEditingController();
    final TextEditingController mcc = TextEditingController();
    final TextEditingController address = TextEditingController();
    final TextEditingController ownerName = TextEditingController();
    final TextEditingController ownerPhoneNumber = TextEditingController();

    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.createItem(U.s.merchant)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: title,
                    labelText: U.s.title,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(controller: businessTitle, labelText: U.s.businessTitle, margin: const EdgeInsets.symmetric(vertical: 6)),
                  UTextField(
                    controller: nationalCode,
                    labelText: U.s.nationalCode,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: phoneNumber,
                    labelText: U.s.phoneNumber,
                    keyboardType: TextInputType.phone,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: landline,
                    labelText: U.s.landline,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: zipCode,
                    labelText: U.s.zipCode,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: cityCode,
                    labelText: U.s.cityCode,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: mcc,
                    labelText: U.s.mcc,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: ownerName,
                    labelText: U.s.ownerName,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: ownerPhoneNumber,
                    labelText: U.s.ownerPhoneNumber,
                    keyboardType: TextInputType.phone,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  UTextField(
                    controller: address,
                    labelText: U.s.address,
                    lines: 2,
                    validator: UValidators.required(message: U.s.required),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        UNavigator.back();
                        c.create(
                          p: UMerchantCreateParams(
                            tags: <int>[TagMerchant.normal.number],
                            title: title.text,
                            businessTitle: businessTitle.text.nullIfEmpty(),
                            nationalCode: nationalCode.numString(),
                            phoneNumber: phoneNumber.numString(),
                            landline: landline.numString(),
                            zipCode: zipCode.numString(),
                            cityCode: cityCode.numString(),
                            mcc: mcc.numString(),
                            ownerName: ownerName.text,
                            ownerPhoneNumber: ownerPhoneNumber.numString(),
                            address: address.text,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
