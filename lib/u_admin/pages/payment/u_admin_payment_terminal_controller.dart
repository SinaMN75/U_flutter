part of "../../u_admin.dart";

class UAdminPaymentTerminalController extends UBaseController {
  List<UTerminalResponse> list = <UTerminalResponse>[];
  UMerchantResponse? merchant;

  final TextEditingController serialFilterController = TextEditingController();
  final TextEditingController merchantIdFilterController = TextEditingController();
  final TextEditingController creatorIdFilterController = TextEditingController();
  TagTerminal? typeFilter;
  UTerminalBrandResponse? brandFilter;
  UTerminalBrokerResponse? brokerFilter;

  UTerminalResponse? editing;
  final TextEditingController serialController = TextEditingController();
  final TextEditingController simCardNumberController = TextEditingController();
  final TextEditingController simCardSerialController = TextEditingController();
  final TextEditingController imeiController = TextEditingController();
  final TextEditingController terminalIdController = TextEditingController();
  UTerminalBrandResponse? brand;
  UTerminalBrokerResponse? broker;

  final TextEditingController rejectReasonController = TextEditingController();

  final TextEditingController otpSerialController = TextEditingController();
  final TextEditingController otpLengthController = TextEditingController(text: "6");
  final TextEditingController otpCodeController = TextEditingController();
  bool otpGenerate = true;
  bool otpAdmin = false;
  String otpResult = "";
  bool? otpValid;

  Future<void> init({UMerchantResponse? merchant}) {
    this.merchant = merchant;
    return read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.terminal.read(
      p: UTerminalReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        merchantId: merchant?.id ?? merchantIdFilterController.text.nullIfEmpty(),
        serial: serialFilterController.text.nullIfEmpty(),
        creatorId: creatorIdFilterController.text.nullIfEmpty(),
        terminalBrandId: brandFilter?.id,
        terminalBrokerId: brokerFilter?.id,
        tags: typeFilter == null ? null : <int>[typeFilter!.number],
        fromCreatedAt: startDate,
        toCreatedAt: endDate,
        orderBy: tagOrderBy.value.number,
        selectorArgs: const UTerminalSelectorArgs(merchant: UMerchantSelectorArgs(), terminalBrand: UTerminalBrandSelectorArgs(), terminalBroker: UTerminalBrokerSelectorArgs()),
      ),
      onOk: (UResponse<List<UTerminalResponse>> r) {
        list = r.result ?? <UTerminalResponse>[];
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
    serialFilterController.clear();
    merchantIdFilterController.clear();
    creatorIdFilterController.clear();
    typeFilter = null;
    brandFilter = null;
    brokerFilter = null;
    clearDates();
    pageNumber(1);
    read();
  }

  void loadForm(UTerminalResponse? t) {
    editing = t;
    serialController.text = t?.serial ?? "";
    simCardNumberController.text = t?.simCardNumber ?? "";
    simCardSerialController.text = t?.simCardSerial ?? "";
    imeiController.text = t?.imei ?? "";
    terminalIdController.text = t?.terminalId ?? "";
    brand = t?.terminalBrand;
    broker = t?.terminalBroker;
  }

  Future<bool> save() async {
    final UTerminalResponse? t = editing;
    if (t == null && (brand == null || broker == null)) {
      UToast.error(message: U.s.required);
      return false;
    }
    return await submit(
      t == null
          ? UServices.terminal.create(
              p: UTerminalCreateParams(
                tags: <int>[TagTerminal.notAssigned.number],
                serial: serialController.text.trim(),
                simCardNumber: simCardNumberController.text.nullIfEmpty(),
                simCardSerial: simCardSerialController.text.nullIfEmpty(),
                imei: imeiController.text.nullIfEmpty(),
                terminalBrandId: brand!.id,
                terminalBrokerId: broker!.id,
              ),
            )
          : UServices.terminal.update(
              p: UTerminalUpdateParams(
                id: t.id,
                serial: serialController.text.nullIfEmpty(),
                simCardNumber: simCardNumberController.text.nullIfEmpty(),
                simCardSerial: simCardSerialController.text.nullIfEmpty(),
                imei: imeiController.text.nullIfEmpty(),
                terminalId: terminalIdController.text.nullIfEmpty(),
                terminalBrandId: brand?.id,
                terminalBrokerId: broker?.id,
              ),
            ),
      read,
    ) !=
        null;
  }

  void approve(UTerminalResponse i) => confirmAction(
    () => UServices.terminal.approve(p: UIdParams(id: i.id)),
    read,
    title: U.s.approve,
    message: U.s.areYouSureYouWantToApproveAndRegisterThisTerminalInTheAvreenSystem,
  );

  Future<bool> reject(UTerminalResponse i) async =>
      await submit(UServices.terminal.reject(p: UTerminalRejectParams(id: i.id, reason: rejectReasonController.text.nullIfEmpty())), read) != null;

  void delete(UTerminalResponse i) => confirmAction(() => UServices.terminal.delete(p: UIdParams(id: i.id)), read);

  Future<void> viewAgreement(UTerminalResponse i) async {
    ULoading.show();
    final (UResponse<List<UTerminalResponse>>? ok, UEmptyResponse? error, String? exception) = await UServices.terminal.read(
      p: UTerminalReadParams(ids: <String>[i.id], selectorArgs: const UTerminalSelectorArgs(agreement: true)),
    );
    ULoading.dismiss();
    if (ok == null) return UToast.error(message: error?.message ?? exception ?? U.s.errorReadingData);
    final String? agreement = ok.result?.firstOrNull?.agreement;
    if (agreement == null) return UToast.error(message: U.s.noItemsFound(U.s.agreement));
    unawaited(UPdf.open(base64Pdf: agreement));
  }

  Future<String?> supportPassword(UTerminalResponse i) async {
    ULoading.show();
    final (UResponse<UTerminalSupportPasswordResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.terminal.readSupportPassword(p: UIdParams(id: i.id));
    ULoading.dismiss();
    if (ok == null) UToast.error(message: error?.message ?? exception ?? U.s.errorReadingData);
    return ok == null ? null : ok.result?.password ?? "-";
  }

  void import(void Function(UTerminalImportResponse r) onResult) => UFile.showFilePicker(
    allowedExtensions: const <String>["xlsx"],
    action: (List<UFileData> files) async {
      if (files.length != 1 || files.first.bytes == null || !(files.first.extension ?? "").toLowerCase().contains("xlsx")) return;
      ULoading.show();
      final (UResponse<UTerminalImportResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.terminal.import(
        p: UTerminalImportParams(file: files.first.bytes!.toBase64()),
      );
      ULoading.dismiss();
      if (ok == null) return UToast.error(message: error?.message ?? exception ?? U.s.errorReadingData);
      unawaited(read());
      if (ok.result != null) onResult(ok.result!);
    },
  );

  void loadOtp() {
    otpSerialController.clear();
    otpLengthController.text = "6";
    otpCodeController.clear();
    otpGenerate = true;
    otpAdmin = false;
    otpResult = "";
    otpValid = null;
  }

  void runOtp() {
    final String s = otpSerialController.text.trim();
    if (s.isEmpty) return UToast.error(message: U.s.required);
    if (otpGenerate) {
      final int len = int.tryParse(otpLengthController.text.trim()) ?? 6;
      otpResult = otpAdmin ? UOtp.generateAdminOtp(s, len) : UOtp.generateOtp(s, len);
      otpValid = null;
      return;
    }
    final String code = otpCodeController.text.trim();
    if (code.isEmpty) return UToast.error(message: U.s.required);
    otpValid = otpAdmin ? UOtp.verifyAdminOtp(s, code) : UOtp.verifyOtp(s, code);
    otpResult = "";
  }

  Future<List<UTerminalBrandResponse>> searchBrands(String query) async =>
      ((await UServices.terminal.readBrand(p: UTerminalBrandReadParams(pageSize: 100, selectorArgs: const UTerminalBrandSelectorArgs()))).$1?.result ?? <UTerminalBrandResponse>[])
          .where((UTerminalBrandResponse x) => _matches(query, x.title, x.code))
          .toList();

  Future<List<UTerminalBrokerResponse>> searchBrokers(String query) async =>
      ((await UServices.terminal.readBroker(p: UTerminalBrokerReadParams(pageSize: 100, selectorArgs: const UTerminalBrokerSelectorArgs()))).$1?.result ?? <UTerminalBrokerResponse>[])
          .where((UTerminalBrokerResponse x) => _matches(query, x.title, x.code))
          .toList();

  bool _matches(String query, String title, String code) {
    final String q = query.trim().toLowerCase();
    return q.isEmpty || title.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }

  @override
  void dispose() {
    serialFilterController.dispose();
    merchantIdFilterController.dispose();
    creatorIdFilterController.dispose();
    serialController.dispose();
    simCardNumberController.dispose();
    simCardSerialController.dispose();
    imeiController.dispose();
    terminalIdController.dispose();
    rejectReasonController.dispose();
    otpSerialController.dispose();
    otpLengthController.dispose();
    otpCodeController.dispose();
    super.dispose();
  }
}
