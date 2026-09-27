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
    onFilter: () => UFilterDialog.show(
      title: U.s.filterItem(U.s.hotels),
      children: (_) => <Widget>[UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6))],
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
    await UFormDialog.show(
      title: h == null ? U.s.createItem(U.s.hotel) : "${U.s.editItem(U.s.hotel)} — ${h.title}",
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
        UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.starsController, labelText: U.s.stars, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.addressController, labelText: U.s.address, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.emailController, labelText: U.s.email, margin: const EdgeInsets.symmetric(vertical: 6)),
        UFieldPair(
          UTextField(controller: c.latitudeController, labelText: "Latitude", keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.longitudeController, labelText: "Longitude", keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UTagChips<TagHotel>(title: U.s.propertyType, options: TagHotel.values.group(100), tags: c.tags, single: true),
        const Divider(height: 20),
        UTextBodySmall(U.s.status, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTagChips<TagHotel>(title: U.s.status, options: const <TagHotel>[TagHotel.active, TagHotel.inactive], tags: c.tags, single: true),
        UTagChips<TagHotel>(title: U.s.featured, options: const <TagHotel>[TagHotel.featured], tags: c.tags),
        UTagChips<TagHotel>(title: U.s.approval, options: TagHotel.values.group(400), tags: c.tags, single: true),
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
        UTagChips<TagHotel>(title: U.s.amenities, options: TagHotel.values.group(500), tags: c.tags),
        UTagChips<TagHotel>(title: U.s.mealPlans, options: TagHotel.values.group(600), tags: c.tags),
        const Divider(height: 20),
        UTextBodySmall(U.s.policies, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTagChips<TagHotel>(title: U.s.policies, options: TagHotel.values.group(300), tags: c.tags),
        UFieldPair(
          UTextField(controller: c.checkInTimeController, labelText: U.s.checkInTime, margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.checkOutTimeController, labelText: U.s.checkOutTime, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UFieldPair(
          UTextField(
            controller: c.cancellationFreeHoursController,
            labelText: U.s.freeCancellationUpToAFewHoursBeforeCheckIn,
            keyboardType: TextInputType.number,
            margin: const EdgeInsets.symmetric(vertical: 6),
          ),
          UTextField(controller: c.cancellationPenaltyNightsController, labelText: U.s.cancellationFee, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UTextField(controller: c.policiesController, labelText: U.s.policies, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.rulesController, labelText: U.s.rules, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
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
