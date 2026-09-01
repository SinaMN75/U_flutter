import "package:u/utilities.dart";

class UAdminMoadisPage extends StatefulWidget {
  const UAdminMoadisPage({super.key, this.user, this.actions});

  final UUserResponse? user;
  final UAdminActionBuilder<UMoadiResponse>? actions;

  @override
  State<UAdminMoadisPage> createState() => _MoadisPageState();
}

class _MoadisPageState extends State<UAdminMoadisPage> {
  final UAdminMoadiController c = UAdminMoadiController();

  @override
  void initState() {
    c.init(user: widget.user);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.taxpayerRequests,
    onFilter: _showFilterDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: _list(),
  );

  Widget _list() => UAdminListView<UMoadiResponse>(
    state: c.state,
    items: () => c.list,
    totalCount: () => c.totalCount,
    onRetry: c.read,
    emptyText: U.s.youHaveNotSubmittedAnyTaxpayerRequestYet,
    desktopHeader: () => UAdminTable.header(
      <String>[
        U.s.taxpayerName,
        U.s.economicCode,
        U.s.legalEntityType,
        U.s.pendingApproval,
        U.s.createdAt,
        U.s.operations,
      ],
    ),
    desktopRow: _itemDesktop,
    mobileRow: _itemResponsive,
  );

  Widget _itemDesktop(UMoadiResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.name),
      UAdminTable.cell(i.economicCode),
      UAdminTable.cell(i.legalEntity),
      UAdminTable.cell(_statusLabel(i.tags)),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UMoadiResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.receipt_long_rounded,
    title: i.name,
    badge: UAdminTable.statusChip(label: _statusLabel(i.tags), color: Theme.of(context).colorScheme.primary),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.economicCode, i.economicCode),
      UAdminField(U.s.legalEntityType, i.legalEntity),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  String _statusLabel(List<int> tags) {
    if (tags.contains(TagMoadi.approved.number)) return U.s.approved;
    if (tags.contains(TagMoadi.rejected.number)) return U.s.rejected;
    return U.s.pendingApproval;
  }

  String _tagLabel(TagMoadi t) => switch (t) {
    TagMoadi.approved => U.s.approved,
    TagMoadi.rejected => U.s.rejected,
    TagMoadi.pending => U.s.pendingApproval,
  };

  Widget _menu(UMoadiResponse i) {
    final bool isPending = !i.tags.contains(TagMoadi.approved.number) && !i.tags.contains(TagMoadi.rejected.number);
    return UAdminOps.menu<UMoadiResponse>(
      item: i,
      actions: widget.actions,
      handlers: UAdminActionHandlers<UMoadiResponse>(
        onDelete: c.delete,
        onDetail: _showDetailDialog,
        extras: <String, void Function(UMoadiResponse item)>{
          "approve": c.approve,
          "reject": _showRejectDialog,
        },
      ),
      fallback: (UAdminActionContext<UMoadiResponse> ctx) => <UAdminAction>[
        ctx.extra("approve", label: U.s.approve, icon: Icons.check_circle_outline, visible: isPending, color: UAdminTheme.green),
        ctx.extra("reject", label: U.s.reject, icon: Icons.cancel_outlined, visible: isPending, destructive: true),
        ctx.detail(),
        ctx.delete(),
      ],
    );
  }

  void _showRejectDialog(UMoadiResponse i) {
    final TextEditingController reason = TextEditingController();
    UNavigator.dialog(
      AlertDialog(
        title: Text(U.s.reject),
        content: SizedBox(
          width: context.dialogWidth(),
          child: UTextField(controller: reason, labelText: U.s.rejectionReason, lines: 3),
        ),
        actions: <Widget>[
          UButtonSubmitCancel(
            onSubmit: () {
              UNavigator.back();
              c.reject(i, reason.text.nullIfEmpty());
            },
            onCancel: UNavigator.back,
          ),
        ],
      ),
    ).whenComplete(reason.dispose);
  }

  void _showDetailDialog(UMoadiResponse i) => UNavigator.dialog(
    AlertDialog(
      title: Text(i.name),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _kv(U.s.pendingApproval, _statusLabel(i.tags)),
              _kv(U.s.economicCode, i.economicCode),
              _kv(U.s.legalEntityType, i.legalEntity),
              _kv(U.s.uniqueTaxCode, i.uniqueTaxCode),
              _kv(U.s.nationalCode, i.nationalCode ?? "-"),
              _kv(U.s.postalCode, i.postalCode ?? "-"),
              _kv(U.s.registrationDate, i.registrationDate ?? "-"),
              _kv(U.s.registrationNumber, i.registrationNumber ?? "-"),
              _kv(U.s.address, i.address ?? "-"),
              _kv(U.s.introductionCode, i.introductionCode ?? "-"),
              _kv(U.s.ownerName, i.ownerName),
              _kv(U.s.ownerMobile, i.ownerMobile),
              _kv(U.s.ownerNationalCode, i.ownerNationalCode),
              _kv("UUID", i.jsonData.uuid ?? "-"),
              _kv(U.s.rejectionReason, i.jsonData.rejectReason ?? "-"),
              UButton(type: UButtonType.text, title: U.s.ok, onTap: UNavigator.back),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _kv(String k, String v) => URow(
    crossAxisAlignment: CrossAxisAlignment.start,
    margin: const EdgeInsets.symmetric(vertical: 6),
    children: <Widget>[
      SizedBox(width: 130, child: UTextBodySmall(k, color: UAdminTheme.grey)),
      Expanded(child: UTextBodyMedium(v, fontWeight: FontWeight.w500)),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.taxpayerRequests),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextFieldAutoCompleteAsync<UUserResponse>(
                labelBuilder: (UUserResponse i) => "${i.firstName} ${i.lastName} ${i.nationalCode}",
                onChanged: c.user.call,
                selectedItem: c.user.value,
                fetchData: c.readUsers,
                hintText: U.s.user,
              ).pSymmetric(vertical: 6),
              Obx(
                () => UTextFieldAutoComplete<TagMoadi?>(
                  title: U.s.pendingApproval,
                  items: TagMoadi.values,
                  labelBuilder: (TagMoadi? i) => i == null ? "" : _tagLabel(i),
                  selectedItem: c.status.value,
                  onChanged: c.status.call,
                ),
              ).pSymmetric(vertical: 6),
              UTextField(controller: c.nameFilter, labelText: U.s.taxpayerName, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.economicCodeFilter, labelText: U.s.economicCode, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.nationalCodeFilter, labelText: U.s.nationalCode, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.uniqueTaxCodeFilter, labelText: U.s.uniqueTaxCode, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.fromCreatedController,
                labelText: U.s.fromDate,
                onChange: (DateTime d, Jalali j) {
                  c.fromCreatedController.text = j.formatCompactDate();
                  c.fromCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              UTextFieldDatePicker(
                jalali: true,
                controller: c.toCreatedController,
                labelText: U.s.toDate,
                onChange: (DateTime d, Jalali j) {
                  c.toCreatedController.text = j.formatCompactDate();
                  c.toCreatedAt = d;
                },
              ).pSymmetric(vertical: 6),
              const SizedBox(height: 20),
              UButtonSubmitCancel(
                submitTitle: U.s.filter,
                cancelTitle: U.s.clearFilters,
                onSubmit: () {
                  c.applyFilters();
                  UNavigator.back();
                },
                onCancel: () {
                  c.clearFilters();
                  UNavigator.back();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
