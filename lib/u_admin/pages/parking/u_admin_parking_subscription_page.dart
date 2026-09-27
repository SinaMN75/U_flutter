import "package:u/utilities.dart";

class UAdminParkingSubscriptionPage extends StatefulWidget {
  const UAdminParkingSubscriptionPage({super.key, this.parking});

  static void open({UParkingResponse? parking}) => U.addOrSwitchTab(
    parking == null ? U.s.subscriptions : "${U.s.subscriptions} · ${parking.title}",
    UAdminParkingSubscriptionPage(parking: parking),
  );

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.subscriptions,
    icon: Icons.card_membership_rounded,
    page: () => const UAdminParkingSubscriptionPage(),
    roles: roles,
  );

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.subscriptions : "${U.s.subscriptions} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _form,
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
      UObx(
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

  Widget _menu(UParkingSubscriptionResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.renewSubscription, icon: Icons.autorenew_rounded, onTap: () => c.renew(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  Future<void> _form() async {
    c.loadForm();
    await UAdminForm.editDialog(
      title: U.s.registerANewSubscription,
      formKey: c.formKey,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UPlateField(onPlateChange: (String v) => c.plate = v).pSymmetric(vertical: 6),
        UDropDownField<TagVehicle>(
          initialValue: c.vehicleType,
          items: TagVehicle.values.map((TagVehicle v) => DropdownMenuItem<TagVehicle>(value: v, child: Text(v.localizedTitle))).toList(),
          onChanged: (TagVehicle? v) => setState(() => c.vehicleType = v ?? TagVehicle.car),
        ).pSymmetric(vertical: 6),
        UDropDownField<TagParkingSubscription>(
          initialValue: c.duration,
          items: <TagParkingSubscription>[
            TagParkingSubscription.weekly,
            TagParkingSubscription.monthly,
            TagParkingSubscription.quarterly,
          ].map((TagParkingSubscription v) => DropdownMenuItem<TagParkingSubscription>(value: v, child: Text(v.localizedTitle))).toList(),
          onChanged: (TagParkingSubscription? v) => setState(() => c.duration = v ?? TagParkingSubscription.monthly),
        ).pSymmetric(vertical: 6),
        UAdminForm.text(c.name, U.s.fullName),
        UTextFieldPhoneNumber(controller: c.phone, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        UAdminForm.text(c.price, U.s.amount, money: true),
      ],
    );
  }
}
