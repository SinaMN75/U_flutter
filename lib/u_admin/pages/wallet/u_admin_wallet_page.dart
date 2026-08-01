import "package:u/utilities.dart";

class UAdminWalletPage extends StatefulWidget {
  const UAdminWalletPage({super.key});

  @override
  State<UAdminWalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<UAdminWalletPage> {
  final UAdminWalletController c = UAdminWalletController();

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.walletManagement)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16),
          Obx(() {
            if (c.selectedUser.value == null) {
              return Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(child: UTextBodyMedium(U.s.selectUserToManageWallet)),
              );
            }
            if (c.state.value.isError())
              return Center(
                child: TextButton(onPressed: c.read, child: Text(U.s.retry)),
              );
            if (!c.state.value.isLoaded())
              return const Center(
                child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
              );
            return UColumn(
              spacing: 0,
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
  );

  Widget _balanceCard() => UCard(
    child: URow(
      spacing: 0,
      children: <Widget>[
        const Icon(Icons.account_balance_wallet_rounded, size: 40),
        const SizedBox(width: 16),
        UColumn(
          spacing: 0,
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
    spacing: 0,
    children: <Widget>[
      UButton(title: U.s.charge, icon: const Icon(Icons.add_card_rounded, size: 18), onTap: _showChargeDialog).expanded(),
      const SizedBox(width: 12),
      UButton(title: U.s.transfer, icon: const Icon(Icons.swap_horiz_rounded, size: 18), onTap: _showTransferDialog).expanded(),
    ],
  );

  Widget _summaryCard() => Obx(() {
    final UAccountingReportResponse? s = c.summary.value;
    if (s == null) return const SizedBox.shrink();
    return UCard(
      child: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextTitleSmall(U.s.last30Days),
          const Divider(height: 16),
          URow(
            spacing: 0,
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
      spacing: 0,
      children: <Widget>[
        UTextBodySmall(label),
        const SizedBox(height: 4),
        UTextBodyLarge(value.rial(), color: color, fontWeight: FontWeight.w700, textAlign: .center),
      ],
    ),
  );

  Widget _history() => Obx(() {
    if (c.txns.isEmpty)
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: UTextBodySmall(U.s.noTransactions)),
      );
    return UColumn(
      spacing: 0,
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

  void _showChargeDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amount = TextEditingController();
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.chargeWallet),
        content: SizedBox(
          width: context.dialogWidth(max: 380),
          child: Form(
            key: formKey,
            child: UColumn(
              spacing: 0,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextField(
                  controller: amount,
                  labelText: U.s.amount,
                  keyboardType: TextInputType.number,
                  validator: UValidators.required(message: U.s.required),
                ).pSymmetric(vertical: 6),
                const SizedBox(height: 20),
                UButtonSubmitCancel(
                  submitTitle: U.s.charge,
                  onSubmit: () => UValidators.validateForm(
                    key: formKey,
                    action: () {
                      UNavigator.back();
                      c.charge(amount.text.trim().toDouble());
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransferDialog() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController amount = TextEditingController();
    final TextEditingController detail = TextEditingController();
    final Rxn<UUserResponse> receiver = Rxn<UUserResponse>();
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.transferFunds),
        content: SizedBox(
          width: context.dialogWidth(max: 380),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                spacing: 0,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: amount,
                    labelText: U.s.amount,
                    keyboardType: TextInputType.number,
                    validator: UValidators.required(message: U.s.required),
                  ).pSymmetric(vertical: 6),
                  UTextField(controller: detail, labelText: U.s.description).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    submitTitle: U.s.transfer,
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        if (receiver.value == null) {
                          UToast.error(message: U.s.selectAReceiver);
                          return;
                        }
                        UNavigator.back();
                        c.transfer(receiverId: receiver.value!.id, amount: amount.text.trim().toDouble(), detail: detail.text.nullIfEmpty());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
