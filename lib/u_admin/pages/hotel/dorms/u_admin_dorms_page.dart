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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.dorms,
    onFilter: () => UAdminForm.filter(
      title: U.s.filterItem(U.s.dorms),
      children: (_) => <Widget>[UAdminForm.text(c.titleFilter, U.s.title)],
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
      UPopupMenuItem(label: U.s.room, icon: Icons.meeting_room_outlined, onTap: () => UAdminPageSwitcher.dormRooms(dorm: i)),
      UPopupMenuItem(label: U.s.beds, icon: Icons.bed_outlined, onTap: () => UAdminPageSwitcher.dormBeds(dorm: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageDorms]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteDorms]), onTap: () => c.delete(i)),
    ],
  );

  /// Create ([d] == null) and edit share this one dialog.
  Future<void> _form([UDormResponse? d]) async {
    await c.loadForm(d);
    final UCountryCityInfo city = UCountries.infoByCode(c.cityCode);
    await UAdminForm.editDialog(
      title: d == null ? U.s.createItem(U.s.dorm) : "${U.s.editItem(U.s.dorm)} — ${d.title}",
      formKey: c.formKey,
      maxWidth: 760,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.title, U.s.title, required: true),
        UCountryProvincePicker(
          initialCountry: city.country,
          initialProvince: city.province,
          initialCity: city.city,
          onProvinceChanged: (UProvince i) => c.cityCode = i.code,
          onCityChanged: (UCity? i) => c.cityCode = i?.code ?? c.cityCode,
        ).pSymmetric(vertical: 6),
        UTagChips<TagDorm>(title: U.s.gender, options: TagDorm.values.group(100), tags: c.tags, single: true),
        UAdminForm.text(c.description, U.s.description, lines: 3),
        UAdminForm.text(c.address, U.s.address),
        UTextFieldPhoneNumber(controller: c.phone, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UAdminForm.pair(context, UAdminForm.text(c.nearbyUniversity, U.s.nearbyUniversity), UAdminForm.text(c.universityWalkMinutes, U.s.universityWalkMinutes, number: true)),
        UAdminForm.pair(context, UAdminForm.text(c.visitingHours, U.s.visitingHours), UAdminForm.text(c.curfewTime, U.s.curfewTime)),
        UAdminForm.pair(context, UAdminForm.text(c.latitude, "Latitude", number: true), UAdminForm.text(c.longitude, "Longitude", number: true)),
        UAdminForm.sectionTitle(U.s.status),
        UTagChips<TagDorm>(title: U.s.status, options: const <TagDorm>[TagDorm.active, TagDorm.inactive], tags: c.tags, single: true),
        UTagChips<TagDorm>(title: U.s.featured, options: const <TagDorm>[TagDorm.featured], tags: c.tags),
        UTagChips<TagDorm>(title: U.s.approval, options: TagDorm.values.group(400), tags: c.tags, single: true),
        UAdminForm.sectionTitle(U.s.admins),
        UTextFieldAutoCompleteAsyncMulti<UUserResponse>(
          selected: c.admins,
          hintText: U.s.admins,
          labelBuilder: (UUserResponse u) => u.userName,
          fetchData: c.searchUsers,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UAdminForm.sectionTitle(U.s.photos),
        UFilePicker.gallery(c.photos),
        UAdminForm.sectionTitle(U.s.details),
        UListEditor.strings(title: U.s.highlights, addLabel: U.s.addHighlight, items: c.highlights, onChanged: (List<String> v) => c.highlights = v),
        UTagChips<TagDorm>(title: U.s.acceptedResidents, options: TagDorm.values.group(300), tags: c.tags),
        UTagChips<TagDorm>(title: U.s.amenities, options: TagDorm.values.group(500), tags: c.tags),
        UTagChips<TagDorm>(title: U.s.includedInRent, options: TagDorm.values.group(700), tags: c.tags),
        UTagChips<TagDorm>(title: U.s.mealServices, options: TagDorm.values.group(600), tags: c.tags),
        UAdminForm.sectionTitle(U.s.policies),
        UAdminForm.text(c.minimumStayMonths, U.s.minimumStayMonths, number: true),
        UAdminForm.text(c.policies, U.s.policies, lines: 3),
        UAdminForm.text(c.rules, U.s.rules),
        UAdminForm.text(c.requiredDocuments, U.s.requiredDocuments),
        UAdminForm.sectionTitle(U.s.socialMedia),
        UAdminForm.pair(context, UAdminForm.text(c.website, U.s.website), UAdminForm.text(c.whatsapp, U.s.whatsapp)),
        UAdminForm.pair(context, UAdminForm.text(c.instagram, U.s.instagram), UAdminForm.text(c.telegram, U.s.telegram)),
        UAdminForm.sectionTitle(U.s.nearbyPlaces),
        UAdminForm.text(c.howToGetThere, U.s.howToGetThere, lines: 2),
        UListEditor.nearby(items: c.nearby, onChanged: (List<UPlaceNearby> v) => c.nearby = v),
        UAdminForm.sectionTitle(U.s.faqs),
        UListEditor.faqs(items: c.faqs, onChanged: (List<UPlaceFaq> v) => c.faqs = v),
      ],
    );
  }
}
