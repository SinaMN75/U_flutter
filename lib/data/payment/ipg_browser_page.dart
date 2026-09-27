part of "../data.dart";

class UIpgBrowserPage extends StatefulWidget {
  const UIpgBrowserPage({required this.url, required this.additionalData, super.key});

  final String url;
  final UIpgAdditionalData additionalData;

  @override
  State<UIpgBrowserPage> createState() => _UIpgBrowserPageState();
}

class _UIpgBrowserPageState extends State<UIpgBrowserPage> {
  late final UIpgBrowserController c;

  @override
  void initState() {
    c = UIpgBrowserController(url: widget.url, additionalData: widget.additionalData);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? _) {
      if (!didPop && !c.finished) c.cancel();
    },
    child: UScaffold(
      appBar: AppBar(title: Text(U.s.payment)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _hero(context).fadeSlideIn(),
            const SizedBox(height: 16),
            _details(context).fadeSlideIn(milliseconds: 800),
            const SizedBox(height: 24),
            UButton(title: U.s.payWithTheBankGateway, icon: const Icon(Icons.open_in_new_rounded, size: 18), fullWidth: true, onTap: c.open).fadeSlideIn(),
            const SizedBox(height: 12),
            UButton(
              title: U.s.refresh,
              type: UButtonType.outlined,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              fullWidth: true,
              onTap: () => c.check(showPending: true),
            ).fadeSlideIn(milliseconds: 1200),
            const SizedBox(height: 4),
            UButton(title: U.s.cancel, type: UButtonType.text, fullWidth: true, onTap: c.cancel).fadeSlideIn(milliseconds: 1400),
          ],
        ),
      ),
    ),
  );

  Widget _hero(BuildContext context) {
    final ColorScheme scheme = context.colorScheme;
    return UContainer(
      radius: 28,
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: <Color>[scheme.primary, scheme.primary.withValues(alpha: 0.72)],
      ),
      child: UStack(
        height: 120,
        children: <Widget>[
          CircleAvatar(radius: 75, backgroundColor: scheme.onPrimary.withAlpha(0x1F)).position(top: -40, left: -30),
          CircleAvatar(radius: 70, backgroundColor: scheme.onPrimary.withAlpha(0x1F)).position(top: 80, left: 180),
          ListTile(
            leading: UIconBackground(Icons.open_in_browser_rounded, color: scheme.onPrimary, size: 48),
            title: UTextBodyMedium(U.s.paymentStatus, color: scheme.onPrimary.withAlpha(0xCC)),
            subtitle: UTextHeadlineSmall(U.s.pending, color: scheme.onPrimary, fontWeight: FontWeight.bold),
            trailing: UIconTextHorizontal(
              leading: SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary)),
              trailing: UTextLabelSmall(U.s.onlinePayment, color: scheme.onPrimary),
              color: scheme.onPrimary.withAlpha(0x1F),
              radius: 100,
              padding: const EdgeInsets.all(12),
            ),
          ).alignAtCenter(),
        ],
      ),
    );
  }

  Widget _details(BuildContext context) {
    final ColorScheme scheme = context.colorScheme;
    final String? trackingNumber = widget.additionalData.trackingNumber;
    return UContainer(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      child: UColumn(
        children: <Widget>[
          URow(
            spacing: 12,
            children: <Widget>[
              Icon(Icons.info_outline_rounded, size: 20, color: scheme.primary),
              UTextBodyMedium(U.s.completeThePaymentInTheBrowserThenComeBackHere, color: scheme.onSurface, expanded: 1),
            ],
          ).pSymmetric(vertical: 16),
          if (trackingNumber != null && trackingNumber.isNotEmpty) ...<Widget>[
            Divider(height: 1, color: scheme.outlineVariant),
            URow(
              spacing: 12,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                UTextLabelMedium(U.s.trackingNumber, color: scheme.onSurfaceVariant),
                UIconTextHorizontal(
                  spaceBetween: 6,
                  onTap: () => UClipboard.set(trackingNumber, snackBar: true),
                  leading: Icon(Icons.copy, size: 15, color: scheme.onSurfaceVariant),
                  trailing: UTextBodyMedium(trackingNumber, color: scheme.onSurface, fontWeight: FontWeight.bold),
                ),
              ],
            ).pSymmetric(vertical: 14),
          ],
        ],
      ),
    );
  }
}
