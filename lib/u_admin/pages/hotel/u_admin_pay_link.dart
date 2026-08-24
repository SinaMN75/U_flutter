part of "../../u_admin.dart";

abstract class UAdminPayLink {
  static Future<void> dormBedInvoice(UDormBedInvoiceResponse i, {Future<void> Function()? onClosed}) async {
    final bool paid = await UIpgFlow.pay(amount: i.netDue, tag: TagTxn.dormInvoice, invoiceId: i.id);
    if (paid) await onClosed?.call();
  }

  static Future<void> copyDormBedInvoiceLink(UDormBedInvoiceResponse i) async {
    final String? url = await UIpgFlow.link(amount: i.netDue, tag: TagTxn.dormInvoice, invoiceId: i.id);
    if (url == null || url.isEmpty) return;
    await UClipboard.set(url, snackBar: true);
  }

  static void dormBedInvoiceList(UDormBedContractResponse contract, {Future<void> Function()? onClosed}) {
    final List<UDormBedInvoiceResponse> invoices = contract.invoices ?? <UDormBedInvoiceResponse>[];
    if (invoices.isEmpty) {
      UToast.error(message: U.s.noItemsFound(U.s.invoice));
      return;
    }
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.payment),
        content: Builder(
          builder: (BuildContext context) => SizedBox(
            width: context.dialogWidth(),
            child: SingleChildScrollView(
              child: UColumn(
                spacing: 0,
                mainAxisSize: MainAxisSize.min,
                children: invoices
                    .map(
                      (UDormBedInvoiceResponse i) => ListTile(
                        dense: true,
                        title: UTextBodyMedium(i.netDue.rial()),
                        subtitle: UTextBodySmall(i.dueDate.toJalaliDate()),
                        trailing: i.isPaid
                            ? UTextBodySmall(U.s.paid, color: UAdminTheme.green)
                            : URow(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 0,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded),
                                    tooltip: "${U.s.copy} ${U.s.link}",
                                    onPressed: () => copyDormBedInvoiceLink(i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.payments_rounded),
                                    tooltip: U.s.payment,
                                    onPressed: () => dormBedInvoice(i, onClosed: onClosed),
                                  ),
                                ],
                              ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
