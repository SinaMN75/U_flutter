import "package:u/utilities.dart";

class UAdminFinancialOpsDashboardPage extends StatefulWidget {
  const UAdminFinancialOpsDashboardPage({super.key});

  @override
  State<UAdminFinancialOpsDashboardPage> createState() => _FinancialOpsDashboardPageState();
}

class _FinancialOpsDashboardPageState extends State<UAdminFinancialOpsDashboardPage> {
  final UAdminFinancialOpsDashboardController c = UAdminFinancialOpsDashboardController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  bool get _isWide => MediaQuery.sizeOf(context).width > 1000;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text("${U.s.financialAndOperations} ⚡"),
      actions: <Widget>[IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: c.load)],
    ),
    body: Obx(() {
      if (c.state.value.isError()) return TextButton(onPressed: c.load, child: Text(U.s.retry)).alignAtCenter();
      if (!c.state.value.isLoaded()) return const CircularProgressIndicator().alignAtCenter();
      final UFinancialOpsDashboardResponse r = c.report.value!;
      return SingleChildScrollView(
        padding: EdgeInsets.all(_isWide ? 24 : 14),
        child: UColumn(
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _hero(r).pSymmetric(vertical: 16),
            _entityCards(r).pSymmetric(vertical: 16),
            _chartsSection(r).pSymmetric(vertical: 16),
            _breakdownSection(r).pSymmetric(vertical: 16),
            _topMerchants(r).pSymmetric(vertical: 16),
            _recentListsSection(r).pSymmetric(vertical: 16),
          ],
        ),
      );
    }),
  );

  Widget _hero(UFinancialOpsDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(24),
    radius: 24,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Theme.of(context).colorScheme.primary, UAdminTheme.indigo.shade400, UAdminTheme.blue.shade400],
    ),
    boxShadow: <BoxShadow>[BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UIconTextHorizontal(
          leading: const Icon(Icons.account_balance_wallet_rounded, color: UAdminTheme.white, size: 34),
          trailing: UTextHeadlineSmall(U.s.financialAndOperations, color: UAdminTheme.white, fontWeight: FontWeight.w800),
        ),
        UAdminResponsiveGrid(
          minTileWidth: 150,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _heroMetric(U.s.users, r.usersCount.separate3By3(), Icons.groups_rounded),
            _heroMetric(U.s.merchants, r.merchantsCount.separate3By3(), Icons.storefront_rounded),
            _heroMetric(U.s.transactions, r.txnCount.separate3By3(), Icons.swap_horiz_rounded),
            _heroMetric(U.s.net, r.net.rial(), Icons.trending_up_rounded),
          ],
        ),
      ],
    ),
  );

  Widget _heroMetric(String label, String value, IconData icon) => ListTile(
    leading: Icon(icon, color: UAdminTheme.white),
    title: UTextBodySmall(label, color: UAdminTheme.white),
    subtitle: UTextBodyLarge(value, color: UAdminTheme.white),
  );

  Widget _entityCards(UFinancialOpsDashboardResponse r) => UAdminResponsiveGrid(
    children: <Widget>[
      _statCard(U.s.users, r.usersCount.separate3By3(), "+${r.newUsersCount} ${U.s.new_}", Icons.people_alt_rounded, UAdminTheme.indigo, UAdminPageSwitcher.adminUsers),
      _statCard(U.s.merchants, r.merchantsCount.separate3By3(), "+${r.newMerchantsCount} ${U.s.new_}", Icons.storefront_rounded, UAdminTheme.orange, UAdminPageSwitcher.merchants),
      _statCard(
        U.s.terminals,
        r.terminalsCount.separate3By3(),
        "${r.terminalsAssignedCount} ${U.s.assigned}",
        Icons.point_of_sale_rounded,
        UAdminTheme.green,
        UAdminPageSwitcher.terminals,
      ),
      _statCard(U.s.transactions, r.txnCount.separate3By3(), "+${r.newTxnCount} ${U.s.new_}", Icons.swap_horiz_rounded, UAdminTheme.pink, UAdminPageSwitcher.transactions),
      _statCard(U.s.wallets, r.walletsCount.separate3By3(), r.totalWalletBalance.rial(), Icons.account_balance_wallet_rounded, UAdminTheme.blueGrey, UAdminPageSwitcher.wallet),
      _statCard(U.s.moneyIn, r.totalIn.rial(), "", Icons.south_west_rounded, UAdminTheme.green, null),
      _statCard(U.s.moneyOut, r.totalOut.rial(), "", Icons.north_east_rounded, UAdminTheme.red, null),
      _statCard(U.s.unassignedTerminals, r.terminalsUnassignedCount.separate3By3(), "", Icons.link_off_rounded, UAdminTheme.grey, UAdminPageSwitcher.terminals),
    ],
  );

  Widget _statCard(String title, String value, String sub, IconData icon, Color color, VoidCallback? onTap) => UCard(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(icon, color: color, size: 26).container(padding: const EdgeInsets.all(12), backgroundColor: color.withValues(alpha: 0.14), radius: 16),
      title: UTextTitleMedium(value, fontWeight: FontWeight.w800, maxLines: 1),
      subtitle: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextBodySmall(title, color: UAdminTheme.grey),
          if (sub.isNotEmpty) UTextBodySmall(sub, color: color, fontWeight: FontWeight.w600),
        ],
      ),
      onTap: onTap,
    ),
  );

  Widget _chartsSection(UFinancialOpsDashboardResponse r) => _isWide
      ? URow(spacing: 0, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[_timelineChart(r).expanded(flex: 2), const SizedBox(width: 16), _entityBarChart(r).expanded()])
      : UColumn(spacing: 0, children: <Widget>[_timelineChart(r), const SizedBox(height: 16), _entityBarChart(r)]);

  Widget _timelineChart(UFinancialOpsDashboardResponse r) {
    if (r.dailyTimeline.isEmpty) return _chartCard(title: U.s.dailyInOut, child: UTextBodySmall(U.s.noData).alignAtCenter());
    return _chartCard(
      title: U.s.dailyInOut,
      child: UAreaChart(
        categories: r.dailyTimeline.map((UAccountingTimelineItem d) => d.date.toJalaliDate()).toList(),
        series: <UChartSeries>[
          UChartSeries(name: U.s.moneyIn, color: UAdminTheme.green, values: r.dailyTimeline.map((UAccountingTimelineItem d) => d.inAmount.toDouble()).toList()),
          UChartSeries(name: U.s.moneyOut, color: UAdminTheme.red, values: r.dailyTimeline.map((UAccountingTimelineItem d) => d.outAmount.toDouble()).toList()),
        ],
      ),
    );
  }

  Widget _entityBarChart(UFinancialOpsDashboardResponse r) {
    final List<_Bar> data = <_Bar>[
      _Bar(U.s.users, r.usersCount, UAdminTheme.indigo),
      _Bar(U.s.merchants, r.merchantsCount, UAdminTheme.orange),
      _Bar(U.s.terminals, r.terminalsCount, UAdminTheme.green),
      _Bar(U.s.transactions, r.txnCount, UAdminTheme.pink),
    ];
    return _chartCard(
      title: U.s.entityOverview,
      child: UBarChart(
        categories: data.map((_Bar d) => d.label).toList(),
        series: <UChartSeries>[
          UChartSeries(
            values: data.map((_Bar d) => d.value.toDouble()).toList(),
            pointColors: data.map((_Bar d) => d.color).toList(),
          ),
        ],
      ),
    );
  }

  Widget _breakdownSection(UFinancialOpsDashboardResponse r) {
    final List<Widget> charts = <Widget>[
      _doughnutAmount(U.s.transactionsByStatus, r.txnByStatus),
      _doughnutAmount(U.s.transactionsByMethod, r.txnByMethod),
      _doughnutCount(U.s.terminalsByType, r.terminalsByType),
    ];
    return _isWide
        ? URow(
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < charts.length; i++) ...<Widget>[if (i > 0) const SizedBox(width: 16), charts[i].expanded()],
            ],
          )
        : UColumn(
            spacing: 0,
            children: <Widget>[
              for (final Widget w in charts) ...<Widget>[w, const SizedBox(height: 16)],
            ],
          );
  }

  Widget _doughnutAmount(String title, List<UAccountingBreakdownItem> items) => _chartCard(
    title: title,
    child: items.isEmpty
        ? UTextBodySmall(U.s.noData).alignAtCenter()
        : UDonutChart(
            slices: items.map((UAccountingBreakdownItem d) => USlice(value: d.amount.toDouble(), label: d.tagName)).toList(),
          ),
  );

  Widget _doughnutCount(String title, List<UAccountingBreakdownItem> items) => _chartCard(
    title: title,
    child: items.isEmpty
        ? UTextBodySmall(U.s.noData).alignAtCenter()
        : UPieChart(
            slices: items.map((UAccountingBreakdownItem d) => USlice(value: d.count.toDouble(), label: d.tagName)).toList(),
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

  Widget _topMerchants(UFinancialOpsDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.workspace_premium_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.topMerchantsByTerminalCount, fontWeight: FontWeight.w700).expanded(),
            TextButton(onPressed: UAdminPageSwitcher.merchants, child: Text(U.s.merchants)),
          ],
        ),
        const Divider(height: 16),
        if (r.topMerchants.isEmpty)
          UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.topMerchants.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final UTopMerchantItem m = r.topMerchants[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: UAdminTheme.primaries[index % UAdminTheme.primaries.length].shade100,
                  child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(m.title),
                subtitle: Text(m.city),
                trailing: UTextBodyMedium("${m.terminalCount} ${U.s.terminals}", fontWeight: FontWeight.w700),
              );
            },
          ),
      ],
    ),
  );

  Widget _recentListsSection(UFinancialOpsDashboardResponse r) => _isWide
      ? URow(
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[_recentTransactions(r).expanded(), const SizedBox(width: 16), _recentMerchantsAndUsers(r).expanded()],
        )
      : UColumn(spacing: 0, children: <Widget>[_recentTransactions(r), const SizedBox(height: 16), _recentMerchantsAndUsers(r)]);

  Widget _recentTransactions(UFinancialOpsDashboardResponse r) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.receipt_long_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.recentTransactions, fontWeight: FontWeight.w700).expanded(),
            TextButton(onPressed: UAdminPageSwitcher.transactions, child: Text(U.s.transactions)),
          ],
        ),
        const Divider(height: 16),
        if (r.recentTransactions.isEmpty)
          UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.recentTransactions.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
            itemBuilder: (BuildContext context, int index) {
              final URecentTxnItem t = r.recentTransactions[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz_rounded),
                title: Text(t.amount.rial()),
                subtitle: Text("${t.userName ?? "-"} · ${t.tags.join(", ")}"),
                trailing: UTextBodySmall(t.trackingNumber),
              );
            },
          ),
      ],
    ),
  );

  Widget _recentMerchantsAndUsers(UFinancialOpsDashboardResponse r) => UColumn(
    spacing: 0,
    children: <Widget>[
      UContainer(
        padding: const EdgeInsets.all(20),
        radius: 20,
        child: UColumn(
          spacing: 0,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            URow(
              spacing: 0,
              children: <Widget>[
                const Icon(Icons.storefront_rounded, size: 20),
                const SizedBox(width: 8),
                UTextTitleSmall(U.s.recentlyOnboardedMerchants, fontWeight: FontWeight.w700).expanded(),
                TextButton(onPressed: UAdminPageSwitcher.merchants, child: Text(U.s.merchants)),
              ],
            ),
            const Divider(height: 16),
            if (r.recentMerchants.isEmpty)
              UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: r.recentMerchants.length,
                separatorBuilder: (BuildContext context, int index) => const Divider(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final URecentMerchantItem m = r.recentMerchants[index];
                  return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.store_rounded), title: Text(m.title), subtitle: Text(m.cityCode));
                },
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      UContainer(
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
      ),
    ],
  );
}

class _Bar {
  _Bar(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
