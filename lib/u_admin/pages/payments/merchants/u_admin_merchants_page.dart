import "package:u/utilities.dart";

class UAdminMerchantsPage extends StatefulWidget {
  const UAdminMerchantsPage({super.key, this.user});

  static void open({UUserResponse? user}) => U.addOrSwitchTab(
    user == null ? U.s.merchantsManagement : "${U.s.merchants} · ${user.displayName}",
    UAdminMerchantsPage(user: user),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.merchants,
    icon: Icons.storefront_rounded,
    page: () => const UAdminMerchantsPage(),
    roles: roles,
  );

  final UUserResponse? user;

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.merchantsManagement,
    onFilter: _filter,
    onCreate: _form,
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
      UAdminTable.cell(UBusinessCategories.categories.firstWhereOrNull((UBusinessCategory j) => j.code == i.mcc)?.localizedName() ?? i.mcc),
      UAdminTable.cell(i.merchantId ?? U.s.unassigned),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UMerchantResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.storefront_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.nationalCode, i.nationalCode),
      UAdminField(U.s.phoneNumber, i.phoneNumber),
      UAdminField(U.s.mcc, UBusinessCategories.categories.firstWhereOrNull((UBusinessCategory j) => j.code == i.mcc)?.localizedName() ?? i.mcc),
      UAdminField(U.s.merchantId, i.merchantId ?? U.s.unassigned),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UMerchantResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.viewItem(U.s.terminals), icon: Icons.point_of_sale_outlined, onTap: () => UAdminTerminalsPage.open(merchant: i)),
      UPopupMenuItem(label: U.s.viewItem(U.s.details), icon: Icons.info_outline, onTap: () => _detail(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _detail(UMerchantResponse i) => UNavigator.dialog(
    AlertDialog(
      title: Text(i.title),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
        ),
      ),
      actions: <Widget>[UButton(type: UButtonType.text, title: U.s.ok, onTap: UNavigator.back)],
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

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.merchant),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UTextFieldAutoCompleteAsync<UUserResponse>(
        labelBuilder: (UUserResponse i) => "${i.firstName} ${i.lastName} ${i.nationalCode}",
        onChanged: (UUserResponse? v) => c.user = v,
        selectedItem: c.user,
        fetchData: c.searchUsers,
        hintText: U.s.user,
      ).pSymmetric(vertical: 6),
      UTextFieldAutoComplete<UBusinessCategory?>(
        items: UBusinessCategories.categories,
        labelBuilder: (UBusinessCategory? i) => i?.localizedName() ?? i?.code ?? "",
        onChanged: (UBusinessCategory? v) => c.businessCategory = v,
        selectedItem: c.businessCategory,
        hintText: U.s.businessTitle,
      ).pSymmetric(vertical: 6),
      URow(
        margin: const EdgeInsets.symmetric(vertical: 6),
        children: <Widget>[
          Expanded(
            child: UTextFieldAutoComplete<UProvince?>(
              title: U.s.province,
              items: UCountries.iranProvinces,
              labelBuilder: (UProvince? i) => i?.nameFa ?? "",
              selectedItem: c.province,
              onChanged: (UProvince? v) => setState(() {
                c.province = v;
                c.city = v?.cities.firstOrNull;
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: UTextFieldAutoComplete<UCity?>(
              title: U.s.city,
              items: c.province?.cities ?? <UCity>[],
              labelBuilder: (UCity? i) => i?.nameFa ?? "",
              selectedItem: c.city,
              onChanged: (UCity? v) => c.city = v,
            ),
          ),
        ],
      ),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.fromDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.startDate = d;
          c.startDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.endDateController,
        labelText: U.s.toDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.endDate = d;
          c.endDateController.text = d.toJalaliDate();
        },
      ),
      UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.nationalCodeFilterController, labelText: U.s.nationalCode, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.phoneNumberFilterController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.landlineFilterController, labelText: U.s.landline, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.zipCodeFilterController, labelText: U.s.zipCode, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.merchantIdFilterController, labelText: U.s.merchantId, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.bankAccountIdFilterController, labelText: U.s.bankAccountId, margin: const EdgeInsets.symmetric(vertical: 6)),
    ],
  );

  Future<void> _form() async {
    c.loadForm();
    await UFormDialog.show(
      title: U.s.createItem(U.s.merchant),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.businessTitleController, labelText: U.s.businessTitle, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.nationalCodeController, labelText: U.s.nationalCode, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneNumberController, labelText: U.s.phoneNumber, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.landlineController, labelText: U.s.landline, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.zipCodeController, labelText: U.s.zipCode, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.cityCodeController, labelText: U.s.cityCode, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.mccController, labelText: U.s.mcc, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.ownerNameController, labelText: U.s.ownerName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.ownerPhoneNumberController, labelText: U.s.ownerPhoneNumber, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.addressController, labelText: U.s.address, lines: 2, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
      ],
    );
  }
}
