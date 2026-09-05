import "package:u/utilities.dart";

enum UGoldInputMode { amount, weight }

class UGoldBalanceCard extends StatelessWidget {
  const UGoldBalanceCard({
    required this.balance,
    super.key,
    this.value,
    this.buyUnitPrice,
    this.sellUnitPrice,
    this.updatedAt,
    this.isLoading = false,
    this.errorText,
    this.gradient,
    this.onRefresh,
    this.onHistory,
  });

  final double balance;
  final double? value;
  final double? buyUnitPrice;
  final double? sellUnitPrice;
  final DateTime? updatedAt;
  final bool isLoading;
  final String? errorText;
  final Gradient? gradient;
  final VoidCallback? onRefresh;
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) => UContainer(
    padding: const EdgeInsets.all(20),
    radius: 20,
    gradient: gradient,
    color: gradient == null ? Theme.of(context).colorScheme.primaryContainer : null,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            UTextLabelMedium(U.s.myGold, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85)),
            if (onRefresh != null)
              Icon(Icons.refresh_rounded, size: 20, color: Theme.of(context).colorScheme.onPrimary).onTap(onRefresh),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          UProgressLinear(progressColor: Theme.of(context).colorScheme.onPrimary)
        else if (errorText != null)
          UTextBodyMedium(errorText!, color: Theme.of(context).colorScheme.onPrimary)
        else ...<Widget>[
          UTextHeadlineSmall(
            "${balance.toStringAsSmartRound(maxPrecision: 4)} ${U.s.gram}",
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          UTextBodySmall(value.rial(), color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85)),
        ],
        const SizedBox(height: 16),
        URow(
          children: <Widget>[
            UGoldPriceChip(title: U.s.buyPrice, price: buyUnitPrice).expanded(),
            const SizedBox(width: 8),
            UGoldPriceChip(title: U.s.sellPrice, price: sellUnitPrice).expanded(),
          ],
        ),
        if (updatedAt != null) ...<Widget>[
          const SizedBox(height: 10),
          UTextLabelSmall(
            "${U.s.lastUpdated}: ${updatedAt!.toJalaliDateTime()}",
            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
        ],
        if (onHistory != null) ...<Widget>[
          const SizedBox(height: 12),
          UButton(
            title: U.s.goldTransactions,
            type: UButtonType.outlined,
            fullWidth: true,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            borderColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
            onTap: onHistory,
          ),
        ],
      ],
    ),
  );
}

class UGoldPriceChip extends StatelessWidget {
  const UGoldPriceChip({required this.title, super.key, this.price});

  final String title;
  final double? price;

  @override
  Widget build(BuildContext context) => UContainer(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    radius: 14,
    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextLabelSmall(title, color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
        const SizedBox(height: 2),
        UTextBodySmall(price.rial(), color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
      ],
    ),
  );
}

// Amount input for a gold trade: the user types either rial or grams and the other side is shown as an estimate.
class UGoldTradeField extends StatelessWidget {
  const UGoldTradeField({
    required this.controller,
    required this.mode,
    required this.onModeChanged,
    required this.onChanged,
    super.key,
    this.unitPrice,
    this.quickAmounts = const <double>[],
    this.hintText,
  });

  final TextEditingController controller;
  final UGoldInputMode mode;
  final ValueChanged<UGoldInputMode> onModeChanged;
  final ValueChanged<String> onChanged;
  final double? unitPrice;
  final List<double> quickAmounts;
  final String? hintText;

  double get _typed => controller.text.replaceAll(",", "").toDouble();

  String get _estimate {
    final double price = unitPrice ?? 0;
    if (price <= 0 || _typed <= 0) return "-";
    return mode == UGoldInputMode.amount ? "${(_typed / price).toStringAsSmartRound(maxPrecision: 4)} ${U.s.gram}" : (_typed * price).rial();
  }

  @override
  Widget build(BuildContext context) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      USegmentedControl<UGoldInputMode>(
        items: <UGoldInputMode, String>{UGoldInputMode.amount: U.s.byAmount, UGoldInputMode.weight: U.s.byWeight},
        selectedValue: mode,
        onValueChanged: (UGoldInputMode? v) => onModeChanged(v ?? UGoldInputMode.amount),
      ),
      const SizedBox(height: 12),
      UTextField(
        controller: controller,
        labelText: mode == UGoldInputMode.amount ? U.s.amountInRial : U.s.amountInGram,
        hintText: hintText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        formatters: mode == UGoldInputMode.amount ? <TextInputFormatter>[UCurrencyInputFormatter()] : null,
        onChanged: onChanged,
      ),
      if (quickAmounts.isNotEmpty) ...<Widget>[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickAmounts
              .map(
                (double a) => UButton(
                  title: mode == UGoldInputMode.amount ? a.rial() : "${a.toStringAsSmartRound(maxPrecision: 4)} ${U.s.gram}",
                  type: UButtonType.outlined,
                  size: UButtonSize.small,
                  onTap: () {
                    controller.text = mode == UGoldInputMode.amount ? a.toInt().toString().separateNumbers3By3() : a.toStringAsSmartRound(maxPrecision: 4);
                    onChanged(controller.text);
                  },
                ),
              )
              .toList(),
        ),
      ],
      const SizedBox(height: 10),
      URow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          UTextLabelMedium(mode == UGoldInputMode.amount ? U.s.estimatedGold : U.s.estimatedAmount),
          UTextBodyMedium(_estimate, fontWeight: FontWeight.bold),
        ],
      ),
      const SizedBox(height: 6),
      UTextLabelSmall(U.s.theFinalPriceIsSetAtTheMomentTheOrderIsFilled, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ],
  );
}

class UGoldTxnTile extends StatelessWidget {
  const UGoldTxnTile({required this.txn, super.key, this.onTap});

  final UGoldTxnResponse txn;
  final VoidCallback? onTap;

  Color _statusColor(BuildContext context) {
    switch (txn.status) {
      case TagGoldTxn.filled:
        return Theme.of(context).colorScheme.primary;
      case TagGoldTxn.pending:
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      leading: UIconBackground(txn.icon, color: _statusColor(context)),
      title: UTextBodyMedium(txn.side.localizedTitle, fontWeight: FontWeight.bold),
      subtitle: UTextLabelSmall(
        "${txn.goldAmount.toStringAsSmartRound(maxPrecision: 4)} ${U.s.gram} • ${txn.createdAt?.toJalaliDateTime() ?? ""}",
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      trailing: UColumn(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          UTextBodySmall(txn.amount.rial(), fontWeight: FontWeight.bold),
          UTextLabelSmall(txn.status.localizedTitle, color: _statusColor(context)),
        ],
      ),
    ),
  );
}
