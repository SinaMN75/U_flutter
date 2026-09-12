part of "../data.dart";

class UReceiptRow {
  const UReceiptRow({required this.label, required this.value, this.copyable = false});

  final String label;
  final String value;
  final bool copyable;
}

class UReceipt {
  const UReceipt({
    required this.title,
    required this.amount,
    this.icon = Icons.receipt_long_outlined,
    this.method,
    this.trackingNumber,
    this.date,
    this.rows = const <UReceiptRow>[],
  });

  final String title;
  final int amount;
  final IconData icon;
  final String? method;
  final String? trackingNumber;
  final DateTime? date;
  final List<UReceiptRow> rows;
}

class UReceiptSheet extends StatelessWidget {
  const UReceiptSheet({required this.receipt, super.key});

  static const Color _success = Color(0xFF16A34A);
  static const Color _onSuccess = Color(0xFFFFFFFF);

  static Future<void> show(UReceipt receipt) => UNavigator.bottomSheet<void>(UReceiptSheet(receipt: receipt), showDragHandle: true);

  final UReceipt receipt;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: context.height * 0.85),
    child: SingleChildScrollView(
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _hero().fadeSlideIn(),
          const SizedBox(height: 16),
          _details(context).fadeSlideIn(),
          const SizedBox(height: 16),
          UButton(title: U.s.close, fullWidth: true, onTap: UNavigator.back).fadeSlideIn(),
        ],
      ).pOnly(left: 16, right: 16, bottom: 16, top: 4),
    ),
  );

  Widget _hero() => UContainer(
    radius: 28,
    gradient: LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: <Color>[_success, _success.withValues(alpha: 0.72)],
    ),
    child: UStack(
      height: 120,
      children: <Widget>[
        CircleAvatar(radius: 75, backgroundColor: _onSuccess.withAlpha(0x1F)).position(top: -40, left: -30),
        CircleAvatar(radius: 70, backgroundColor: _onSuccess.withAlpha(0x1F)).position(top: 80, left: 180),
        ListTile(
          leading: UIconBackground(receipt.icon, color: _onSuccess, size: 48),
          title: UTextBodyMedium(receipt.title, color: _onSuccess.withAlpha(0xCC)),
          subtitle: UTextHeadlineSmall(receipt.amount.abs().rial(), color: _onSuccess, fontWeight: FontWeight.bold),
          trailing: UIconTextHorizontal(
            leading: const Icon(Icons.check_circle, color: _onSuccess, size: 16),
            trailing: UTextLabelSmall(U.s.successful, color: _onSuccess),
            color: _onSuccess.withAlpha(0x1F),
            radius: 100,
            padding: const EdgeInsets.all(12),
          ),
        ).alignAtCenter(),
      ],
    ),
  );

  Widget _details(BuildContext context) {
    final ColorScheme scheme = context.colorScheme;
    final List<UReceiptRow> rows = <UReceiptRow>[
      UReceiptRow(label: U.s.amount, value: receipt.amount.abs().rial()),
      if (receipt.method != null) UReceiptRow(label: U.s.paymentMethod, value: receipt.method!),
      UReceiptRow(label: U.s.date, value: (receipt.date ?? DateTime.now()).toJalaliDateTime()),
      if (!receipt.trackingNumber.isNullOrEmpty()) UReceiptRow(label: U.s.trackingNumber, value: receipt.trackingNumber!, copyable: true),
      ...receipt.rows,
    ];
    return UContainer(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      child: UColumn(
        children: rows
            .mapIndexed<Widget>(
              (int index, UReceiptRow row) => UColumn(
                children: <Widget>[
                  if (index != 0) Divider(height: 1, color: scheme.outlineVariant),
                  _row(context, row),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _row(BuildContext context, UReceiptRow row) {
    final ColorScheme scheme = context.colorScheme;
    return URow(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        UTextLabelMedium(row.label, color: scheme.onSurfaceVariant),
        UIconTextHorizontal(
          spaceBetween: 6,
          expanded: 1,
          mainAxisAlignment: MainAxisAlignment.end,
          onTap: row.copyable ? () => UClipboard.set(row.value, snackBar: true) : null,
          leading: row.copyable ? Icon(Icons.copy, size: 15, color: scheme.onSurfaceVariant) : const SizedBox.shrink(),
          trailing: UTextBodyMedium(row.value, textAlign: TextAlign.left, color: scheme.onSurface, fontWeight: FontWeight.bold, expanded: 1),
        ),
      ],
    ).pSymmetric(vertical: 14);
  }
}
