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
      context,
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
    context,
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
    final TextEditingController detail = TextEditingController(text: p?.jsonData.detail1);
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
                  UTextField(
                    controller: detail,
                    labelText: U.s.description,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    lines: 3,
                  ).pSymmetric(vertical: 6),
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
                              tags: <int>[TagDorm.girls.number],
                              title: title.text,
                              cityCode: city?.code ?? province.code,
                              detail1: detail.text.nullIfEmpty(),
                              adminUserIds: adminUserIds,
                            ),
                          );
                        } else {
                          c.update(
                            p: UDormUpdateParams(
                              id: p.id,
                              title: title.text,
                              cityCode: city?.code ?? province.code,
                              detail1: detail.text.nullIfEmpty(),
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
        )),
      ),
    );
  }
}
