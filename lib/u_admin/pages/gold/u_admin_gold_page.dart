import "package:u/utilities.dart";

class UAdminGoldPage extends StatefulWidget {
  const UAdminGoldPage({super.key});

  @override
  State<UAdminGoldPage> createState() => _UAdminGoldPageState();
}

class _UAdminGoldPageState extends State<UAdminGoldPage> {
  final UAdminGoldController c = UAdminGoldController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.gold,
    extraActions: <Widget>[IconButton(icon: const Icon(Icons.refresh), tooltip: U.s.refresh, onPressed: c.init)],
    body: UDefaultTabBar(
      isScrollable: true,
      tabBar: TabBar(
        isScrollable: true,
        tabs: <Widget>[
          Tab(text: U.s.goldPrice),
          Tab(text: U.s.goldOrders),
          Tab(text: U.s.providerTransactions),
          Tab(text: U.s.tradeLimits),
          Tab(text: U.s.goldApiTokens),
        ],
      ),
      children: <Widget>[_overview(), _orders(), _transactions(), _limits(), _tokens()],
    ),
  );

  Widget _overview() => Obx(
    () => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: <Widget>[
          _card(U.s.providerAccount, <UAdminField>[
            UAdminField(U.s.title, c.account.value?.name ?? "-"),
            UAdminField(U.s.accountStatus, (c.account.value?.active ?? false) ? U.s.active : U.s.inactive),
            UAdminField(U.s.allowedIps, (c.account.value?.ipWhitelist ?? <String>[]).join(", ")),
          ]),
          _card(U.s.goldPrice, <UAdminField>[
            UAdminField(U.s.buyPrice, c.quote.value?.buyUnitPrice.rial()),
            UAdminField(U.s.sellPrice, c.quote.value?.sellUnitPrice.rial()),
            UAdminField(U.s.pricePerGram, c.quote.value?.baseUnitPrice.rial()),
            UAdminField(U.s.lastUpdated, c.quote.value?.updatedAt?.toJalaliDateTime() ?? "-"),
          ]),
          _card(
            U.s.providerBalances,
            c.balances
                .map((UGoldBalanceResponse b) => UAdminField(b.assetCode, "${b.balance?.toStringAsSmartRound(maxPrecision: 4) ?? "0"}${b.locked ? " 🔒" : ""}"))
                .toList(),
          ),
        ],
      ),
    ),
  );

  Widget _card(String title, List<UAdminField> fields) => UContainer(
    padding: const EdgeInsets.all(16),
    radius: 16,
    color: Theme.of(context).colorScheme.surface,
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        UTextTitleSmall(title, fontWeight: FontWeight.w700),
        ...fields.map(
          (UAdminField f) => URow(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              UTextBodySmall(f.label, color: Theme.of(context).colorScheme.onSurfaceVariant),
              UTextBodySmall(f.value ?? "-", fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _orders() => UColumn(
    children: <Widget>[
      UAdminListView<UGoldOrderResponse>(
        state: c.ordersState,
        items: () => c.orders,
        totalCount: () => c.orders.length,
        onRetry: c.readOrders,
        emptyText: U.s.noGoldOrdersYet,
        desktopHeader: () => UAdminTable.header(<String>[U.s.type, U.s.amountInGram, U.s.amount, U.s.unitPrice, U.s.status, U.s.date]),
        desktopRow: _orderDesktop,
        mobileRow: _orderMobile,
      ).expanded(),
      Obx(
        () => c.ordersCursor == null
            ? const SizedBox.shrink()
            : UButton(title: U.s.loadMore, type: UButtonType.text, onTap: () => c.readOrders(more: true)).pOnly(bottom: 8),
      ),
    ],
  );

  Widget _orderDesktop(UGoldOrderResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.side?.localizedTitle ?? "-"),
      UAdminTable.cell(i.dealtBaseAmount?.toStringAsSmartRound(maxPrecision: 4) ?? "-"),
      UAdminTable.cell(i.dealtQuoteAmount.rial()),
      UAdminTable.cell(i.effectivePrice.rial()),
      UAdminTable.cell(i.status?.localizedTitle ?? "-"),
      UAdminTable.cell(i.createdAt?.toJalaliDate() ?? "-"),
    ],
  );

  Widget _orderMobile(UGoldOrderResponse i, int index) => UAdminTable.mobileCard(
    icon: i.side == TagGoldOrderSide.sell ? Icons.trending_down_rounded : Icons.trending_up_rounded,
    title: "${i.side?.localizedTitle ?? "-"} • ${i.dealtBaseAmount?.toStringAsSmartRound(maxPrecision: 4) ?? "-"} ${U.s.gram}",
    badge: UAdminTable.statusChip(label: i.status?.localizedTitle ?? "-", color: Theme.of(context).colorScheme.primary),
    fields: <UAdminField>[
      UAdminField(U.s.amount, i.dealtQuoteAmount.rial()),
      UAdminField(U.s.unitPrice, i.effectivePrice.rial()),
      UAdminField(U.s.orderId, i.id),
      UAdminField(U.s.date, i.createdAt?.toJalaliDateTime() ?? "-"),
    ],
  );

  Widget _transactions() => UColumn(
    children: <Widget>[
      UAdminListView<UGoldTransactionResponse>(
        state: c.txnsState,
        items: () => c.txns,
        totalCount: () => c.txns.length,
        onRetry: c.readTransactions,
        emptyText: U.s.noGoldTransactionsYet,
        desktopHeader: () => UAdminTable.header(<String>[U.s.id, U.s.details, U.s.date]),
        desktopRow: (UGoldTransactionResponse i, int index) => URow(
          spacing: 8,
          color: UAdminTable.rowColor(context, index),
          padding: UAdminTable.rowPadding,
          children: <Widget>[
            UAdminTable.cell(i.id),
            UAdminTable.cell(_entries(i.entries)),
            UAdminTable.cell(i.createdAt?.toJalaliDate() ?? "-"),
          ],
        ),
        mobileRow: (UGoldTransactionResponse i, int index) => UAdminTable.mobileCard(
          icon: Icons.swap_horiz_rounded,
          title: _entries(i.entries),
          fields: <UAdminField>[
            UAdminField(U.s.id, i.id),
            UAdminField(U.s.date, i.createdAt?.toJalaliDateTime() ?? "-"),
          ],
        ),
      ).expanded(),
      Obx(
        () => c.txnsCursor == null
            ? const SizedBox.shrink()
            : UButton(title: U.s.loadMore, type: UButtonType.text, onTap: () => c.readTransactions(more: true)).pOnly(bottom: 8),
      ),
    ],
  );

  String _entries(List<UGoldWalletEntryResponse> entries) =>
      entries.map((UGoldWalletEntryResponse e) => "${e.asset ?? ""} ${e.amount?.toStringAsSmartRound(maxPrecision: 4) ?? ""}".trim()).join(" • ");

  Widget _limits() => Obx(
    () => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: <Widget>[
          _card(U.s.tradeLimits, <UAdminField>[
            UAdminField(U.s.timezone, c.limits.value?.timezone ?? "-"),
            ...(c.limits.value?.items ?? <UGoldTradeLimitResponse>[]).map(
              (UGoldTradeLimitResponse l) => UAdminField(
                "${l.type ?? "-"} (${l.interval ?? "-"})",
                "${l.remainingVolume?.toStringAsSmartRound(maxPrecision: 4) ?? "-"} / ${l.maxVolume?.toStringAsSmartRound(maxPrecision: 4) ?? "-"}",
              ),
            ),
          ]),
          _card(U.s.creditFacilities, <UAdminField>[
            UAdminField(U.s.timezone, c.credit.value?.timezone ?? "-"),
            ...(c.credit.value?.items ?? <UGoldCreditFacilityResponse>[]).map(
              (UGoldCreditFacilityResponse f) => UAdminField("${f.type ?? "-"} (${f.asset ?? "-"})", "${U.s.availableCredit}: ${f.availableCredit.rial()}"),
            ),
            ...(c.credit.value?.balances ?? <UGoldAssetBalanceResponse>[]).map(
              (UGoldAssetBalanceResponse b) => UAdminField(b.asset ?? "-", b.availableToTrade?.toStringAsSmartRound(maxPrecision: 4) ?? "-"),
            ),
          ]),
        ],
      ),
    ),
  );

  Widget _tokens() => UColumn(
    children: <Widget>[
      UButton(title: U.s.createApiToken, icon: const Icon(Icons.add), fullWidth: true, onTap: _showCreateTokenDialog).pAll(16),
      UAdminListView<UGoldApiTokenResponse>(
        state: c.tokensState,
        items: () => c.tokens,
        totalCount: () => c.tokens.length,
        onRetry: c.readTokens,
        emptyText: U.s.noApiTokensYet,
        desktopHeader: () => UAdminTable.header(<String>[U.s.label, U.s.tokenPrefix, U.s.scopes, U.s.status, U.s.operations]),
        desktopRow: (UGoldApiTokenResponse i, int index) => URow(
          spacing: 8,
          color: UAdminTable.rowColor(context, index),
          padding: UAdminTable.rowPadding,
          children: <Widget>[
            UAdminTable.cell(i.label ?? "-"),
            UAdminTable.cell(i.tokenPrefix ?? "-"),
            UAdminTable.cell(i.scopes.join(", ")),
            UAdminTable.cell(i.active ? U.s.active : U.s.inactive),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(i)).expanded(),
          ],
        ),
        mobileRow: (UGoldApiTokenResponse i, int index) => UAdminTable.mobileCard(
          icon: Icons.vpn_key_rounded,
          title: i.label ?? i.tokenPrefix ?? i.id,
          badge: UAdminTable.statusChip(
            label: i.active ? U.s.active : U.s.inactive,
            color: i.active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
          ),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(i)),
          fields: <UAdminField>[
            UAdminField(U.s.scopes, i.scopes.join(", ")),
            UAdminField(U.s.allowedIps, i.ipWhitelist.join(", ")),
            UAdminField(U.s.date, i.createdAt?.toJalaliDateTime() ?? "-"),
          ],
        ),
      ).expanded(),
    ],
  );

  void _confirmDelete(UGoldApiTokenResponse i) => UNavigator.confirm(
    title: U.s.revokeApiToken,
    message: i.label ?? i.tokenPrefix ?? i.id,
    onConfirm: () => c.deleteToken(i.id),
  );

  void _showCreateTokenDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.createApiToken),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.tokenLabelController, labelText: U.s.label).pSymmetric(vertical: 6),
              UTextField(controller: c.tokenScopesController, labelText: U.s.scopes).pSymmetric(vertical: 6),
              UTextField(controller: c.tokenIpsController, labelText: U.s.allowedIps).pSymmetric(vertical: 6),
              const SizedBox(height: 20),
              UButtonSubmitCancel(
                submitTitle: U.s.create,
                cancelTitle: U.s.cancel,
                onSubmit: () {
                  c.createToken();
                  UNavigator.back();
                },
                onCancel: UNavigator.back,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
