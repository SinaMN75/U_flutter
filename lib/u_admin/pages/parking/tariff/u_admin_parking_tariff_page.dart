part of "../../../u_admin.dart";

class UAdminParkingTariffPage extends StatefulWidget {
  const UAdminParkingTariffPage({super.key, this.parking});

  static UAdminModule module({List<TagUser>? roles, UParkingResponse? parking}) => UAdminModule(
    title: parking == null ? U.s.tariffs : "${U.s.tariffs} · ${parking.title}",
    icon: Icons.request_quote_rounded,
    page: () => UAdminParkingTariffPage(parking: parking),
    roles: roles,
  );

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.tariffs : "${U.s.tariffs} · ${widget.parking!.title}",
    onCreate: widget.parking == null ? null : _form,
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
        UAdminTable.headerCell(U.s.nightRate),
        UAdminTable.headerCell(U.s.dailyCap),
        UAdminTable.headerCell(U.s.monthly),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
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

  Widget _itemMobile(UParkingTariffResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.request_quote_outlined,
    title: _vehicle(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.entrancePrice, i.entrancePrice.separate3By3()),
      UAdminField(U.s.dayRate, i.dayHourlyPrice.separate3By3()),
      UAdminField(U.s.nightRate, i.nightHourlyPrice.separate3By3()),
      UAdminField(U.s.dailyCap, i.dailyCap.separate3By3()),
      UAdminField(U.s.weekly, i.weeklyPrice.separate3By3()),
      UAdminField(U.s.monthly, i.monthlyPrice.separate3By3()),
      UAdminField(U.s.quarterly, i.quarterlyPrice.separate3By3()),
    ],
  );

  Widget _menu(UParkingTariffResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  Future<void> _form([UParkingTariffResponse? t]) async {
    c.loadForm(t);
    await UFormDialog.show(
      title: t == null ? U.s.createItem(U.s.tariff) : U.s.editItem(U.s.tariff),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<TagVehicle>(
          initialValue: c.vehicleType,
          items: TagVehicle.values.map((TagVehicle v) => DropdownMenuItem<TagVehicle>(value: v, child: Text(v.localizedTitle))).toList(),
          onChanged: (TagVehicle? v) => setState(() => c.vehicleType = v ?? TagVehicle.car),
        ).pSymmetric(vertical: 6),
        UTextField(
          controller: c.entranceController,
          labelText: U.s.entrancePrice,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.dayHourlyController,
          labelText: U.s.dayRate,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.nightHourlyController,
          labelText: U.s.nightRate,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.dailyCapController,
          labelText: U.s.dailyCap,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.weeklyController,
          labelText: U.s.weekly,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.monthlyController,
          labelText: U.s.monthly,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.quarterlyController,
          labelText: U.s.quarterly,
          keyboardType: TextInputType.number,
          formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(
          controller: c.freeMinutesController,
          labelText: U.s.firstMinutesMinutesFree(c.freeMinutesController.text),
          keyboardType: TextInputType.number,
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        SwitchListTile(
          value: c.roundToFullHour,
          title: UTextBodyMedium(U.s.roundUpToAFullHour),
          contentPadding: EdgeInsets.zero,
          onChanged: (bool v) => setState(() => c.roundToFullHour = v),
        ),
        SwitchListTile(
          value: c.perMinuteAfterFirstHour,
          title: UTextBodyMedium(U.s.perMinuteAfterTheFirstHour),
          contentPadding: EdgeInsets.zero,
          onChanged: (bool v) => setState(() => c.perMinuteAfterFirstHour = v),
        ),
      ],
    );
  }
}
