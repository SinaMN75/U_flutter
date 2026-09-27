import "package:u/utilities.dart";

class UAdminDormPage extends StatefulWidget {
  const UAdminDormPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.dorms, const UAdminDormPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.dorms,
    icon: Icons.bedroom_parent_rounded,
    page: () => const UAdminDormPage(),
    roles: roles,
  );

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.dorms,
    onFilter: () => UFilterDialog.show(
      title: U.s.filterItem(U.s.dorms),
      children: (_) => <Widget>[UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6))],
      onApply: c.applyFilters,
      onClear: c.clearFilters,
    ),
    onCreate: U.user.hasPermission(TagUser.permissionManageDorms) ? _form : null,
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
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.city, U.s.room, U.s.created, U.s.featured, U.s.active, U.s.operations]),
      desktopRow: (UDormResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(i.title),
          UAdminTable.cell(UCountries.cityFullName(i.cityCode) ?? "-"),
          UAdminTable.cell((i.rooms?.length ?? 0).toString()),
          UAdminTable.cell(i.createdAt.toJalaliDate()),
          _featured(i).expanded(),
          _active(i).expanded(),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UDormResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.bedroom_parent_rounded,
        title: i.title,
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.city, UCountries.cityFullName(i.cityCode) ?? "-"),
          UAdminField(U.s.rooms, (i.rooms?.length ?? 0).toString()),
          UAdminField(U.s.created, i.createdAt.toJalaliDate()),
          UAdminField(U.s.featured, null, valueWidget: _featured(i)),
          UAdminField(U.s.active, null, valueWidget: _active(i)),
        ],
      ),
    ),
  );

  bool get _canManage => U.user.hasPermission(TagUser.permissionManageDorms);

  Widget _featured(UDormResponse i) => Switch(value: i.tags.contains(TagDorm.featured.number), onChanged: _canManage ? (bool on) => c.setTag(i, TagDorm.featured, on) : null);

  /// Active = shown to the public.
  Widget _active(UDormResponse i) =>
      Switch(value: i.tags.contains(TagDorm.active.number), onChanged: _canManage ? (bool on) => c.setTag(i, TagDorm.active, on, opposite: TagDorm.inactive) : null);

  Widget _menu(UDormResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.room, icon: Icons.meeting_room_outlined, onTap: () => UAdminDormRoomPage.open(dorm: i)),
      UPopupMenuItem(label: U.s.beds, icon: Icons.bed_outlined, onTap: () => UAdminDormBedPage.open(dorm: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageDorms]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteDorms]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([d] == null) and edit share this one dialog.
  Future<void> _form([UDormResponse? d]) async {
    await c.loadForm(d);
    final UCountryCityInfo city = UCountries.infoByCode(c.cityCode);
    await UFormDialog.show(
      title: d == null ? U.s.createItem(U.s.dorm) : "${U.s.editItem(U.s.dorm)} — ${d.title}",
      maxWidth: 760,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UCountryProvincePicker(
          initialCountry: city.country,
          initialProvince: city.province,
          initialCity: city.city,
          onProvinceChanged: (UProvince i) => c.cityCode = i.code,
          onCityChanged: (UCity? i) => c.cityCode = i?.code ?? c.cityCode,
        ).pSymmetric(vertical: 6),
        UTagChips<TagDorm>(title: U.s.gender, options: TagDorm.values.group(100), tags: c.tags, single: true),
        UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.addressController, labelText: U.s.address, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UFieldPair(
          UTextField(controller: c.nearbyUniversityController, labelText: U.s.nearbyUniversity, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.universityWalkMinutesController, labelText: U.s.universityWalkMinutes, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UFieldPair(
          UTextField(controller: c.visitingHoursController, labelText: U.s.visitingHours, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.curfewTimeController, labelText: U.s.curfewTime, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UFieldPair(
          UTextField(controller: c.latitudeController, labelText: "Latitude", keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.longitudeController, labelText: "Longitude", keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        const Divider(height: 20),
        UTextBodySmall(U.s.status, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTagChips<TagDorm>(title: U.s.status, options: const <TagDorm>[TagDorm.active, TagDorm.inactive], tags: c.tags, single: true),
        UTagChips<TagDorm>(title: U.s.featured, options: const <TagDorm>[TagDorm.featured], tags: c.tags),
        UTagChips<TagDorm>(title: U.s.approval, options: TagDorm.values.group(400), tags: c.tags, single: true),
        const Divider(height: 20),
        UTextBodySmall(U.s.admins, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTextFieldAutoCompleteAsyncMulti<UUserResponse>(
          selected: c.admins,
          hintText: U.s.admins,
          labelBuilder: (UUserResponse u) => u.userName,
          fetchData: c.searchUsers,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        const Divider(height: 20),
        UTextBodySmall(U.s.photos, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UFilePicker.gallery(c.photos),
        const Divider(height: 20),
        UTextBodySmall(U.s.details, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UListEditor.strings(title: U.s.highlights, addLabel: U.s.addHighlight, items: c.highlights, onChanged: (List<String> v) => c.highlights = v),
        UTagChips<TagDorm>(title: U.s.acceptedResidents, options: TagDorm.values.group(300), tags: c.tags),
        UTagChips<TagDorm>(title: U.s.amenities, options: TagDorm.values.group(500), tags: c.tags),
        UTagChips<TagDorm>(title: U.s.includedInRent, options: TagDorm.values.group(700), tags: c.tags),
        UTagChips<TagDorm>(title: U.s.mealServices, options: TagDorm.values.group(600), tags: c.tags),
        const Divider(height: 20),
        UTextBodySmall(U.s.policies, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTextField(controller: c.minimumStayMonthsController, labelText: U.s.minimumStayMonths, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.policiesController, labelText: U.s.policies, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.rulesController, labelText: U.s.rules, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.requiredDocumentsController, labelText: U.s.requiredDocuments, margin: const EdgeInsets.symmetric(vertical: 6)),
        const Divider(height: 20),
        UTextBodySmall(U.s.socialMedia, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UFieldPair(
          UTextField(controller: c.websiteController, labelText: U.s.website, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.whatsappController, labelText: U.s.whatsapp, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UFieldPair(
          UTextField(controller: c.instagramController, labelText: U.s.instagram, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.telegramController, labelText: U.s.telegram, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        const Divider(height: 20),
        UTextBodySmall(U.s.nearbyPlaces, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTextField(controller: c.howToGetThereController, labelText: U.s.howToGetThere, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        UListEditor.nearby(items: c.nearby, onChanged: (List<UPlaceNearby> v) => c.nearby = v),
        const Divider(height: 20),
        UTextBodySmall(U.s.faqs, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UListEditor.faqs(items: c.faqs, onChanged: (List<UPlaceFaq> v) => c.faqs = v),
      ],
    );
  }
}
