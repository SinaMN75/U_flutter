part of "../../u_admin.dart";

class UAdminPaymentTerminalBrandController extends UAdminBaseController {
  List<UTerminalBrandResponse> list = <UTerminalBrandResponse>[];

  static const List<TagTerminalBrand> deviceTypes = <TagTerminalBrand>[TagTerminalBrand.atm, TagTerminalBrand.wallCashless, TagTerminalBrand.deskCashless];
  static const List<TagTerminalBrand> connectionTypes = <TagTerminalBrand>[TagTerminalBrand.simCard, TagTerminalBrand.wifi];

  static TagTerminalBrand? deviceTypeOf(UTerminalBrandResponse i) => deviceTypes.firstWhereOrNull((TagTerminalBrand x) => i.tags.contains(x.number));

  static TagTerminalBrand? connectionTypeOf(UTerminalBrandResponse i) => connectionTypes.firstWhereOrNull((TagTerminalBrand x) => i.tags.contains(x.number));

  final TextEditingController codeFilterController = TextEditingController();
  final TextEditingController titleFilterController = TextEditingController();
  final TextEditingController modelFilterController = TextEditingController();

  UTerminalBrandResponse? editing;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  TagTerminalBrand deviceType = TagTerminalBrand.wallCashless;
  TagTerminalBrand connectionType = TagTerminalBrand.simCard;

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.terminal.readBrand(
      p: UTerminalBrandReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        code: codeFilterController.text.nullIfEmpty(),
        title: titleFilterController.text.nullIfEmpty(),
        model: modelFilterController.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
        selectorArgs: const UTerminalBrandSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrandResponse>> r) {
        list = r.result ?? <UTerminalBrandResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    codeFilterController.clear();
    titleFilterController.clear();
    modelFilterController.clear();
    pageNumber(1);
    read();
  }

  void loadForm(UTerminalBrandResponse? b) {
    editing = b;
    codeController.text = b?.code ?? "";
    titleController.text = b?.title ?? "";
    modelController.text = b?.model ?? "";
    deviceType = (b == null ? null : deviceTypeOf(b)) ?? TagTerminalBrand.wallCashless;
    connectionType = (b == null ? null : connectionTypeOf(b)) ?? TagTerminalBrand.simCard;
  }

  Future<bool> save() async {
    final UTerminalBrandResponse? b = editing;
    final List<int> tags = <int>[deviceType.number, connectionType.number];
    return await submit(
      b == null
          ? UServices.terminal.createBrand(p: UTerminalBrandCreateParams(code: codeController.text.trim(), title: titleController.text.trim(), model: modelController.text.trim(), tags: tags))
          : UServices.terminal.updateBrand(
              p: UTerminalBrandUpdateParams(id: b.id, code: codeController.text.trim().nullIfEmpty(), title: titleController.text.nullIfEmpty(), model: modelController.text.nullIfEmpty(), tags: tags),
            ),
      read,
    ) !=
        null;
  }

  void delete(UTerminalBrandResponse i) => confirmAction(() => UServices.terminal.deleteBrand(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    codeFilterController.dispose();
    titleFilterController.dispose();
    modelFilterController.dispose();
    codeController.dispose();
    titleController.dispose();
    modelController.dispose();
    super.dispose();
  }
}
