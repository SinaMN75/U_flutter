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

  bool get _isWide => MediaQuery.sizeOf(context).width > 1000;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text("${U.s.propertyDashboard} ⚡"),
      actions: <Widget>[IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: c.load)],
    ),
    body: Obx(() {
      if (c.state.value.isError()) return TextButton(onPressed: c.load, child: Text(U.s.retry)).alignAtCenter();
      if (!c.state.value.isLoaded()) return const CircularProgressIndicator().alignAtCenter();
      final UPropertyDashboardResponse r = c.report.value!;
      return SingleChildScrollView(
        padding: EdgeInsets.all(_isWide ? 24 : 14),
        child: UColumn(
          spacing: 0,
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
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UIconTextHorizontal(
          leading: const Icon(Icons.apartment_rounded, color: UAdminTheme.white, size: 34),
          trailing: UTextHeadlineSmall(U.s.propertyDashboard, color: UAdminTheme.white, fontWeight: FontWeight.w800),
        ),
        UAdminResponsiveGrid(
          minTileWidth: 150,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _heroMetric(U.s.users, r.usersCount.separate3By3(), Icons.groups_rounded),
            _heroMetric(U.s.hotels, r.hotelsCount.separate3By3(), Icons.apartment_rounded),
            _heroMetric(U.s.dorms, r.dormsCount.separate3By3(), Icons.bedroom_parent_rounded),
            _heroMetric(U.s.contracts, r.contractsCount.separate3By3(), Icons.description_rounded),
            _heroMetric(U.s.invoices, r.invoicesCount.separate3By3(), Icons.receipt_long_rounded),
          ],
        ),
      ],
    ),
  );

  Widget _heroMetric(String label, String value, IconData icon) => ListTile(
    leading: UIconBackground(icon, color: UAdminTheme.white),
    title: UTextBodyMedium(label, color: UAdminTheme.white),
    subtitle: UTextBodyLarge(value, color: UAdminTheme.white),
  );

  Widget _entityCards(UPropertyDashboardResponse r) => UAdminResponsiveGrid(
    children: <Widget>[
      _statCard(U.s.hotels, r.hotelsCount.separate3By3(), "${r.hotelRoomsCount} ${U.s.rooms}", Icons.apartment_rounded, UAdminTheme.indigo, UAdminPageSwitcher.hotels),
      _statCard(
        U.s.hotelOccupancy,
        "${r.hotelOccupancyRate}%",
        "${r.hotelRoomsOccupiedCount}/${r.hotelRoomsCount} ${U.s.occupied}",
        Icons.hotel_rounded,
        UAdminTheme.orange,
        UAdminPageSwitcher.hotelRooms,
      ),
      _statCard(U.s.dorms, r.dormsCount.separate3By3(), "${r.dormRoomsCount} ${U.s.rooms}", Icons.bedroom_parent_rounded, UAdminTheme.green, UAdminPageSwitcher.dormList),
      _statCard(U.s.dormOccupancy, "${r.dormOccupancyRate}%", "${r.dormBedsOccupiedCount}/${r.dormBedsCount} ${U.s.beds}", Icons.bed_rounded, UAdminTheme.pink, UAdminPageSwitcher.dormBeds),
      _statCard(U.s.contracts, r.contractsCount.separate3By3(), "${r.activeContractsCount} ${U.s.active}", Icons.description_rounded, UAdminTheme.blueGrey, UAdminPageSwitcher.contracts),
      _statCard(U.s.contractsExpiringSoon, r.expiringSoonContractsCount.separate3By3(), U.s.next30Days, Icons.event_busy_rounded, UAdminTheme.red, UAdminPageSwitcher.contracts),
      _statCard(U.s.invoices, r.invoicesCount.separate3By3(), "${r.unpaidInvoicesCount} ${U.s.unpaid}", Icons.receipt_long_rounded, UAdminTheme.yellow.shade900, UAdminPageSwitcher.invoices),
      _statCard(U.s.overdueInvoices, r.overdueInvoicesCount.separate3By3(), r.totalOutstanding.rial(), Icons.warning_amber_rounded, UAdminTheme.red, UAdminPageSwitcher.invoices),
    ],
  );

  Widget _statCard(String title, String value, String sub, IconData icon, Color color, VoidCallback? onTap) => UCard(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: UIconBackground(icon, color: color),
      title: UTextTitleMedium(value, fontWeight: FontWeight.w800, maxLines: 1),
      subtitle: UTextBodySmall(title, color: UAdminTheme.grey),
      trailing: sub.isNullOrEmpty() ? null : UTextBodySmall(sub, color: color, fontWeight: FontWeight.w600),
      onTap: onTap,
    ),
  );

  Widget _occupancyAndRevenueSection(UPropertyDashboardResponse r) => _isWide
      ? URow(
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _monthlyRevenueChart(r).expanded(flex: 2),
            const SizedBox(width: 16),
            _occupancyChart(r).expanded(),
          ],
        )
      : UColumn(
          spacing: 0,
          children: <Widget>[
            _monthlyRevenueChart(r),
            const SizedBox(height: 16),
            _occupancyChart(r),
          ],
        );

  Widget _monthlyRevenueChart(UPropertyDashboardResponse r) {
    if (r.monthlyRevenue.isEmpty) return _chartCard(title: U.s.monthlyRevenue, child: UTextBodySmall(U.s.noData).alignAtCenter());
    return _chartCard(
      title: U.s.monthlyRevenueDebtPaidPenalty,
      child: UBarChart(
        categories: r.monthlyRevenue.map((UDormBedInvoiceChartItem d) => d.month).toList(),
        series: <UChartSeries>[
          UChartSeries(name: U.s.debt, color: UAdminTheme.blueGrey, values: r.monthlyRevenue.map((UDormBedInvoiceChartItem d) => d.totalDebt.toDouble()).toList()),
          UChartSeries(name: U.s.paid, color: UAdminTheme.green, values: r.monthlyRevenue.map((UDormBedInvoiceChartItem d) => d.totalPaid.toDouble()).toList()),
          UChartSeries(name: U.s.penalty, color: UAdminTheme.red, values: r.monthlyRevenue.map((UDormBedInvoiceChartItem d) => d.totalPenalty.toDouble()).toList()),
        ],
      ),
    );
  }

  Widget _occupancyChart(UPropertyDashboardResponse r) => _chartCard(
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

  Widget _cityBreakdownSection(UPropertyDashboardResponse r) => _isWide
      ? URow(
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _cityBarChart(U.s.hotelsByCity, r.hotelsByCity, UAdminTheme.indigo).expanded(),
            const SizedBox(width: 16),
            _cityBarChart(U.s.dormsByCity, r.dormsByCity, UAdminTheme.green).expanded(),
          ],
        )
      : UColumn(
          spacing: 0,
          children: <Widget>[_cityBarChart(U.s.hotelsByCity, r.hotelsByCity, UAdminTheme.indigo), const SizedBox(height: 16), _cityBarChart(U.s.dormsByCity, r.dormsByCity, UAdminTheme.green)],
        );

  Widget _cityBarChart(String title, List<UPropertyBreakdownItem> items, Color color) => _chartCard(
    title: title,
    child: items.isEmpty
        ? UTextBodySmall(U.s.noData).alignAtCenter()
        : UHorizontalBarChart(
            categories: items.map((UPropertyBreakdownItem d) => d.name).toList(),
            series: <UChartSeries>[UChartSeries(color: color, values: items.map((UPropertyBreakdownItem d) => d.count.toDouble()).toList())],
          ),
  );

  Widget _chartCard({required String title, required Widget child}) => UContainer(
    height: 320,
    padding: const EdgeInsets.all(18),
    radius: 20,
    color: Theme.of(context).cardTheme.color,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextTitleSmall(title, fontWeight: FontWeight.w700),
        const Divider(height: 18),
        child.expanded(),
      ],
    ),
  );

  Widget _contractsAndInvoicesSection(UPropertyDashboardResponse r) => _isWide
      ? URow(spacing: 0, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[_expiringContracts(r).expanded(), const SizedBox(width: 16), _overdueInvoices(r).expanded()])
      : UColumn(spacing: 0, children: <Widget>[_expiringContracts(r), const SizedBox(height: 16), _overdueInvoices(r)]);

  Widget _expiringContracts(UPropertyDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.event_busy_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.contractsExpiringSoon, fontWeight: FontWeight.w700).expanded(),
            TextButton(onPressed: UAdminPageSwitcher.contracts, child: Text(U.s.contracts)),
          ],
        ),
        const Divider(height: 16),
        if (r.expiringContracts.isEmpty)
          UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.expiringContracts.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final UExpiringContractItem item = r.expiringContracts[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bed_rounded),
                title: Text("${item.userName ?? "-"} · ${item.dormTitle} / ${item.bedTitle}"),
                subtitle: Text("${U.s.ends} ${item.endDate.toJalaliDate()} · ${item.rent.rial()}"),
              );
            },
          ),
      ],
    ),
  );

  Widget _overdueInvoices(UPropertyDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.overdueInvoices, fontWeight: FontWeight.w700).expanded(),
            TextButton(onPressed: UAdminPageSwitcher.invoices, child: Text(U.s.invoices)),
          ],
        ),
        const Divider(height: 16),
        if (r.overdueInvoices.isEmpty)
          UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.overdueInvoices.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final UOverdueInvoiceItem item = r.overdueInvoices[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long_rounded, color: UAdminTheme.red),
                title: Text(item.userName ?? "-"),
                subtitle: Text("${U.s.due} ${item.dueDate.toJalaliDate()} · ${item.daysOverdue} ${U.s.daysOverdue}"),
                trailing: UTextBodyMedium(item.debtAmount.rial(), fontWeight: FontWeight.w700),
              );
            },
          ),
      ],
    ),
  );

  Widget _recentSection(UPropertyDashboardResponse r) => _isWide
      ? URow(spacing: 0, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[_recentContracts(r).expanded(), const SizedBox(width: 16), _recentUsers(r).expanded()])
      : UColumn(spacing: 0, children: <Widget>[_recentContracts(r), const SizedBox(height: 16), _recentUsers(r)]);

  Widget _recentContracts(UPropertyDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.description_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.recentContracts, fontWeight: FontWeight.w700).expanded(),
            TextButton(onPressed: UAdminPageSwitcher.contracts, child: Text(U.s.contracts)),
          ],
        ),
        const Divider(height: 16),
        if (r.recentContracts.isEmpty)
          UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.recentContracts.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final URecentContractItem item = r.recentContracts[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_rounded),
                title: Text("${item.userName ?? "-"} · ${item.dormTitle} / ${item.bedTitle}"),
                subtitle: Text("${item.startDate.toJalaliDate()} → ${item.endDate.toJalaliDate()} · ${item.rent.rial()}"),
              );
            },
          ),
      ],
    ),
  );

  Widget _recentUsers(UPropertyDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.person_add_alt_1_rounded, size: 20),
            const SizedBox(width: 8),
            Text(U.s.recentlyJoined, style: const TextStyle(fontWeight: FontWeight.w700)).expanded(),
            TextButton(onPressed: UAdminPageSwitcher.adminUsers, child: Text(U.s.users)),
          ],
        ),
        const Divider(height: 16),
        if (r.recentUsers.isEmpty)
          UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.recentUsers.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final URecentUserItem u = r.recentUsers[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: UAdminTheme.primaries[index % UAdminTheme.primaries.length].shade100,
                  child: Text(u.displayName.isNotEmpty ? u.displayName.substring(0, 1).toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(u.displayName),
                subtitle: Text(u.userName ?? u.phoneNumber ?? ""),
              );
            },
          ),
      ],
    ),
  );
}
