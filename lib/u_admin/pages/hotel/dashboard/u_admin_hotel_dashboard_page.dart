import "package:u/utilities.dart";

class UAdminHotelDashboardPage extends StatefulWidget {
  const UAdminHotelDashboardPage({super.key});

  @override
  State<UAdminHotelDashboardPage> createState() => _HotelDashboardPageState();
}

class _HotelDashboardPageState extends State<UAdminHotelDashboardPage> {
  final UAdminHotelDashboardController c = UAdminHotelDashboardController();

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

  bool get _isWide => MediaQuery.sizeOf(context).width > 1000;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text("${U.s.accommodationDashboard} ⚡"),
      actions: <Widget>[IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: c.load)],
    ),
    body: UAdminPageBody(
      child: UObx(() {
        if (c.state.value.isError()) return TextButton(onPressed: c.load, child: Text(U.s.retry)).alignAtCenter();
        if (!c.state.value.isLoaded()) return const CircularProgressIndicator().alignAtCenter();
        final UPropertyDashboardResponse r = c.report.value!;
        return SingleChildScrollView(
          padding: EdgeInsets.all(_isWide ? 24 : 14),
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _hero(r).pSymmetric(vertical: 16),
              _entityCards(r).pSymmetric(vertical: 16),
              _occupancyAndRevenueSection(r).pSymmetric(vertical: 16),
              _cityBreakdownSection(r).pSymmetric(vertical: 16),
              _contractsAndInvoicesSection(r).pSymmetric(vertical: 16),
              _recentSection(r).pSymmetric(vertical: 16),
            ],
          ),
        );
      }),
    ),
  );

  Widget _hero(UPropertyDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(24),
    radius: 24,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Theme.of(context).colorScheme.primary, UAdminTheme.green.shade400, UAdminTheme.blue.shade400],
    ),
    boxShadow: <BoxShadow>[BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UIconTextHorizontal(
          leading: const Icon(Icons.apartment_rounded, color: UAdminTheme.white, size: 34),
          trailing: UTextHeadlineSmall(U.s.accommodationDashboard, color: UAdminTheme.white, fontWeight: FontWeight.w800),
        ),
        UAdminResponsiveGrid(
          minTileWidth: 150,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            UAdminDashboard.heroMetric(U.s.users, r.usersCount.separate3By3(), Icons.groups_rounded),
            UAdminDashboard.heroMetric(U.s.hotels, r.hotelsCount.separate3By3(), Icons.apartment_rounded),
            UAdminDashboard.heroMetric(U.s.dorms, r.dormsCount.separate3By3(), Icons.bedroom_parent_rounded),
            UAdminDashboard.heroMetric(U.s.contracts, r.contractsCount.separate3By3(), Icons.description_rounded),
            UAdminDashboard.heroMetric(U.s.invoices, r.invoicesCount.separate3By3(), Icons.receipt_long_rounded),
          ],
        ),
      ],
    ),
  );

  Widget _entityCards(UPropertyDashboardResponse r) => UAdminResponsiveGrid(
    children: <Widget>[
      UAdminDashboard.statCard(U.s.hotels, r.hotelsCount.separate3By3(), "${r.hotelRoomsCount} ${U.s.rooms}", Icons.apartment_rounded, UAdminTheme.indigo, UAdminPageSwitcher.hotels),
      UAdminDashboard.statCard(
        U.s.hotelOccupancy,
        "${r.hotelOccupancyRate}%",
        "${r.hotelRoomsOccupiedCount}/${r.hotelRoomsCount} ${U.s.occupied}",
        Icons.hotel_rounded,
        UAdminTheme.orange,
        UAdminPageSwitcher.hotelRooms,
      ),
      UAdminDashboard.statCard(U.s.dorms, r.dormsCount.separate3By3(), "${r.dormRoomsCount} ${U.s.rooms}", Icons.bedroom_parent_rounded, UAdminTheme.green, UAdminPageSwitcher.dormList),
      UAdminDashboard.statCard(
        U.s.dormOccupancy,
        "${r.dormOccupancyRate}%",
        "${r.dormBedsOccupiedCount}/${r.dormBedsCount} ${U.s.beds}",
        Icons.bed_rounded,
        UAdminTheme.pink,
        UAdminPageSwitcher.dormBeds,
      ),
      UAdminDashboard.statCard(
        U.s.contracts,
        r.contractsCount.separate3By3(),
        "${r.activeContractsCount} ${U.s.active}",
        Icons.description_rounded,
        UAdminTheme.blueGrey,
        UAdminPageSwitcher.contracts,
      ),
      UAdminDashboard.statCard(U.s.contractsExpiringSoon, r.expiringSoonContractsCount.separate3By3(), U.s.next30Days, Icons.event_busy_rounded, UAdminTheme.red, UAdminPageSwitcher.contracts),
      UAdminDashboard.statCard(
        U.s.invoices,
        r.invoicesCount.separate3By3(),
        "${r.unpaidInvoicesCount} ${U.s.unpaid}",
        Icons.receipt_long_rounded,
        UAdminTheme.yellow.shade900,
        UAdminPageSwitcher.invoices,
      ),
      UAdminDashboard.statCard(U.s.overdueInvoices, r.overdueInvoicesCount.separate3By3(), r.totalOutstanding.rial(), Icons.warning_amber_rounded, UAdminTheme.red, UAdminPageSwitcher.invoices),
    ],
  );

  Widget _occupancyAndRevenueSection(UPropertyDashboardResponse r) => _isWide
      ? URow(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _monthlyRevenueChart(r).expanded(flex: 2),
            const SizedBox(width: 16),
            _occupancyChart(r).expanded(),
          ],
        )
      : UColumn(
          children: <Widget>[
            _monthlyRevenueChart(r),
            const SizedBox(height: 16),
            _occupancyChart(r),
          ],
        );

  Widget _monthlyRevenueChart(UPropertyDashboardResponse r) {
    if (r.monthlyRevenue.isEmpty) return UAdminDashboard.chartCard(context, title: U.s.monthlyRevenue, child: UTextBodySmall(U.s.noData).alignAtCenter());
    return UAdminDashboard.chartCard(
      context,
      title: U.s.monthlyRevenueDebtPaidPenalty,
      child: UBarChart(
        categories: r.monthlyRevenue.map((UDormBedInvoiceChartResponse d) => d.month).toList(),
        series: <UChartSeries>[
          UChartSeries(name: U.s.debt, color: UAdminTheme.blueGrey, values: r.monthlyRevenue.map((UDormBedInvoiceChartResponse d) => d.totalDebt.toDouble()).toList()),
          UChartSeries(name: U.s.paid, color: UAdminTheme.green, values: r.monthlyRevenue.map((UDormBedInvoiceChartResponse d) => d.totalPaid.toDouble()).toList()),
          UChartSeries(name: U.s.penalty, color: UAdminTheme.red, values: r.monthlyRevenue.map((UDormBedInvoiceChartResponse d) => d.totalPenalty.toDouble()).toList()),
        ],
      ),
    );
  }

  Widget _occupancyChart(UPropertyDashboardResponse r) => UAdminDashboard.chartCard(
    context,
    title: U.s.occupancy,
    child: UDonutChart(
      holeFactor: 0.55,
      slices: <USlice>[
        USlice(value: r.hotelRoomsOccupiedCount.toDouble(), label: U.s.hotelOccupied, color: UAdminTheme.orange),
        USlice(value: r.hotelRoomsAvailableCount.toDouble(), label: U.s.hotelAvailable, color: UAdminTheme.orange.shade100),
        USlice(value: r.dormBedsOccupiedCount.toDouble(), label: U.s.dormOccupied, color: UAdminTheme.green),
        USlice(value: r.dormBedsAvailableCount.toDouble(), label: U.s.dormAvailable, color: UAdminTheme.green.shade100),
      ],
    ),
  );

  Widget _cityBreakdownSection(UPropertyDashboardResponse r) =>
      _pair(_cityBarChart(U.s.hotelsByCity, r.hotelsByCity, UAdminTheme.indigo), _cityBarChart(U.s.dormsByCity, r.dormsByCity, UAdminTheme.green));

  Widget _cityBarChart(String title, List<UPropertyBreakdownItem> items, Color color) => UAdminDashboard.chartCard(
    context,
    title: title,
    child: items.isEmpty
        ? UTextBodySmall(U.s.noData).alignAtCenter()
        : UHorizontalBarChart(
            categories: items.map((UPropertyBreakdownItem d) => d.name).toList(),
            series: <UChartSeries>[UChartSeries(color: color, values: items.map((UPropertyBreakdownItem d) => d.count.toDouble()).toList())],
          ),
  );

  Widget _contractsAndInvoicesSection(UPropertyDashboardResponse r) => _pair(
    _list<UExpiringContractItem>(
      Icons.event_busy_rounded,
      U.s.contractsExpiringSoon,
      U.s.contracts,
      UAdminPageSwitcher.contracts,
      r.expiringContracts,
      (UExpiringContractItem i, int _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.bed_rounded),
        title: Text("${i.userName ?? "-"} · ${i.dormTitle} / ${i.bedTitle}"),
        subtitle: Text("${U.s.ends} ${i.endDate.toJalaliDate()} · ${i.rent.rial()}"),
      ),
    ),
    _list<UOverdueInvoiceItem>(
      Icons.warning_amber_rounded,
      U.s.overdueInvoices,
      U.s.invoices,
      UAdminPageSwitcher.invoices,
      r.overdueInvoices,
      (UOverdueInvoiceItem i, int _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.receipt_long_rounded, color: UAdminTheme.red),
        title: Text(i.userName ?? "-"),
        subtitle: Text("${U.s.due} ${i.dueDate.toJalaliDate()} · ${i.daysOverdue} ${U.s.daysOverdue}"),
        trailing: UTextBodyMedium(i.debtAmount.rial(), fontWeight: FontWeight.w700),
      ),
    ),
  );

  Widget _recentSection(UPropertyDashboardResponse r) => _pair(
    _list<URecentContractItem>(
      Icons.description_rounded,
      U.s.recentContracts,
      U.s.contracts,
      UAdminPageSwitcher.contracts,
      r.recentContracts,
      (URecentContractItem i, int _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.description_rounded),
        title: Text("${i.userName ?? "-"} · ${i.dormTitle} / ${i.bedTitle}"),
        subtitle: Text("${i.startDate.toJalaliDate()} → ${i.endDate.toJalaliDate()} · ${i.rent.rial()}"),
      ),
    ),
    _list<URecentUserItem>(
      Icons.person_add_alt_1_rounded,
      U.s.recentlyJoined,
      U.s.users,
      UAdminPageSwitcher.adminUsers,
      r.recentUsers,
      (URecentUserItem u, int index) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: UAdminTheme.primaries[index % UAdminTheme.primaries.length].shade100,
          child: Text(u.displayName.isNotEmpty ? u.displayName.substring(0, 1).toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(u.displayName),
        subtitle: Text(u.userName ?? u.phoneNumber ?? ""),
      ),
    ),
  );

  /// Two cards side by side on a wide screen, stacked otherwise.
  Widget _pair(Widget a, Widget b) =>
      _isWide ? URow(crossAxisAlignment: CrossAxisAlignment.start, spacing: 16, children: <Widget>[a.expanded(), b.expanded()]) : UColumn(spacing: 16, children: <Widget>[a, b]);

  /// A titled card listing [items], with a link to the page that has all of them.
  Widget _list<T>(IconData icon, String title, String linkTitle, VoidCallback onLink, List<T> items, Widget Function(T item, int index) tile) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 8,
          children: <Widget>[
            Icon(icon, size: 20),
            UTextTitleSmall(title, fontWeight: FontWeight.w700, expanded: 1),
            TextButton(onPressed: onLink, child: Text(linkTitle)),
          ],
        ),
        const Divider(height: 16),
        if (items.isEmpty)
          UTextBodySmall(U.s.noData, margin: const EdgeInsets.symmetric(vertical: 12))
        else
          for (int i = 0; i < items.length; i++) ...<Widget>[if (i > 0) const Divider(height: 8), tile(items[i], i)],
      ],
    ),
  );
}
