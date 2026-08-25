import "package:u/utilities.dart";

class UAdminParkingReportPage extends StatefulWidget {
  const UAdminParkingReportPage({super.key, this.parking});
  final UParkingResponse? parking;

  @override
  State<UAdminParkingReportPage> createState() => _UAdminParkingReportPageState();
}

class _UAdminParkingReportPageState extends State<UAdminParkingReportPage> {
  final UAdminParkingReportController c = UAdminParkingReportController();

  @override
  void initState() {
    c.init(parking: widget.parking);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.parking == null ? U.s.parkingReports : "${U.s.parkingReports} · ${widget.parking!.title}",
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UColumn(children: <Widget>[_summary(), _list().expanded()]),
  );

  Widget _summary() => Obx(() {
    if (!c.state.isLoaded()) return const SizedBox.shrink();
    return UContainer(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      radius: 10,
      child: URow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          UTextBodyMedium("${U.s.totalResults}: ${c.totalCount.toString().separateNumbers3By3()}"),
          UTextBodyMedium("${U.s.amount}: ${c.totalAmount.rial()}", fontWeight: FontWeight.bold),
        ],
      ),
    );
  });

  Widget _list() => UAdminListView<UParkingReportResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.noItemsFound(U.s.parkingReport),
    desktopHeader: () => <Widget>[
      UAdminTable.headerCell(U.s.parking, flex: 2),
      UAdminTable.headerCell(U.s.licencePlate, flex: 2),
      UAdminTable.headerCell(U.s.startDate),
      UAdminTable.headerCell(U.s.endDate),
      UAdminTable.headerCell(U.s.amount),
      UAdminTable.headerCell(U.s.operations, flex: 0),
    ],
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _itemDesktop(UParkingReportResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.parking?.title ?? "-", flex: 2),
      UAdminTable.cell(i.vehicle?.licencePlate ?? "-", flex: 2),
      UAdminTable.cell(i.startDate.toJalaliDate()),
      UAdminTable.cell(i.endDate?.toJalaliDate() ?? "-"),
      UAdminTable.cell((i.amount ?? 0).rial()),
      IconButton(
        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error, size: 20),
        onPressed: () => c.delete(i),
      ).expanded(flex: 0),
    ],
  );

  Widget _itemResponsive(UParkingReportResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.directions_car_rounded,
    title: i.vehicle?.licencePlate ?? "-",
    subtitle: i.parking?.title,
    trailing: IconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error, size: 20),
      onPressed: () => c.delete(i),
    ),
    fields: <UAdminField>[
      UAdminField(U.s.parking, i.parking?.title ?? "-"),
      UAdminField(U.s.startDate, i.startDate.toJalaliDate()),
      UAdminField(U.s.endDate, i.endDate?.toJalaliDate() ?? "-"),
      UAdminField(U.s.amount, (i.amount ?? 0).rial()),
    ],
  );
}
