import "package:u/utilities.dart";

class UAdminParkingPlateFlagPage extends StatefulWidget {
  const UAdminParkingPlateFlagPage({super.key, this.parking});

  final UParkingResponse? parking;

  @override
  State<UAdminParkingPlateFlagPage> createState() => _UAdminParkingPlateFlagPageState();
}

class _UAdminParkingPlateFlagPageState extends State<UAdminParkingPlateFlagPage> {
  final UAdminParkingPlateFlagController c = UAdminParkingPlateFlagController();

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
    title: widget.parking == null ? U.s.specialPlates : "${U.s.specialPlates} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _form,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UParkingPlateFlagResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.specialPlates),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.licencePlate),
        UAdminTable.headerCell(U.s.type),
        UAdminTable.headerCell(U.s.reason, flex: 2),
        UAdminTable.headerCell(U.s.amount),
        UAdminTable.headerCell(U.s.parkingSpot),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  String _kind(UParkingPlateFlagResponse i) => TagParkingPlateFlag.values.firstWhereOrNull((TagParkingPlateFlag t) => i.tags.contains(t.number))?.localizedTitle ?? "-";

  Widget _itemDesktop(UParkingPlateFlagResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.licencePlate),
      UAdminTable.cell(_kind(i)),
      UAdminTable.cell(i.reason.nullIfEmpty() ?? "-", flex: 2),
      UAdminTable.cell(i.amount == null ? "-" : i.amount!.separate3By3()),
      UAdminTable.cell(i.spotNumber.nullIfEmpty() ?? "-"),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UParkingPlateFlagResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.gpp_maybe_outlined,
    title: i.licencePlate,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.type, _kind(i)),
      UAdminField(U.s.reason, i.reason.nullIfEmpty() ?? "-"),
      UAdminField(U.s.amount, i.amount == null ? "-" : i.amount!.separate3By3()),
      UAdminField(U.s.parkingSpot, i.spotNumber.nullIfEmpty() ?? "-"),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UParkingPlateFlagResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  Future<void> _form() async {
    c.loadForm();
    await UAdminForm.editDialog(
      title: U.s.addPlate,
      formKey: c.formKey,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UPlateField(onPlateChange: (String v) => c.plate = v).pSymmetric(vertical: 6),
        UDropDownField<TagParkingPlateFlag>(
          initialValue: c.kind,
          items: TagParkingPlateFlag.values.map((TagParkingPlateFlag v) => DropdownMenuItem<TagParkingPlateFlag>(value: v, child: Text(v.localizedTitle))).toList(),
          onChanged: (TagParkingPlateFlag? v) => setState(() => c.kind = v ?? TagParkingPlateFlag.debt),
        ).pSymmetric(vertical: 6),
        UAdminForm.text(c.reason, U.s.reason, lines: 2),
        if (c.kind == TagParkingPlateFlag.debt) UAdminForm.text(c.amount, U.s.amount, money: true),
        if (c.kind == TagParkingPlateFlag.reservation) UAdminForm.text(c.spotNumber, U.s.spotNumber),
      ],
    );
  }
}
