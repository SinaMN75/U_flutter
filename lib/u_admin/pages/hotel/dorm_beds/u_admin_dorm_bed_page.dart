import "package:u/utilities.dart";

class UAdminDormBedPage extends StatefulWidget {
  const UAdminDormBedPage({this.room, this.dorm, super.key});

  final UDormRoomResponse? room;
  final UDormResponse? dorm;

  @override
  State<UAdminDormBedPage> createState() => _DormBedPageState();
}

class _DormBedPageState extends State<UAdminDormBedPage> {
  final UAdminDormBedController c = UAdminDormBedController();

  @override
  void initState() {
    c.init(room: widget.room, dorm: widget.dorm);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.room != null
        ? "${U.s.beds} · ${widget.room!.title}"
        : widget.dorm != null
        ? "${U.s.beds} · ${widget.dorm!.title}"
        : U.s.dormBeds,
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageDorms) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UDormBedResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.beds),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.deposit, U.s.rent, U.s.occupancy, U.s.operations]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  bool _isFree(UDormBedResponse i) => i.contracts?.where((UDormBedContractResponse i) => i.isActive).isEmpty ?? true;

  Widget _itemDesktop(UDormBedResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.deposit.rial()),
      UAdminTable.cell(i.monthlyRent.rial()),
      UAdminTable.statusChip(context, label: _isFree(i) ? U.s.free : U.s.occupied, color: _isFree(i) ? UAdminTheme.green : UAdminTheme.orange).alignAtCenter().expanded(),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UDormBedResponse i, int index) => UAdminTable.mobileCard(
    context,
    icon: Icons.bed_rounded,
    title: i.title,
    badge: UAdminTable.statusChip(context, label: _isFree(i) ? U.s.free : U.s.occupied, color: _isFree(i) ? UAdminTheme.green : UAdminTheme.orange),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.deposit, i.deposit.rial()),
      UAdminField(U.s.rent, i.monthlyRent.rial()),
    ],
  );

  Widget _menu(UDormBedResponse i) => UAdminOps.menu<UDormBedResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UDormBedResponse>(
      onEdit: (UDormBedResponse b) => _showEditDialog(p: b),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UDormBedResponse> ctx) => <UAdminAction>[
      UAdminLinks.bedContracts(ctx.item),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageDorms]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteDorms]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.beds)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title).pSymmetric(vertical: 6),
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

  void _showEditDialog({UDormBedResponse? p}) {
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController deposit = TextEditingController(text: p?.deposit.toInt().toString());
    final TextEditingController rent = TextEditingController(text: p?.monthlyRent.toInt().toString());
    final TextEditingController detail = TextEditingController(text: p?.jsonData.detail1);
    final Rxn<UDormRoomResponse> room = Rxn<UDormRoomResponse>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(p == null ? U.s.createItem(U.s.bed) : U.s.editItem(U.s.bed)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setLocal) => Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(
                      controller: title,
                      labelText: U.s.title,
                      validator: UValidators.required(message: ""),
                    ).pSymmetric(vertical: 6),
                    if (widget.room == null)
                      UTextFieldAutoCompleteAsync<UDormRoomResponse>(
                        labelBuilder: (UDormRoomResponse i) => i.dorm == null ? i.title : "${i.dorm!.title} · ${i.title}",
                        onChanged: room.call,
                        selectedItem: room.value,
                        fetchData: c.readRooms,
                        hintText: U.s.room,
                      ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: deposit,
                      labelText: U.s.deposit,
                      keyboardType: TextInputType.number,
                      validator: UValidators.required(message: ""),
                      formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                    ).pSymmetric(vertical: 6),
                    UTextField(
                      controller: rent,
                      labelText: U.s.rent,
                      keyboardType: TextInputType.number,
                      validator: UValidators.required(message: ""),
                      formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: detail, labelText: U.s.description, lines: 2).pSymmetric(vertical: 6),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final String? rid = room.value?.id ?? widget.room?.id;
                          if (rid == null) {
                            UToast.error(message: U.s.pleaseSelectA(U.s.room));
                            return;
                          }
                          if (p == null) {
                            c.create(
                              p: UDormBedCreateParams(
                                tags: <int>[TagDormBed.single.number],
                                title: title.text,
                                deposit: deposit.numDouble(),
                                monthlyRent: rent.numDouble(),
                                roomId: rid,
                                detail1: detail.text.nullIfEmpty(),
                              ),
                            );
                          } else {
                            c.update(
                              p: UDormBedUpdateParams(
                                id: p.id,
                                title: title.text,
                                deposit: deposit.numDouble(),
                                monthlyRent: rent.numDouble(),
                                roomId: rid,
                                detail1: detail.text.nullIfEmpty(),
                              ),
                            );
                          }
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
