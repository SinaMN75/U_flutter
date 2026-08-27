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
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.specialPlates : "${U.s.specialPlates} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _showCreateDialog,
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
    context,
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

  Widget _menu(UParkingPlateFlagResponse i) => UAdminOps.menu<UParkingPlateFlagResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UParkingPlateFlagResponse>(onDelete: c.delete),
    fallback: (UAdminActionContext<UParkingPlateFlagResponse> ctx) => <UAdminAction>[ctx.delete()],
  );

  Future<void> _showCreateDialog() async {
    final String? parkingId = widget.parking?.id;
    if (parkingId == null) return;

    final TextEditingController reason = TextEditingController();
    final TextEditingController amount = TextEditingController();
    final TextEditingController spotNumber = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String plate = "";
    TagParkingPlateFlag kind = TagParkingPlateFlag.debt;

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(U.s.addPlate),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UPlateField(onPlateChange: (String value) => plate = value).pSymmetric(vertical: 6),
                    UDropDownField<TagParkingPlateFlag>(
                      initialValue: kind,
                      items: TagParkingPlateFlag.values.map((TagParkingPlateFlag v) => DropdownMenuItem<TagParkingPlateFlag>(value: v, child: Text(v.localizedTitle))).toList(),
                      onChanged: (TagParkingPlateFlag? value) => setDialogState(() => kind = value ?? TagParkingPlateFlag.debt),
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: reason, labelText: U.s.reason, lines: 2).pSymmetric(vertical: 6),
                    if (kind == TagParkingPlateFlag.debt)
                      UTextField(
                        controller: amount,
                        labelText: U.s.amount,
                        keyboardType: TextInputType.number,
                        formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                      ).pSymmetric(vertical: 6),
                    if (kind == TagParkingPlateFlag.reservation) UTextField(controller: spotNumber, labelText: U.s.spotNumber).pSymmetric(vertical: 6),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          if (plate.length < 6) return;
                          c.create(
                            p: UParkingPlateFlagCreateParams(
                              parkingId: parkingId,
                              licencePlate: plate,
                              tags: <int>[kind.number],
                              reason: reason.text.nullIfEmpty(),
                              amount: amount.isNullOrEmpty() ? null : amount.numDouble(),
                              spotNumber: spotNumber.text.nullIfEmpty(),
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
