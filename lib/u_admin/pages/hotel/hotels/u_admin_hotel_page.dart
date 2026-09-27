import "package:u/utilities.dart";

class UAdminHotelPage extends StatefulWidget {
  const UAdminHotelPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.hotels, const UAdminHotelPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.hotels,
    icon: Icons.apartment_rounded,
    page: () => const UAdminHotelPage(),
    roles: roles,
  );

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.hotels,
    onFilter: () => UAdminForm.filter(
      title: U.s.filterItem(U.s.hotels),
      children: (_) => <Widget>[UAdminForm.text(c.titleFilter, U.s.title)],
      onApply: c.applyFilters,
      onClear: c.clearFilters,
    ),
    onCreate: U.user.hasPermission(TagUser.permissionManageHotels) ? _form : null,
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
      emptyText: U.s.noItemsFound(U.s.hotels),
      desktopHeader: () => UAdminTable.header(
        <String>[
          U.s.title,
          U.s.city,
          U.s.rooms,
          U.s.created,
          U.s.featured,
          U.s.active,
          U.s.operations,
        ],
      ),
      desktopRow: (UHotelResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          UAdminTable.cell(i.title),
          UAdminTable.cell(UCountries.cityFullName(i.cityCode) ?? "-"),
          UAdminTable.cell((i.rooms?.length ?? 0).toString()),
          UAdminTable.cell(i.createdAt.toJalaliDate()),
          Switch(
            value: i.tags.contains(TagHotel.featured.number),
            onChanged: _canManage ? (bool on) => c.setTag(i, TagHotel.featured, on) : null,
          ).expanded(),
          Switch(
            value: i.tags.contains(TagHotel.active.number),
            onChanged: _canManage ? (bool on) => c.setTag(i, TagHotel.active, on, opposite: TagHotel.inactive) : null,
          ).expanded(),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UHotelResponse i, int index) => UAdminTable.mobileCard(
        icon: Icons.apartment_rounded,
        title: i.title,
        trailing: _menu(i),
        fields: <UAdminField>[
          UAdminField(U.s.city, UCountries.cityFullName(i.cityCode) ?? "-"),
          UAdminField(U.s.rooms, (i.rooms?.length ?? 0).toString()),
          UAdminField(U.s.created, i.createdAt.toJalaliDate()),
          UAdminField(
            U.s.featured,
            null,
            valueWidget: Switch(
              value: i.tags.contains(TagHotel.featured.number),
              onChanged: _canManage ? (bool on) => c.setTag(i, TagHotel.featured, on) : null,
            ),
          ),
          UAdminField(
            U.s.active,
            null,
            valueWidget: Switch(
              value: i.tags.contains(TagHotel.active.number),
              onChanged: _canManage ? (bool on) => c.setTag(i, TagHotel.active, on, opposite: TagHotel.inactive) : null,
            ),
          ),
        ],
      ),
    ),
  );

  bool get _canManage => U.user.hasPermission(TagUser.permissionManageHotels);

  Widget _menu(UHotelResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.rooms, icon: Icons.meeting_room_outlined, onTap: () => UAdminHotelRoomPage.open(hotel: i)),
      UPopupMenuItem(label: U.s.reservations, icon: Icons.event_available_outlined, onTap: () => UAdminReservationPage.open(hotel: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageHotels]), onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteHotels]), onTap: () => c.delete(i)),
    ],
  );

  Future<void> _form([UHotelResponse? h]) async {
    await c.loadForm(h);
    final UCountryCityInfo city = UCountries.infoByCode(c.cityCode);
    await UAdminForm.editDialog(
      title: h == null ? U.s.createItem(U.s.hotel) : "${U.s.editItem(U.s.hotel)} — ${h.title}",
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
        UAdminForm.text(c.description, U.s.description, lines: 3),
        UAdminForm.text(c.stars, U.s.stars, number: true),
        UAdminForm.text(c.address, U.s.address, lines: 2),
        UTextFieldPhoneNumber(controller: c.phone, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UAdminForm.text(c.email, U.s.email),
        UAdminForm.pair(context, UAdminForm.text(c.latitude, "Latitude", number: true), UAdminForm.text(c.longitude, "Longitude", number: true)),
        UTagChips<TagHotel>(title: U.s.propertyType, options: TagHotel.values.group(100), tags: c.tags, single: true),
        UAdminForm.sectionTitle(U.s.status),
        UTagChips<TagHotel>(title: U.s.status, options: const <TagHotel>[TagHotel.active, TagHotel.inactive], tags: c.tags, single: true),
        UTagChips<TagHotel>(title: U.s.featured, options: const <TagHotel>[TagHotel.featured], tags: c.tags),
        UTagChips<TagHotel>(title: U.s.approval, options: TagHotel.values.group(400), tags: c.tags, single: true),
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
        UTagChips<TagHotel>(title: U.s.amenities, options: TagHotel.values.group(500), tags: c.tags),
        UTagChips<TagHotel>(title: U.s.mealPlans, options: TagHotel.values.group(600), tags: c.tags),
        UAdminForm.sectionTitle(U.s.policies),
        UTagChips<TagHotel>(title: U.s.policies, options: TagHotel.values.group(300), tags: c.tags),
        UAdminForm.pair(context, UAdminForm.text(c.checkInTime, U.s.checkInTime), UAdminForm.text(c.checkOutTime, U.s.checkOutTime)),
        UAdminForm.pair(
          context,
          UAdminForm.text(c.cancellationFreeHours, U.s.freeCancellationUpToAFewHoursBeforeCheckIn, number: true),
          UAdminForm.text(c.cancellationPenaltyNights, U.s.cancellationFee, number: true),
        ),
        UAdminForm.text(c.policies, U.s.policies, lines: 2),
        UAdminForm.text(c.rules, U.s.rules, lines: 2),
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
