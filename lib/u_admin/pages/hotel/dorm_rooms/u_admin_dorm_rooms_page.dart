import "package:u/utilities.dart";

class UAdminDormRoomPage extends StatefulWidget {
  const UAdminDormRoomPage({this.dorm, super.key});

  final UDormResponse? dorm;

  @override
  State<UAdminDormRoomPage> createState() => _DormRoomPageState();
}

class _DormRoomPageState extends State<UAdminDormRoomPage> {
  final UAdminDormRoomController c = UAdminDormRoomController();

  @override
  void initState() {
    c.init(dorm: widget.dorm);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: widget.dorm?.title == null ? U.s.dormRooms : "${U.s.rooms} · ${widget.dorm?.title}",
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageDorms) ? _showEditDialog : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UDormRoomResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.room),
      desktopHeader: () => UAdminTable.header(<String>[U.s.title, U.s.dorm, U.s.beds, U.s.created, U.s.operations]),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _itemDesktop(UDormRoomResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(i.title),
      UAdminTable.cell(i.dorm?.title ?? "-"),
      UAdminTable.cell((i.beds?.length ?? 0).toString()),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UDormRoomResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.meeting_room_rounded,
    title: i.title,
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.dorm, i.dorm?.title ?? "-"),
      UAdminField(U.s.beds, (i.beds?.length ?? 0).toString()),
      UAdminField(U.s.created, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UDormRoomResponse i) => UAdminOps.menu<UDormRoomResponse>(
    item: i,
    handlers: UAdminActionHandlers<UDormRoomResponse>(
      onEdit: (UDormRoomResponse r) => _showEditDialog(p: r),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UDormRoomResponse> ctx) => <UAdminAction>[
      UAdminLinks.roomBeds(ctx.item),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageDorms]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteDorms]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.rooms)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
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

  void _showEditDialog({UDormRoomResponse? p}) {
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController detail = TextEditingController(text: p?.jsonData.detail1);
    final Rxn<UDormResponse> dorm = Rxn<UDormResponse>();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    UNavigator.dialog(
      AlertDialog(
        title: Text(p == null ? U.s.createItem(U.s.room) : U.s.editItem(U.s.rooms)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(
                    controller: title,
                    labelText: U.s.title,
                    validator: UValidators.required(message: ""),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  if (widget.dorm == null)
                    UTextFieldAutoCompleteAsync<UDormResponse>(
                      labelBuilder: (UDormResponse i) => i.title,
                      onChanged: dorm.call,
                      selectedItem: dorm.value,
                      fetchData: c.readDorms,
                      hintText: U.s.dorm,
                    ).pSymmetric(vertical: 6),
                  UTextField(controller: detail, labelText: U.s.description, margin: const EdgeInsets.symmetric(vertical: 6)),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    onSubmit: () => UValidators.validateForm(
                      key: formKey,
                      action: () {
                        final String? did = dorm.value?.id ?? widget.dorm?.id;
                        if (did == null) {
                          UToast.error(message: U.s.pleaseSelectA(U.s.dorm));
                          return;
                        }
                        if (p == null) {
                          c.create(
                            p: UDormRoomCreateParams(
                              tags: <int>[TagDormRoom.dorm.number],
                              title: title.text,
                              dormId: did,
                              detail1: detail.text.nullIfEmpty(),
                            ),
                          );
                        } else {
                          c.update(
                            p: UDormRoomUpdateParams(
                              id: p.id,
                              title: title.text,
                              dormId: did,
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
    );
  }
}
