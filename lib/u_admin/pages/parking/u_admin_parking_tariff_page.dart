import "package:u/utilities.dart";

class UAdminParkingTariffPage extends StatefulWidget {
  const UAdminParkingTariffPage({super.key, this.parking});

  final UParkingResponse? parking;

  @override
  State<UAdminParkingTariffPage> createState() => _UAdminParkingTariffPageState();
}

class _UAdminParkingTariffPageState extends State<UAdminParkingTariffPage> {
  final UAdminParkingTariffController c = UAdminParkingTariffController();

  @override
  void initState() {
    c.init(parking: widget.parking);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.tariffs : "${U.s.tariffs} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _showEditDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UParkingTariffResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.tariffs),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.vehicleType),
        UAdminTable.headerCell(U.s.entrancePrice),
        UAdminTable.headerCell(U.s.dayRate),
        UAdminTable.headerCell(U.s.nightRateTitle),
        UAdminTable.headerCell(U.s.dailyCap),
        UAdminTable.headerCell(U.s.monthly),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  String _vehicle(UParkingTariffResponse i) => TagVehicle.values.fromNumber(i.vehicleType)?.localizedTitle ?? "-";

  Widget _itemDesktop(UParkingTariffResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_vehicle(i)),
      UAdminTable.cell(i.entrancePrice.separate3By3()),
      UAdminTable.cell(i.dayHourlyPrice.separate3By3()),
      UAdminTable.cell(i.nightHourlyPrice.separate3By3()),
      UAdminTable.cell(i.dailyCap.separate3By3()),
      UAdminTable.cell(i.monthlyPrice.separate3By3()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UParkingTariffResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.request_quote_outlined,
    title: _vehicle(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.entrancePrice, i.entrancePrice.separate3By3()),
      UAdminField(U.s.dayRate, i.dayHourlyPrice.separate3By3()),
      UAdminField(U.s.nightRateTitle, i.nightHourlyPrice.separate3By3()),
      UAdminField(U.s.dailyCap, i.dailyCap.separate3By3()),
      UAdminField(U.s.weekly, i.weeklyPrice.separate3By3()),
      UAdminField(U.s.monthly, i.monthlyPrice.separate3By3()),
      UAdminField(U.s.quarterly, i.quarterlyPrice.separate3By3()),
    ],
  );

  Widget _menu(UParkingTariffResponse i) => UAdminOps.menu<UParkingTariffResponse>(
    item: i,
    handlers: UAdminActionHandlers<UParkingTariffResponse>(
      onEdit: (UParkingTariffResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UParkingTariffResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  Future<void> _showEditDialog({UParkingTariffResponse? p}) async {
    final String? parkingId = p?.parkingId ?? widget.parking?.id;
    if (parkingId == null) return;

    final TextEditingController entrance = TextEditingController(text: p?.entrancePrice.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController dayHourly = TextEditingController(text: p?.dayHourlyPrice.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController nightHourly = TextEditingController(text: p?.nightHourlyPrice.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController dailyCap = TextEditingController(text: p?.dailyCap.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController weekly = TextEditingController(text: p?.weeklyPrice.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController monthly = TextEditingController(text: p?.monthlyPrice.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController quarterly = TextEditingController(text: p?.quarterlyPrice.toStringAsSmartRound(maxPrecision: 0));
    final TextEditingController freeMinutes = TextEditingController(text: (p?.freeMinutes ?? 0).toString());
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    TagVehicle vehicleType = TagVehicle.values.fromNumber(p?.vehicleType ?? TagVehicle.car.number) ?? TagVehicle.car;
    bool roundToFullHour = p?.roundToFullHour ?? false;
    bool perMinuteAfterFirstHour = p?.perMinuteAfterFirstHour ?? true;

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.tariff) : U.s.editItem(U.s.tariff)),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UDropDownField<TagVehicle>(
                      initialValue: vehicleType,
                      items: TagVehicle.values.map((TagVehicle v) => DropdownMenuItem<TagVehicle>(value: v, child: Text(v.localizedTitle))).toList(),
                      onChanged: (TagVehicle? value) => setDialogState(() => vehicleType = value ?? TagVehicle.car),
                    ).pSymmetric(vertical: 6),
                    _money(entrance, U.s.entrancePrice),
                    _money(dayHourly, U.s.dayRate),
                    _money(nightHourly, U.s.nightRateTitle),
                    _money(dailyCap, U.s.dailyCap),
                    _money(weekly, U.s.weekly),
                    _money(monthly, U.s.monthly),
                    _money(quarterly, U.s.quarterly),
                    UTextField(controller: freeMinutes, labelText: U.s.firstMinutesFreeRule(freeMinutes.text), keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                    SwitchListTile(
                      value: roundToFullHour,
                      title: UTextBodyMedium(U.s.roundToFullHour),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool v) => setDialogState(() => roundToFullHour = v),
                    ),
                    SwitchListTile(
                      value: perMinuteAfterFirstHour,
                      title: UTextBodyMedium(U.s.perMinuteAfterFirstHour),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool v) => setDialogState(() => perMinuteAfterFirstHour = v),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          c.save(
                            p: UParkingTariffCreateParams(
                              parkingId: parkingId,
                              vehicleType: vehicleType.number,
                              tags: <int>[TagParkingTariff.hourly.number, TagParkingTariff.subscription.number],
                              entrancePrice: entrance.isNullOrEmpty() ? 0 : entrance.numDouble(),
                              dayHourlyPrice: dayHourly.isNullOrEmpty() ? 0 : dayHourly.numDouble(),
                              nightHourlyPrice: nightHourly.isNullOrEmpty() ? 0 : nightHourly.numDouble(),
                              dailyCap: dailyCap.isNullOrEmpty() ? 0 : dailyCap.numDouble(),
                              weeklyPrice: weekly.isNullOrEmpty() ? 0 : weekly.numDouble(),
                              monthlyPrice: monthly.isNullOrEmpty() ? 0 : monthly.numDouble(),
                              quarterlyPrice: quarterly.isNullOrEmpty() ? 0 : quarterly.numDouble(),
                              freeMinutes: freeMinutes.isNullOrEmpty() ? 0 : freeMinutes.numInt(),
                              roundToFullHour: roundToFullHour,
                              perMinuteAfterFirstHour: perMinuteAfterFirstHour,
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

  Widget _money(TextEditingController controller, String label) => UTextField(
    controller: controller,
    labelText: label,
    keyboardType: TextInputType.number,
    formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
    margin: const EdgeInsets.symmetric(vertical: 6),
  );
}
