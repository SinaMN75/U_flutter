part of "../../../u_admin.dart";

class UAdminTerminalBrandController extends UBaseController {
  List<UTerminalBrandResponse> list = <UTerminalBrandResponse>[];

  static const List<TagTerminalBrand> deviceTypes = <TagTerminalBrand>[TagTerminalBrand.atm, TagTerminalBrand.wallCashless, TagTerminalBrand.deskCashless];
  static const List<TagTerminalBrand> connectionTypes = <TagTerminalBrand>[TagTerminalBrand.simCard, TagTerminalBrand.wifi];

  static TagTerminalBrand? deviceTypeOf(UTerminalBrandResponse i) => deviceTypes.firstWhereOrNull((TagTerminalBrand x) => i.tags.contains(x.number));

  static TagTerminalBrand? connectionTypeOf(UTerminalBrandResponse i) => connectionTypes.firstWhereOrNull((TagTerminalBrand x) => i.tags.contains(x.number));

  late final TextEditingController codeFilter = fields.text();
  late final TextEditingController titleFilter = fields.text();
  late final TextEditingController modelFilter = fields.text();

  UTerminalBrandResponse? editing;
  late final TextEditingController code = fields.text();
  late final TextEditingController title = fields.text();
  late final TextEditingController model = fields.text();
  TagTerminalBrand deviceType = TagTerminalBrand.wallCashless;
  TagTerminalBrand connectionType = TagTerminalBrand.simCard;

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.terminal.readBrand(
      p: UTerminalBrandReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        code: codeFilter.text.nullIfEmpty(),
        title: titleFilter.text.nullIfEmpty(),
        model: modelFilter.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
        selectorArgs: const UTerminalBrandSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrandResponse>> r) {
        list = r.result ?? <UTerminalBrandResponse>[];
        totalCount = r.totalCount;
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: setError,
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    codeFilter.clear();
    titleFilter.clear();
    modelFilter.clear();
    reloadFirstPage(read);
  }

  void loadForm(UTerminalBrandResponse? b) {
    editing = b;
    code.text = b?.code ?? "";
    title.text = b?.title ?? "";
    model.text = b?.model ?? "";
    deviceType = (b == null ? null : deviceTypeOf(b)) ?? TagTerminalBrand.wallCashless;
    connectionType = (b == null ? null : connectionTypeOf(b)) ?? TagTerminalBrand.simCard;
  }

  Future<bool> save() async {
    final UTerminalBrandResponse? b = editing;
    final List<int> tags = <int>[deviceType.number, connectionType.number];
    final dynamic ok = await submit(
      b == null
          ? UServices.terminal.createBrand(p: UTerminalBrandCreateParams(code: code.text.trim(), title: title.text.trim(), model: model.text.trim(), tags: tags))
          : UServices.terminal.updateBrand(
              p: UTerminalBrandUpdateParams(id: b.id, code: code.text.trim().nullIfEmpty(), title: title.text.nullIfEmpty(), model: model.text.nullIfEmpty(), tags: tags),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UTerminalBrandResponse i) => confirmAction(() => UServices.terminal.deleteBrand(p: UIdParams(id: i.id)), read);
}
