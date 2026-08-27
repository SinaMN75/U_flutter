import "package:u/utilities.dart";

class UAdminHotelRoomPage extends StatefulWidget {
  const UAdminHotelRoomPage({this.hotel, super.key});

  final UHotelResponse? hotel;

  @override
  State<UAdminHotelRoomPage> createState() => _HotelRoomPageState();
}

class _HotelRoomPageState extends State<UAdminHotelRoomPage> {
  final UAdminHotelRoomController c = UAdminHotelRoomController();

  @override
  void initState() {
    c.init(hotel: widget.hotel);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.hotel?.title == null ? U.s.hotelRooms : "${U.s.rooms} · ${widget.hotel?.title}",
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageHotels) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UHotelRoomResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.rooms),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.hotel, U.s.capacity, U.s.priceNight, U.s.operations]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _itemDesktop(UHotelRoomResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.hotel?.title ?? "-"),
      UAdminTable.cell(i.capacity.toString()),
      UAdminTable.cell(i.pricePerNight.rial()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UHotelRoomResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.meeting_room_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.hotel, i.hotel?.title ?? "-"),
      UAdminField(U.s.capacity, i.capacity.toString()),
      UAdminField(U.s.priceNight, i.pricePerNight.rial()),
    ],
  );

  Widget _menu(UHotelRoomResponse i) => UAdminOps.menu<UHotelRoomResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UHotelRoomResponse>(
      onEdit: (UHotelRoomResponse r) => _showEditDialog(p: r),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UHotelRoomResponse> ctx) => <UAdminAction>[
      UAdminLinks.roomReservations(ctx.item),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageHotels]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteHotels]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.rooms)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(
                controller: c.minPriceFilter,
                labelText: U.s.minPrice,
                keyboardType: TextInputType.number,
                formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
              UTextField(
                controller: c.maxPriceFilter,
                labelText: U.s.maxPrice,
                keyboardType: TextInputType.number,
                formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
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

  void _showEditDialog({UHotelRoomResponse? p}) {
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController capacity = TextEditingController(text: p?.capacity.toString());
    final TextEditingController price = TextEditingController(text: p?.pricePerNight.toInt().toString());
    final TextEditingController detail = TextEditingController(text: p?.jsonData.description ?? p?.jsonData.detail1);
    final TextEditingController roomNumber = TextEditingController(text: p?.roomNumber);
    final TextEditingController quantity = TextEditingController(text: (p?.quantity ?? 1).toString());
    final TextEditingController bedType = TextEditingController(text: p?.jsonData.bedType);
    final TextEditingController size = TextEditingController(text: p?.jsonData.sizeSquareMeters == null ? null : p!.jsonData.sizeSquareMeters!.toInt().toString());
    final TextEditingController floor = TextEditingController(text: p?.jsonData.floor?.toString());
    final TextEditingController amenities = TextEditingController(text: p?.jsonData.amenities.join(", "));
    bool isAvailable = p?.isAvailable ?? true;
    final Rxn<UHotelResponse> hotel = Rxn<UHotelResponse>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(p == null ? U.s.createItem(U.s.room) : U.s.editItem(U.s.room)),
        content: SizedBox(
          width: context.dialogWidth(max: 480),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setLocal) => Form(
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
                    if (widget.hotel == null)
                      UTextFieldAutoCompleteAsync<UHotelResponse>(
                        labelBuilder: (UHotelResponse i) => i.title,
                        onChanged: hotel.call,
                        selectedItem: hotel.value,
                        fetchData: c.readHotels,
                        hintText: U.s.hotel,
                      ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: capacity,
                      labelText: U.s.capacity,
                      keyboardType: TextInputType.number,
                      validator: UValidators.required(message: ""),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(
                      controller: price,
                      labelText: U.s.priceNight,
                      keyboardType: TextInputType.number,
                      validator: UValidators.required(message: ""),
                      formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    UTextField(controller: detail, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: roomNumber, labelText: U.s.roomNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: quantity, labelText: U.s.quantity, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: bedType, labelText: U.s.bedType, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: size, labelText: U.s.size, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: floor, labelText: U.s.floor, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: amenities, labelText: U.s.amenities, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(U.s.available), value: isAvailable, onChanged: (bool v) => setLocal(() => isAvailable = v)),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final String? hid = hotel.value?.id ?? widget.hotel?.id;
                          if (hid == null) {
                            UToast.error(message: U.s.pleaseSelectA(U.s.hotel));
                            return;
                          }
                          if (p == null) {
                            c.create(
                              p: UHotelRoomCreateParams(
                                tags: <int>[TagRoom.single.number],
                                title: title.text,
                                capacity: capacity.numInt(),
                                pricePerNight: price.numDouble(),
                                hotelId: hid,
                                roomNumber: roomNumber.text.nullIfEmpty(),
                                quantity: quantity.text.isEmpty ? 1 : quantity.text.toInt(),
                                isAvailable: isAvailable,
                                description: detail.text.nullIfEmpty(),
                                bedType: bedType.text.nullIfEmpty(),
                                sizeSquareMeters: size.text.isEmpty ? null : size.numDouble(),
                                floor: floor.text.isEmpty ? null : floor.text.toInt(),
                                amenities: amenities.text.trim().isEmpty ? null : amenities.text.split(",").map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList(),
                              ),
                            );
                          } else {
                            c.update(
                              p: UHotelRoomUpdateParams(
                                id: p.id,
                                title: title.text,
                                capacity: capacity.numInt(),
                                pricePerNight: price.numDouble(),
                                hotelId: hid,
                                roomNumber: roomNumber.text.nullIfEmpty(),
                                quantity: quantity.text.isEmpty ? null : quantity.text.toInt(),
                                isAvailable: isAvailable,
                                description: detail.text.nullIfEmpty(),
                                bedType: bedType.text.nullIfEmpty(),
                                sizeSquareMeters: size.text.isEmpty ? null : size.numDouble(),
                                floor: floor.text.isEmpty ? null : floor.text.toInt(),
                                amenities: amenities.text.trim().isEmpty ? null : amenities.text.split(",").map((String e) => e.trim()).where((String e) => e.isNotEmpty).toList(),
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
