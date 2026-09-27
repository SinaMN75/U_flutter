part of "../../../u_admin.dart";

class UAdminTerminalBrokerController extends UBaseController {
  List<UTerminalBrokerResponse> list = <UTerminalBrokerResponse>[];

  final TextEditingController codeFilterController = TextEditingController();
  final TextEditingController titleFilterController = TextEditingController();

  UTerminalBrokerResponse? editing;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController registrationNumberController = TextEditingController();
  final TextEditingController nationalCodeController = TextEditingController();
  final TextEditingController representativeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController sign1OwnerController = TextEditingController();
  final TextEditingController sign2OwnerController = TextEditingController();
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
        code: codeFilterController.text.nullIfEmpty(),
        title: titleFilterController.text.nullIfEmpty(),
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
    codeFilterController.clear();
    titleFilterController.clear();
    reloadFirstPage(read);
  }

  void loadForm(UTerminalBrokerResponse? b) {
    editing = b;
    codeController.text = b?.code ?? "";
    titleController.text = b?.title ?? "";
    registrationNumberController.text = b?.jsonData.registrationNumber ?? "";
    nationalCodeController.text = b?.jsonData.nationalCode ?? "";
    representativeController.text = b?.jsonData.representative ?? "";
    addressController.text = b?.jsonData.address ?? "";
    postalCodeController.text = b?.jsonData.postalCode ?? "";
    phoneNumberController.text = b?.jsonData.phoneNumber ?? "";
    sign1OwnerController.text = b?.jsonData.sign1Owner ?? "";
    sign2OwnerController.text = b?.jsonData.sign2Owner ?? "";
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
                code: codeController.text.trim(),
                title: titleController.text.trim(),
                registrationNumber: registrationNumberController.text.trim(),
                nationalCode: nationalCodeController.text.trim(),
                representative: representativeController.text.trim(),
                address: addressController.text.trim(),
                postalCode: postalCodeController.text.trim(),
                phoneNumber: phoneNumberController.text.trim(),
                sign1Base64: sign1Base64!,
                sign1Owner: sign1OwnerController.text.trim(),
                sign2Base64: sign2Base64,
                sign2Owner: sign2OwnerController.text.trim().nullIfEmpty(),
                logoBase64: logoBase64!,
              ),
            )
          : UServices.terminal.updateBroker(
              p: UTerminalBrokerUpdateParams(
                id: b.id,
                code: codeController.text.trim(),
                title: titleController.text.trim(),
                registrationNumber: registrationNumberController.text.trim(),
                nationalCode: nationalCodeController.text.trim(),
                representative: representativeController.text.trim(),
                address: addressController.text.trim(),
                postalCode: postalCodeController.text.trim(),
                phoneNumber: phoneNumberController.text.trim(),
                sign1Base64: sign1Base64,
                sign1Owner: sign1OwnerController.text.trim(),
                sign2Base64: sign2Base64,
                sign2Owner: sign2OwnerController.text.trim(),
                logoBase64: logoBase64,
              ),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UTerminalBrokerResponse i) => confirmAction(() => UServices.terminal.deleteBroker(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    codeFilterController.dispose();
    titleFilterController.dispose();
    codeController.dispose();
    titleController.dispose();
    registrationNumberController.dispose();
    nationalCodeController.dispose();
    representativeController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    phoneNumberController.dispose();
    sign1OwnerController.dispose();
    sign2OwnerController.dispose();
    super.dispose();
  }
}
