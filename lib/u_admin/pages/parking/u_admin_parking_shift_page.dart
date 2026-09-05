import "package:u/utilities.dart";

class UAdminParkingShiftPage extends StatefulWidget {
  const UAdminParkingShiftPage({super.key, this.parking});

  final UParkingResponse? parking;

  @override
  State<UAdminParkingShiftPage> createState() => _UAdminParkingShiftPageState();
}

class _UAdminParkingShiftPageState extends State<UAdminParkingShiftPage> {
  final UAdminParkingShiftController c = UAdminParkingShiftController();

  @override
  void initState() {
    c.init(parking: widget.parking);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.shift : "${U.s.shift} · ${widget.parking!.title}",
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UColumn(
      children: <Widget>[
        Obx(() {
          if (!c.state.isLoaded()) return const SizedBox.shrink();
          return UContainer(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            radius: 10,
            child: URow(
              spacing: 16,
              children: <Widget>[
                UTextTitleMedium("${U.s.shiftRevenue}: ${c.totalRevenue.separate3By3()}"),
                const Spacer(),
                UTextBodyMedium("${U.s.total}: ${c.totalCount}"),
              ],
            ),
          );
        }),
        UAdminListView<UParkingShiftResponse>(
          state: c.state,
          items: () => c.list,
          totalCount: () => c.totalCount,
          onRetry: c.read,
          emptyText: U.s.noItemsFound(U.s.shift),
          desktopHeader: () => <Widget>[
            UAdminTable.headerCell(U.s.operator, flex: 2),
            UAdminTable.headerCell(U.s.shiftStarted),
            UAdminTable.headerCell(U.s.cashTotal),
            UAdminTable.headerCell(U.s.cardTotal),
            UAdminTable.headerCell(U.s.gatewayTotal),
            UAdminTable.headerCell(U.s.cashDifference),
          ],
          desktopRow: _itemDesktop,
          mobileRow: _itemResponsive,
        ).expanded(),
      ],
    ),
  );

  String _operator(UParkingShiftResponse i) => i.creator?.displayName.nullIfEmpty() ?? i.creator?.userName ?? "-";

  Widget _itemDesktop(UParkingShiftResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_operator(i), flex: 2),
      UAdminTable.cell(i.startDate.toJalaliDate()),
      UAdminTable.cell(i.cashTotal.separate3By3()),
      UAdminTable.cell(i.cardTotal.separate3By3()),
      UAdminTable.cell(i.ipgTotal.separate3By3()),
      UAdminTable.cell(i.cashDifference.separate3By3()),
    ],
  );

  Widget _itemResponsive(UParkingShiftResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.point_of_sale_outlined,
    title: _operator(i),
    fields: <UAdminField>[
      UAdminField(U.s.shiftStarted, "${i.startDate.toJalaliDate()} ${i.startDate.hour}:${i.startDate.minute}"),
      UAdminField(U.s.countEntries(i.entryCount.toString()), U.s.countExits(i.exitCount.toString())),
      UAdminField(U.s.cashTotal, i.cashTotal.separate3By3()),
      UAdminField(U.s.cardTotal, i.cardTotal.separate3By3()),
      UAdminField(U.s.gatewayTotal, i.ipgTotal.separate3By3()),
      UAdminField(U.s.countedCash, i.countedCash.separate3By3()),
      UAdminField(U.s.cashDifference, i.cashDifference.separate3By3()),
      UAdminField(i.endDate == null ? U.s.active : U.s.theShiftWasClosed, i.endDate?.toJalaliDate() ?? "-"),
    ],
  );
}
