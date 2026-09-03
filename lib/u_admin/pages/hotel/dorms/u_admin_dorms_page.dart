import "package:u/utilities.dart";

class UAdminDormPage extends StatefulWidget {
  const UAdminDormPage({super.key});

  @override
  State<UAdminDormPage> createState() => _DormPageState();
}

class _DormPageState extends State<UAdminDormPage> {
  final UAdminDormController c = UAdminDormController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.dorms,
    onCreate: U.user.hasPermission(TagUser.permissionManageDorms) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UDormResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.dorms),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.city, U.s.room, U.s.created, U.s.operations]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _itemDesktop(UDormResponse i, int index) {
    final UCountryCityInfo city = UCountries.infoByCode(i.cityCode);
    return URow(
      spacing: 8,
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

  Widget _itemResponsive(UDormResponse i, int index) {
    final UCountryCityInfo city = UCountries.infoByCode(i.cityCode);
    return UAdminTable.mobileCard(
      icon: Icons.bedroom_parent_rounded,
      title: i.title,
      trailing: _menu(i),
      fields: <UAdminField>[
        UAdminField(U.s.city, "${city.country?.nameFa ?? ""} - ${city.province?.nameFa ?? ""} - ${city.city?.nameFa ?? ""}"),
        UAdminField(U.s.rooms, (i.rooms?.length ?? 0).toString()),
        UAdminField(U.s.created, i.createdAt.toJalaliDate()),
      ],
    );
  }

  Widget _menu(UDormResponse i) => UAdminOps.menu<UDormResponse>(
    item: i,
    handlers: UAdminActionHandlers<UDormResponse>(
      onEdit: (UDormResponse d) => _showEditDialog(p: d),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UDormResponse> ctx) => <UAdminAction>[
      UAdminLinks.dormRooms(ctx.item),
      UAdminLinks.dormBeds(ctx.item),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageDorms]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteDorms]),
    ],
  );

  Future<void> _showEditDialog({UDormResponse? p}) async {
    final TextEditingController title = TextEditingController(text: p?.title);
    UProvince province = UCountries.iran().provinces.first;
    UCity? city = province.cities.firstOrNull;
    final TextEditingController detail = TextEditingController(text: p?.jsonData.description);
    final TextEditingController address = TextEditingController(text: p?.address);
    final TextEditingController phoneNumber = TextEditingController(text: p?.phoneNumber);
    final TextEditingController nearbyUniversity = TextEditingController(text: p?.jsonData.nearbyUniversity);
    final TextEditingController visitingHours = TextEditingController(text: p?.jsonData.visitingHours);
    final TextEditingController amenities = TextEditingController(text: p?.jsonData.amenities.join("، "));
    final TextEditingController rules = TextEditingController(text: p?.jsonData.rules.join("، "));
    final TextEditingController requiredDocuments = TextEditingController(text: p?.jsonData.requiredDocuments.join("، "));
    final TextEditingController latitude = TextEditingController(text: p?.jsonData.latitude?.toString());
    final TextEditingController longitude = TextEditingController(text: p?.jsonData.longitude?.toString());
    bool isGirls = p == null || p.tags.contains(TagDorm.girls.number);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final List<UUserResponse> selectedAdmins = <UUserResponse>[];

    if (p != null && p.adminUserIds.isNotEmpty) {
      final List<UUserResponse?> fetched = await Future.wait(p.adminUserIds.map(UAdminHotelAdminSearchHelper.fetchUserById));
      selectedAdmins.addAll(fetched.whereType<UUserResponse>());
    }

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.dorm) : U.s.editItem(U.s.dorm)),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(
                      controller: title,
                      labelText: U.s.title,
                      validator: UValidators.required(message: ""),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UCountryProvincePicker(
                      onCountryChanged: (UCountry i) {},
                      onProvinceChanged: (UProvince i) => province = i,
                      onCityChanged: (UCity? i) => city = i,
                    ).pSymmetric(vertical: 6),
                    UChipChoice<String>(
                      options: <String>[TagDorm.girls.titleFa, TagDorm.boys.titleFa],
                      selected: isGirls ? TagDorm.girls.titleFa : TagDorm.boys.titleFa,
                      onChanged: (int index, bool isSelected, String item) => setDialogState(() => isGirls = index == 0),
                    ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: detail,
                      labelText: U.s.description,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      lines: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(controller: address, labelText: U.s.address, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: phoneNumber, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: nearbyUniversity, labelText: U.s.nearbyUniversity, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: visitingHours, labelText: U.s.visitingHours, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: amenities, labelText: U.s.amenities, hintText: "،", margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: rules, labelText: U.s.rules, hintText: "،", margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: requiredDocuments, labelText: U.s.requiredDocuments, hintText: "،", margin: const EdgeInsets.symmetric(vertical: 6)),
                    URow(
                      children: <Widget>[
                        UTextField(expanded: 1, controller: latitude, labelText: "Latitude", keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                        const SizedBox(width: 8),
                        UTextField(expanded: 1, controller: longitude, labelText: "Longitude", keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                      ],
                    ),
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
                          if (p == null) {
                            c.create(
                              p: UDormCreateParams(
                                tags: <int>[if (isGirls) TagDorm.girls.number else TagDorm.boys.number],
                                title: title.text,
                                cityCode: city?.code ?? province.code,
                                address: address.text.nullIfEmpty(),
                                phoneNumber: phoneNumber.text.nullIfEmpty(),
                                description: detail.text.nullIfEmpty(),
                                nearbyUniversity: nearbyUniversity.text.nullIfEmpty(),
                                visitingHours: visitingHours.text.nullIfEmpty(),
                                amenities: _splitList(amenities.text),
                                rules: _splitList(rules.text),
                                requiredDocuments: _splitList(requiredDocuments.text),
                                latitude: double.tryParse(latitude.text.toLatinNumber()),
                                longitude: double.tryParse(longitude.text.toLatinNumber()),
                                adminUserIds: adminUserIds,
                              ),
                            );
                          } else {
                            c.update(
                              p: UDormUpdateParams(
                                id: p.id,
                                tags: <int>[if (isGirls) TagDorm.girls.number else TagDorm.boys.number],
                                title: title.text,
                                cityCode: city?.code ?? province.code,
                                address: address.text.nullIfEmpty(),
                                phoneNumber: phoneNumber.text.nullIfEmpty(),
                                description: detail.text.nullIfEmpty(),
                                nearbyUniversity: nearbyUniversity.text.nullIfEmpty(),
                                visitingHours: visitingHours.text.nullIfEmpty(),
                                amenities: _splitList(amenities.text),
                                rules: _splitList(rules.text),
                                requiredDocuments: _splitList(requiredDocuments.text),
                                latitude: double.tryParse(latitude.text.toLatinNumber()),
                                longitude: double.tryParse(longitude.text.toLatinNumber()),
                                adminUserIds: adminUserIds,
                              ),
                            );
                          }
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
      ),
    );
  }
}

/// Admin forms take these lists as one comma-separated field.
List<String>? _splitList(String value) {
  final List<String> items = value.split(RegExp("[،,]")).map((String i) => i.trim()).where((String i) => i.isNotEmpty).toList();
  return items.isEmpty ? null : items;
}
