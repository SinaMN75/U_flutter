import "package:u/utilities.dart";

class UAdminParkingPage extends StatefulWidget {
  const UAdminParkingPage({super.key, this.actions});

  // Optional per-row operations override; defaults to the page's built-in set.
  final UAdminActionBuilder<UParkingResponse>? actions;

  @override
  State<UAdminParkingPage> createState() => _UAdminParkingPageState();
}

class _UAdminParkingPageState extends State<UAdminParkingPage> {
  final UAdminParkingController c = UAdminParkingController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.parkingManagement,
    onCreate: _showEditDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UParkingResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noParkingsFound,
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.title, flex: 2),
        UAdminTable.headerCell(U.s.owner, flex: 2),
        UAdminTable.headerCell(U.s.admins),
        UAdminTable.headerCell(U.s.createdAt),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  String _ownerLabel(UParkingResponse i) => i.creator?.displayName.nullIfEmpty() ?? i.creator?.userName ?? "-";

  Widget _itemDesktop(UParkingResponse i, int index) => URow(
    color: UAdminTable.rowColor(context, index),
    children: <Widget>[
      UAdminTable.cell(i.title, flex: 2),
      UAdminTable.cell(_ownerLabel(i), flex: 2),
      UAdminTable.cell(i.adminUserIds.length.toString()),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UParkingResponse i, int index) => UAdminTable.mobileTile(
    context,
    index: index,
    icon: Icons.local_parking_rounded,
    title: i.title,
    subtitle: <Widget>[UTextBodySmall("${U.s.owner}: ${_ownerLabel(i)} • ${i.createdAt.toJalaliDate()}")],
    trailing: _menu(i),
  );

  // Built-in operations; overridable via UAdminParkingPage(actions: ...).
  Widget _menu(UParkingResponse i) => UAdminOps.menu<UParkingResponse>(
    context,
    item: i,
    actions: widget.actions,
    handlers: UAdminActionHandlers<UParkingResponse>(
      onEdit: (UParkingResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UParkingResponse> ctx) => <UAdminAction>[
      UAdminLinks.parkingReport(ctx.item),
      ctx.edit(),
      ctx.delete(),
    ],
  );

  Future<void> _showEditDialog({UParkingResponse? p}) async {
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController entrance = TextEditingController();
    final TextEditingController hourly = TextEditingController();
    final TextEditingController daily = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // Owner = creatorId (single user). Assigned admins = adminUserIds (multiple users).
    UUserResponse? owner = p?.creator;
    final List<UUserResponse> selectedAdmins = <UUserResponse>[];
    if (p != null && p.adminUserIds.isNotEmpty) {
      final List<UUserResponse?> fetched = await Future.wait(p.adminUserIds.map(c.fetchUserById));
      selectedAdmins.addAll(fetched.whereType<UUserResponse>());
    }

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createParking : U.s.editParking),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  spacing: 0,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(
                      controller: title,
                      labelText: U.s.title,
                      validator: UValidators.required(message: ""),
                    ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: entrance,
                      labelText: U.s.entrancePrice,
                      keyboardType: TextInputType.number,
                      formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: hourly, labelText: U.s.hourlyPrice, keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UCurrencyInputFormatter()]).pSymmetric(vertical: 6),
                    UTextField(controller: daily, labelText: U.s.dailyPrice, keyboardType: TextInputType.number, formatters: <TextInputFormatter>[UCurrencyInputFormatter()]).pSymmetric(vertical: 6),
                    const SizedBox(height: 8),
                    // Assign a user as the owner (creatorId).
                    UTextFieldAutoCompleteAsync<UUserResponse>(
                      hintText: U.s.owner,
                      selectedItem: owner,
                      labelBuilder: (UUserResponse u) => u.userName,
                      fetchData: c.readUsers,
                      onChanged: (UUserResponse? u) => setDialogState(() => owner = u),
                    ).pSymmetric(vertical: 6),
                    if (owner != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Chip(label: Text(owner!.userName), onDeleted: () => setDialogState(() => owner = null)),
                      ).pSymmetric(vertical: 4),
                    const SizedBox(height: 8),
                    // Assign the parking to users (adminUserIds).
                    UTextFieldAutoCompleteAsync<UUserResponse>(
                      hintText: U.s.admins,
                      selectedItem: null,
                      labelBuilder: (UUserResponse u) => u.userName,
                      fetchData: c.readUsers,
                      onChanged: (UUserResponse? u) {
                        if (u == null) return;
                        if (selectedAdmins.any((UUserResponse x) => x.id == u.id)) return;
                        setDialogState(() => selectedAdmins.add(u));
                      },
                    ).pSymmetric(vertical: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: selectedAdmins
                          .map((UUserResponse u) => Chip(label: Text(u.userName), onDeleted: () => setDialogState(() => selectedAdmins.removeWhere((UUserResponse x) => x.id == u.id))))
                          .toList(),
                    ).pSymmetric(vertical: 6),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final List<String> adminUserIds = selectedAdmins.map((UUserResponse u) => u.id).toList();
                          if (p == null)
                            c.create(
                              p: UParkingCreateParams(
                                tags: <int>[TagParking.test.number],
                                title: title.text,
                                entrancePrice: entrance.isNullOrEmpty() ? 0 : entrance.numDouble(),
                                hourlyPrice: hourly.isNullOrEmpty() ? 0 : hourly.numDouble(),
                                dailyPrice: daily.isNullOrEmpty() ? 0 : daily.numDouble(),
                                creatorId: owner?.id,
                                adminUserIds: adminUserIds,
                              ),
                            );
                          else
                            c.update(
                              p: UParkingUpdateParams(
                                id: p.id,
                                entrancePrice: entrance.isNullOrEmpty() ? null : entrance.numDouble(),
                                hourlyPrice: hourly.isNullOrEmpty() ? null : hourly.numDouble(),
                                dailyPrice: daily.isNullOrEmpty() ? null : daily.numDouble(),
                                adminUserIds: adminUserIds,
                              ),
                            );
                          UNavigator.back();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
