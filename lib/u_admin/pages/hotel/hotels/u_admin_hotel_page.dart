import "package:u/utilities.dart";

class UAdminHotelPage extends StatefulWidget {
  const UAdminHotelPage({super.key});

  @override
  State<UAdminHotelPage> createState() => _HotelPageState();
}

class _HotelPageState extends State<UAdminHotelPage> {
  final UAdminHotelController c = UAdminHotelController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.hotels,
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageHotels) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UHotelResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noHotelsFound,
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.city, U.s.rooms, U.s.created, U.s.operations]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _itemDesktop(UHotelResponse i, int index) {
    final UCountryCityInfo city = UCountries.infoByCode(i.cityCode);
    return URow(
      color: UAdminTable.rowColor(context, index),
      padding: UAdminTable.rowPadding,
      children: <Widget>[
        UAdminTable.cell(i.title),
        UAdminTable.cell("${city.country?.nameFa ?? ""} - ${city.province?.nameFa ?? ""} - ${city.city?.nameFa ?? ""}"),
        UAdminTable.cell((i.rooms?.length ?? 0).toString()),
        UAdminTable.cell(i.createdAt.toJalaliDate()),
        _menu(i).expanded(),
      ],
    );
  }

  Widget _itemResponsive(UHotelResponse i, int index) {
    final UCountryCityInfo city = UCountries.infoByCode(i.cityCode);
    return UAdminTable.mobileCard(
      context,
      icon: Icons.apartment_rounded,
      title: i.title,
      trailing: _menu(i),
      fields: <UAdminField>[
        UAdminField(U.s.city, "${city.country?.nameFa ?? ""} - ${city.province?.nameFa ?? ""} - ${city.city?.nameFa ?? ""}"),
        UAdminField(U.s.rooms, (i.rooms?.length ?? 0).toString()),
        UAdminField(U.s.created, i.createdAt.toJalaliDate()),
      ],
    );
  }

  Widget _menu(UHotelResponse i) => UAdminOps.menu<UHotelResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UHotelResponse>(
      onEdit: (UHotelResponse h) => _showEditDialog(p: h),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UHotelResponse> ctx) => <UAdminAction>[
      UAdminLinks.hotelRooms(ctx.item),
      UAdminLinks.hotelReservations(ctx.item),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageHotels]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteHotels]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterHotels),
      content: Form(
        key: c.filterFormKey,
        child: SingleChildScrollView(
          child: UColumn(
            spacing: 0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title).pSymmetric(vertical: 6),
              UCountryProvincePicker(onCountryChanged: (UCountry i) => c.countryFilter = i, onProvinceChanged: (UProvince i) => c.cityFilter = i).pSymmetric(vertical: 6),
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

  Future<void> _showEditDialog({UHotelResponse? p}) async {
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController detail = TextEditingController(text: p?.jsonData.description ?? p?.jsonData.detail1);
    final TextEditingController stars = TextEditingController(text: p?.stars.toString());
    final TextEditingController address = TextEditingController(text: p?.address);
    final TextEditingController phone = TextEditingController(text: p?.phoneNumber);
    final TextEditingController email = TextEditingController(text: p?.email);
    final TextEditingController checkInTime = TextEditingController(text: p?.jsonData.checkInTime);
    final TextEditingController checkOutTime = TextEditingController(text: p?.jsonData.checkOutTime);
    final TextEditingController policies = TextEditingController(text: p?.jsonData.policies);
    final TextEditingController amenities = TextEditingController(text: p?.jsonData.amenities.join(", "));
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final List<UUserResponse> selectedAdmins = <UUserResponse>[];
    UProvince province = UCountries.iran().provinces.first;
    UCity? city = province.cities.firstOrNull;

    if (p != null && p.adminUserIds.isNotEmpty) {
      final List<UUserResponse?> fetched = await Future.wait(p.adminUserIds.map(UAdminHotelAdminSearchHelper.fetchUserById));
      selectedAdmins.addAll(fetched.whereType<UUserResponse>());
    }

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createHotel : U.s.editHotel),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                spacing: 0,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: title,
                    labelText: U.s.title,
                    validator: UValidators.required(message: ""),
                  ).pSymmetric(vertical: 6),
                  UCountryProvincePicker(
                    onCountryChanged: (UCountry i) {},
                    onProvinceChanged: (UProvince i) => province = i,
                    onCityChanged: (UCity? i) => city = i,
                  ).pSymmetric(vertical: 6),
                  UTextField(controller: detail, labelText: U.s.description, lines: 3).pSymmetric(vertical: 6),
                  UTextField(controller: stars, labelText: U.s.stars, keyboardType: TextInputType.number).pSymmetric(vertical: 6),
                  UTextField(controller: address, labelText: U.s.address, lines: 2).pSymmetric(vertical: 6),
                  UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone).pSymmetric(vertical: 6),
                  UTextField(controller: email, labelText: U.s.email, keyboardType: TextInputType.emailAddress).pSymmetric(vertical: 6),
                  UTextField(controller: checkInTime, labelText: U.s.checkInTime).pSymmetric(vertical: 6),
                  UTextField(controller: checkOutTime, labelText: U.s.checkOutTime).pSymmetric(vertical: 6),
                  UTextField(controller: policies, labelText: U.s.policies, lines: 2).pSymmetric(vertical: 6),
                  UTextField(controller: amenities, labelText: U.s.amenities, lines: 2).pSymmetric(vertical: 6),
                  const SizedBox(height: 12),
                  UTextFieldAutoCompleteAsync<UUserResponse>(
                    hintText: U.s.admins,
                    selectedItem: null,
                    labelBuilder: (UUserResponse u) => u.userName,
                    fetchData: UAdminHotelAdminSearchHelper.searchUsers,
                    onChanged: (UUserResponse? u) {
                      if (u == null) return;
                      if (selectedAdmins.any((UUserResponse x) => x.id == u.id)) return;
                      setDialogState(() => selectedAdmins.add(u));
                    },
                  ).pSymmetric(vertical: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedAdmins
                        .map(
                          (UUserResponse u) => Chip(
                            label: Text(u.userName),
                            onDeleted: () => setDialogState(() => selectedAdmins.removeWhere((UUserResponse x) => x.id == u.id)),
                          ),
                        )
                        .toList(),
                  ).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        final List<String> adminUserIds = selectedAdmins.map((UUserResponse u) => u.id).toList();
                        if (p == null)
                          c.create(
                            p: UHotelCreateParams(
                              tags: <int>[TagHotel.hotel.number],
                              title: title.text,
                              cityCode: city?.code ?? province.code,
                              stars: stars.text.isEmpty ? 0 : stars.text.toInt(),
                              address: address.text.nullIfEmpty(),
                              phoneNumber: phone.text.nullIfEmpty(),
                              email: email.text.nullIfEmpty(),
                              description: detail.text.nullIfEmpty(),
                              policies: policies.text.nullIfEmpty(),
                              checkInTime: checkInTime.text.nullIfEmpty(),
                              checkOutTime: checkOutTime.text.nullIfEmpty(),
                              amenities: amenities.text.trim().isEmpty ? null : amenities.text.split(",").map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList(),
                              adminUserIds: adminUserIds,
                            ),
                          );
                        else
                          c.update(
                            p: UHotelUpdateParams(
                              id: p.id,
                              title: title.text,
                              cityCode: city?.code ?? province.code,
                              stars: stars.text.isEmpty ? null : stars.text.toInt(),
                              address: address.text.nullIfEmpty(),
                              phoneNumber: phone.text.nullIfEmpty(),
                              email: email.text.nullIfEmpty(),
                              description: detail.text.nullIfEmpty(),
                              policies: policies.text.nullIfEmpty(),
                              checkInTime: checkInTime.text.nullIfEmpty(),
                              checkOutTime: checkOutTime.text.nullIfEmpty(),
                              amenities: amenities.text.trim().isEmpty ? null : amenities.text.split(",").map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList(),
                              adminUserIds: adminUserIds,
                            ),
                          );
                        UNavigator.back();
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

class UAdminHotelAdminSearchHelper {
  static Future<List<UUserResponse>> searchUsers(String query) async {
    final Completer<List<UUserResponse>> completer = Completer<List<UUserResponse>>();
    await UServices.user.read(
      p: UUserReadParams(query: query.nullIfEmpty(), pageSize: 20),
      onOk: (UResponse<List<UUserResponse>> r) => completer.complete(r.result ?? <UUserResponse>[]),
      onError: (_) => completer.complete(<UUserResponse>[]),
      onException: (_) => completer.complete(<UUserResponse>[]),
    );
    return completer.future;
  }

  static Future<UUserResponse?> fetchUserById(String id) async {
    final Completer<UUserResponse?> completer = Completer<UUserResponse?>();
    await UServices.user.readById(
      p: UIdParams(id: id),
      onOk: (UResponse<UUserResponse> r) => completer.complete(r.result),
      onError: (_) => completer.complete(null),
      onException: (_) => completer.complete(null),
    );
    return completer.future;
  }
}
