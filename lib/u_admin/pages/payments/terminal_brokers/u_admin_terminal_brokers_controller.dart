part of "../../../u_admin.dart";

class UAdminTerminalBrokerController extends UBaseController {
  List<UTerminalBrokerResponse> list = <UTerminalBrokerResponse>[];

  late final TextEditingController codeFilter = fields.text();
  late final TextEditingController titleFilter = fields.text();

  UTerminalBrokerResponse? editing;
  late final TextEditingController code = fields.text();
  late final TextEditingController title = fields.text();
  late final TextEditingController registrationNumber = fields.text();
  late final TextEditingController nationalCode = fields.text();
  late final TextEditingController representative = fields.text();
  late final TextEditingController address = fields.text();
  late final TextEditingController postalCode = fields.text();
  late final TextEditingController phoneNumber = fields.text();
  late final TextEditingController sign1Owner = fields.text();
  late final TextEditingController sign2Owner = fields.text();
  String? logoBase64;
  String? sign1Base64;
  String? sign2Base64;

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.terminal.readBroker(
      p: UTerminalBrokerReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        code: codeFilter.text.nullIfEmpty(),
        title: titleFilter.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
        selectorArgs: const UTerminalBrokerSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrokerResponse>> r) {
        list = r.result ?? <UTerminalBrokerResponse>[];
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
    reloadFirstPage(read);
  }

  void loadForm(UTerminalBrokerResponse? b) {
    editing = b;
    code.text = b?.code ?? "";
    title.text = b?.title ?? "";
    registrationNumber.text = b?.jsonData.registrationNumber ?? "";
    nationalCode.text = b?.jsonData.nationalCode ?? "";
    representative.text = b?.jsonData.representative ?? "";
    address.text = b?.jsonData.address ?? "";
    postalCode.text = b?.jsonData.postalCode ?? "";
    phoneNumber.text = b?.jsonData.phoneNumber ?? "";
    sign1Owner.text = b?.jsonData.sign1Owner ?? "";
    sign2Owner.text = b?.jsonData.sign2Owner ?? "";
    logoBase64 = b?.jsonData.logoBase64;
    sign1Base64 = b?.jsonData.sign1Base64;
    sign2Base64 = b?.jsonData.sign2Base64;
  }

  Future<bool> save() async {
    final UTerminalBrokerResponse? b = editing;
    if (b == null && (logoBase64.isNullOrEmpty() || sign1Base64.isNullOrEmpty())) {
      UToast.error(message: U.s.required);
      return false;
    }
    final dynamic ok = await submit(
      b == null
          ? UServices.terminal.createBroker(
              p: UTerminalBrokerCreateParams(
                tags: <int>[TagTerminalBroker.test.number],
                code: code.text.trim(),
                title: title.text.trim(),
                registrationNumber: registrationNumber.text.trim(),
                nationalCode: nationalCode.text.trim(),
                representative: representative.text.trim(),
                address: address.text.trim(),
                postalCode: postalCode.text.trim(),
                phoneNumber: phoneNumber.text.trim(),
                sign1Base64: sign1Base64!,
                sign1Owner: sign1Owner.text.trim(),
                sign2Base64: sign2Base64,
                sign2Owner: sign2Owner.text.trim().nullIfEmpty(),
                logoBase64: logoBase64!,
              ),
            )
          : UServices.terminal.updateBroker(
              p: UTerminalBrokerUpdateParams(
                id: b.id,
                code: code.text.trim(),
                title: title.text.trim(),
                registrationNumber: registrationNumber.text.trim(),
                nationalCode: nationalCode.text.trim(),
                representative: representative.text.trim(),
                address: address.text.trim(),
                postalCode: postalCode.text.trim(),
                phoneNumber: phoneNumber.text.trim(),
                sign1Base64: sign1Base64,
                sign1Owner: sign1Owner.text.trim(),
                sign2Base64: sign2Base64,
                sign2Owner: sign2Owner.text.trim(),
                logoBase64: logoBase64,
              ),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UTerminalBrokerResponse i) => confirmAction(() => UServices.terminal.deleteBroker(p: UIdParams(id: i.id)), read);
}
