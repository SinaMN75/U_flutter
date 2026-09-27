import "package:u/utilities.dart";

class UAdminWalletPage extends StatefulWidget {
  const UAdminWalletPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.walletManagement, const UAdminWalletPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.wallets,
    icon: Icons.account_balance_wallet_rounded,
    page: () => const UAdminWalletPage(),
    roles: roles,
  );

  @override
  State<UAdminWalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<UAdminWalletPage> {
  final UAdminWalletController c = UAdminWalletController();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.walletManagement)),
    body: UAdminPageBody(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            UObx(() {
              if (c.selectedUser.value == null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: UTextBodyMedium(U.s.selectAUserToManageTheirWallet)),
                );
              }
              if (c.state.value.isError()) {
                return Center(
                  child: TextButton(onPressed: c.read, child: Text(U.s.retry)),
                );
              }
              if (!c.state.value.isLoaded()) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                );
              }
              return UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _balanceCard(),
                  const SizedBox(height: 12),
                  _actions(),
                  const SizedBox(height: 12),
                  _summaryCard(),
                  const SizedBox(height: 12),
                  UTextTitleMedium(U.s.recentWalletTransactions),
                  const SizedBox(height: 8),
                  _history(),
                ],
              );
            }),
          ],
        ),
      ),
    ),
  );

  Widget _balanceCard() => UCard(
    child: URow(
      children: <Widget>[
        const Icon(Icons.account_balance_wallet_rounded, size: 40),
        const SizedBox(width: 16),
        UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UTextBodyMedium(U.s.currentBalance),
            const SizedBox(height: 4),
            UTextHeadlineSmall(c.totalBalance.rial()),
          ],
        ),
      ],
    ),
  );

  Widget _actions() => URow(
    children: <Widget>[
      UButton(title: U.s.charge, icon: const Icon(Icons.add_card_rounded, size: 18), onTap: _charge, expanded: 1),
      const SizedBox(width: 12),
      UButton(title: U.s.transfer, icon: const Icon(Icons.swap_horiz_rounded, size: 18), onTap: _transfer, expanded: 1),
    ],
  );

  Widget _summaryCard() => UObx(() {
    final UAccountingReportResponse? s = c.summary.value;
    if (s == null) return const SizedBox.shrink();
    return UCard(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextTitleSmall(U.s.last30Days),
          const Divider(height: 16),
          URow(
            children: <Widget>[
              _miniStat(U.s.moneyIn, s.totalIn, UAdminTheme.green),
              _miniStat(U.s.moneyOut, s.totalOut, UAdminTheme.red),
              _miniStat(U.s.net, s.net, s.net >= 0 ? UAdminTheme.green : UAdminTheme.red),
            ],
          ),
        ],
      ),
    );
  });

  Widget _miniStat(String label, double value, Color color) => Expanded(
    child: UColumn(
      children: <Widget>[
        UTextBodySmall(label),
        const SizedBox(height: 4),
        UTextBodyLarge(value.rial(), color: color, fontWeight: FontWeight.w700, textAlign: .center),
      ],
    ),
  );

  Widget _history() => UObx(() {
    if (c.txns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: UTextBodySmall(U.s.noTransactions)),
      );
    }
    return UColumn(
      children: c.txns.map((UWalletTxnResponse t) {
        final bool incoming = t.receiverId == c.selectedUser.value?.id;
        final Color color = incoming ? UAdminTheme.green : UAdminTheme.red;
        return UCard(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(incoming ? Icons.south_west_rounded : Icons.north_east_rounded, color: color),
            title: UTextBodyMedium("${incoming ? "+" : "-"}${t.amount.rial()}", color: color),
            subtitle: UTextBodySmall("${TagWalletTxn.values.fromNumber(t.tags.isEmpty ? 0 : t.tags.first)?.localizedTitle ?? ""} • ${t.createdAt.toJalaliDate()}"),
            trailing: UTextBodySmall(incoming ? (t.sender?.displayName ?? "") : (t.receiver?.displayName ?? "")),
          ),
        );
      }).toList(),
    );
  });

  void _charge() {
    c.chargeAmount.clear();
    UAdminForm.editDialog(
      title: U.s.chargeWallet,
      formKey: c.formKey,
      maxWidth: 380,
      onSubmit: c.charge,
      children: (BuildContext context, StateSetter setState) => <Widget>[UAdminForm.text(c.chargeAmount, U.s.amount, money: true, required: true)],
    );
  }

  void _transfer() {
    c.transferAmount.clear();
    c.transferDetail.clear();
    c.receiver = null;
    UAdminForm.editDialog(
      title: U.s.transferFunds,
      formKey: c.formKey,
      maxWidth: 380,
      onSubmit: c.transfer,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.text(c.transferAmount, U.s.amount, money: true, required: true),
        UAdminForm.text(c.transferDetail, U.s.description),
      ],
    );
  }
}
