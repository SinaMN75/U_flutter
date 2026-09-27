import "package:u/utilities.dart";

class UAdminAccountingPage extends StatefulWidget {
  const UAdminAccountingPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.accounting, const UAdminAccountingPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.accounting,
    icon: Icons.bar_chart_rounded,
    page: () => const UAdminAccountingPage(),
    roles: roles,
  );

  @override
  State<UAdminAccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<UAdminAccountingPage> {
  final UAdminAccountingController c = UAdminAccountingController();

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

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.accounting),
      actions: <Widget>[
        IconButton(icon: const Icon(Icons.filter_alt), tooltip: U.s.filter, onPressed: _filter),
        IconButton(icon: const Icon(Icons.refresh), tooltip: U.s.refresh, onPressed: c.load),
      ],
    ),
    body: UAdminPageBody(
      child: UObx(() {
        if (c.state.value.isError()) {
          return Center(
            child: TextButton(onPressed: c.load, child: Text(U.s.retry)),
          );
        }
        if (!c.state.value.isLoaded()) return const Center(child: CircularProgressIndicator());
        final UAccountingReportResponse? r = c.report.value;
        if (r == null) return Center(child: Text(U.s.noData));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _scopeBanner(),
              const SizedBox(height: 8),
              _statCards(r),
              const SizedBox(height: 8),
              _breakdown(U.s.incomeByType, r.incomeByType, UAdminTheme.green),
              _breakdown(U.s.spendingByType, r.spendingByType, UAdminTheme.red),
              _breakdown(U.s.gatewayPaymentsByType, r.gatewayByType, UAdminTheme.blue),
              _timeline(r),
            ],
          ),
        );
      }),
    ),
  );

  Widget _scopeBanner() => UObx(() {
    final UUserResponse? u = c.user.value;
    return UCard(
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Icon(u == null ? Icons.public_rounded : Icons.person_rounded),
        title: UTextBodyMedium(u == null ? U.s.systemWideReport : "${U.s.user}: ${u.displayName}"),
        subtitle: UTextBodySmall(_rangeLabel()),
      ),
    );
  });

  String _rangeLabel() {
    final String from = c.controllerStartDate.text.nullIfEmpty() ?? U.s.last30Days;
    final String to = c.controllerEndDate.text.nullIfEmpty() ?? "";
    return to.isEmpty ? from : "$from → $to";
  }

  Widget _statCards(UAccountingReportResponse r) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: <Widget>[
      _stat(U.s.moneyIn, r.totalIn, UAdminTheme.green, Icons.south_west_rounded),
      _stat(U.s.moneyOut, r.totalOut, UAdminTheme.red, Icons.north_east_rounded),
      _stat(U.s.net, r.net, r.net >= 0 ? UAdminTheme.green : UAdminTheme.red, Icons.balance_rounded),
      _stat(U.s.walletBalance, r.totalWalletBalance, UAdminTheme.blueGrey, Icons.account_balance_wallet_rounded),
    ],
  );

  Widget _stat(String label, double value, Color color, IconData icon) => UCard(
    width: 220,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        URow(
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            UTextBodySmall(label, expanded: 1),
          ],
        ),
        const SizedBox(height: 10),
        UTextTitleMedium(value.rial(), color: color),
      ],
    ),
  );

  Widget _breakdown(String title, List<UAccountingBreakdownItem> items, Color color) => UCard(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextTitleSmall(title),
        const Divider(height: 16),
        if (items.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: UTextBodySmall(U.s.noData))
        else
          ...items.map(
            (UAccountingBreakdownItem i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: URow(
                children: <Widget>[
                  UTextBodyMedium(i.tagName, expanded: 1),
                  UTextBodySmall("×${i.count}"),
                  const SizedBox(width: 12),
                  UTextBodyMedium(i.amount.rial(), color: color, fontWeight: FontWeight.w600),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _timeline(UAccountingReportResponse r) {
    if (r.timeline.isEmpty) return const SizedBox.shrink();
    return UCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextTitleSmall(U.s.dailyInOut),
          const Divider(height: 16),
          ...r.timeline.map(
            (UAccountingTimelineItem t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: URow(
                children: <Widget>[
                  UTextBodySmall(t.date.toJalaliDate(), expanded: 1),
                  UTextBodySmall("+${t.inAmount.rial()}", color: UAdminTheme.green),
                  const SizedBox(width: 12),
                  UTextBodySmall("-${t.outAmount.rial()}", color: UAdminTheme.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.report),
    onApply: c.load,
    onClear: c.clear,
    children: (StateSetter setState) => <Widget>[
      UAdminForm.date(c.controllerStartDate, U.s.fromDate, (DateTime d) => c.startDate = d),
      UAdminForm.date(c.controllerEndDate, U.s.toDate, (DateTime d) => c.endDate = d),
    ],
  );
}
