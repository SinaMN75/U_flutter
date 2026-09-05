import "package:u/utilities.dart";

class UAdminParkingSubscriptionPage extends StatefulWidget {
  const UAdminParkingSubscriptionPage({super.key, this.parking});

  final UParkingResponse? parking;

  @override
  State<UAdminParkingSubscriptionPage> createState() => _UAdminParkingSubscriptionPageState();
}

class _UAdminParkingSubscriptionPageState extends State<UAdminParkingSubscriptionPage> {
  final UAdminParkingSubscriptionController c = UAdminParkingSubscriptionController();

  @override
  void initState() {
    c.init(parking: widget.parking);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.subscriptions : "${U.s.subscriptions} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _showCreateDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UColumn(
      children: <Widget>[
        _filters(),
        UAdminListView<UParkingSubscriptionResponse>(
          state: c.state,
          items: () => c.list,
          totalCount: () => c.totalCount,
          onRetry: c.read,
          emptyText: U.s.noItemsFound(U.s.subscriptions),
          desktopHeader: () => <Widget>[
            UAdminTable.headerCell(U.s.licencePlate),
            UAdminTable.headerCell(U.s.fullName, flex: 2),
            UAdminTable.headerCell(U.s.subscriptionType),
            UAdminTable.headerCell(U.s.amount),
            UAdminTable.headerCell(U.s.validUntil),
            UAdminTable.headerCell(U.s.operations),
          ],
          desktopRow: _itemDesktop,
          mobileRow: _itemResponsive,
        ).expanded(),
      ],
    ),
  );

  Widget _filters() => URow(
    spacing: 8,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    children: <Widget>[
      UTextField(controller: c.controllerQuery, hintText: U.s.searchAndSelect, prefix: const Icon(Icons.search_rounded), expanded: 1),
      Obx(
        () => USegmentedControl<bool>(
          items: <bool, String>{true: U.s.active, false: U.s.expired},
          selectedValue: c.isActive.value ?? true,
          onValueChanged: (bool? value) {
            c.isActive(value ?? true);
            c.reloadFirstPage(c.read);
          },
        ),
      ),
      UButton(title: U.s.search, onTap: () => c.reloadFirstPage(c.read)),
    ],
  );

  String _duration(UParkingSubscriptionResponse i) => TagParkingSubscription.values.firstWhereOrNull((TagParkingSubscription t) => i.tags.contains(t.number))?.localizedTitle ?? "-";

  Widget _itemDesktop(UParkingSubscriptionResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.vehicle?.licencePlate ?? "-"),
      UAdminTable.cell(i.customerName.nullIfEmpty() ?? i.customerPhoneNumber.nullIfEmpty() ?? "-", flex: 2),
      UAdminTable.cell(_duration(i)),
      UAdminTable.cell(i.price.separate3By3()),
      UAdminTable.cell(i.expiryDate.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UParkingSubscriptionResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.card_membership_outlined,
    title: i.vehicle?.licencePlate ?? "-",
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.fullName, i.customerName.nullIfEmpty() ?? "-"),
      UAdminField(U.s.phoneNumber, i.customerPhoneNumber.nullIfEmpty() ?? "-"),
      UAdminField(U.s.subscriptionType, _duration(i)),
      UAdminField(U.s.amount, i.price.separate3By3()),
      UAdminField(U.s.validUntil, i.expiryDate.toJalaliDate()),
      UAdminField(U.s.daysDays(i.remainingDays.toString()), i.isExpired ? U.s.expired : U.s.active),
    ],
  );

  Widget _menu(UParkingSubscriptionResponse i) => UAdminOps.menu<UParkingSubscriptionResponse>(
    item: i,
    handlers: UAdminActionHandlers<UParkingSubscriptionResponse>(onDelete: c.delete),
    fallback: (UAdminActionContext<UParkingSubscriptionResponse> ctx) => <UAdminAction>[
      UAdminAction(label: U.s.renewSubscription, icon: Icons.autorenew_rounded, onTap: () => _renew(i)),
      ctx.delete(),
    ],
  );

  void _renew(UParkingSubscriptionResponse i) {
    final TagParkingSubscription duration = TagParkingSubscription.values.firstWhereOrNull((TagParkingSubscription t) => i.tags.contains(t.number)) ?? TagParkingSubscription.monthly;
    final int days = switch (duration) {
      TagParkingSubscription.weekly => 7,
      TagParkingSubscription.quarterly => 90,
      _ => 30,
    };
    final DateTime base = i.expiryDate.isAfter(DateTime.now()) ? i.expiryDate : DateTime.now();
    c.update(
      p: UParkingSubscriptionUpdateParams(
        id: i.id,
        expiryDate: base.add(Duration(days: days)),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final String? parkingId = widget.parking?.id;
    if (parkingId == null) return;

    final TextEditingController name = TextEditingController();
    final TextEditingController phone = TextEditingController();
    final TextEditingController price = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String plate = "";
    TagVehicle vehicleType = TagVehicle.car;
    TagParkingSubscription duration = TagParkingSubscription.monthly;

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(U.s.registerANewSubscription),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UPlateField(onPlateChange: (String value) => plate = value).pSymmetric(vertical: 6),
                    UDropDownField<TagVehicle>(
                      initialValue: vehicleType,
                      items: TagVehicle.values.map((TagVehicle v) => DropdownMenuItem<TagVehicle>(value: v, child: Text(v.localizedTitle))).toList(),
                      onChanged: (TagVehicle? value) => setDialogState(() => vehicleType = value ?? TagVehicle.car),
                    ).pSymmetric(vertical: 6),
                    UDropDownField<TagParkingSubscription>(
                      initialValue: duration,
                      items: <TagParkingSubscription>[
                        TagParkingSubscription.weekly,
                        TagParkingSubscription.monthly,
                        TagParkingSubscription.quarterly,
                      ].map((TagParkingSubscription v) => DropdownMenuItem<TagParkingSubscription>(value: v, child: Text(v.localizedTitle))).toList(),
                      onChanged: (TagParkingSubscription? value) => setDialogState(() => duration = value ?? TagParkingSubscription.monthly),
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: name, labelText: U.s.fullName, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, maxLength: 15, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(
                      controller: price,
                      labelText: U.s.amount,
                      keyboardType: TextInputType.number,
                      formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          if (plate.length < 6) return;
                          c.create(
                            p: UParkingSubscriptionCreateParams(
                              parkingId: parkingId,
                              licencePlate: plate,
                              vehicleType: vehicleType.number,
                              tags: <int>[duration.number],
                              customerName: name.text.nullIfEmpty(),
                              customerPhoneNumber: phone.trimmedLatin().nullIfEmpty(),
                              price: price.isNullOrEmpty() ? 0 : price.numDouble(),
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
      ),
    );
  }
}
