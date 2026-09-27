part of "../../../u_admin.dart";

class UAdminTerminalController extends UBaseController {
  List<UTerminalResponse> list = <UTerminalResponse>[];
  UMerchantResponse? merchant;

  late final TextEditingController serialFilter = fields.text();
  late final TextEditingController merchantIdFilter = fields.text();
  late final TextEditingController creatorIdFilter = fields.text();
  late final TextEditingController fromCreatedController = fields.text();
  late final TextEditingController toCreatedController = fields.text();
  TagTerminal? typeFilter;
  UTerminalBrandResponse? brandFilter;
  UTerminalBrokerResponse? brokerFilter;

  UTerminalResponse? editing;
  late final TextEditingController serial = fields.text();
  late final TextEditingController simCardNumber = fields.text();
  late final TextEditingController simCardSerial = fields.text();
  late final TextEditingController imei = fields.text();
  late final TextEditingController terminalId = fields.text();
  UTerminalBrandResponse? brand;
  UTerminalBrokerResponse? broker;

  late final TextEditingController rejectReason = fields.text();

  late final TextEditingController otpSerial = fields.text();
  late final TextEditingController otpLength = fields.text("6");
  late final TextEditingController otpCode = fields.text();
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
        merchantId: merchant?.id ?? merchantIdFilter.text.nullIfEmpty(),
        serial: serialFilter.text.nullIfEmpty(),
        creatorId: creatorIdFilter.text.nullIfEmpty(),
        terminalBrandId: brandFilter?.id,
        terminalBrokerId: brokerFilter?.id,
        tags: typeFilter == null ? null : <int>[typeFilter!.number],
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        orderBy: tagOrderBy.value.number,
        selectorArgs: const UTerminalSelectorArgs(merchant: UMerchantSelectorArgs(), terminalBrand: UTerminalBrandSelectorArgs(), terminalBroker: UTerminalBrokerSelectorArgs()),
      ),
      onOk: (UResponse<List<UTerminalResponse>> r) {
        list = r.result ?? <UTerminalResponse>[];
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
    serialFilter.clear();
    merchantIdFilter.clear();
    creatorIdFilter.clear();
    fromCreatedController.clear();
    toCreatedController.clear();
    typeFilter = null;
    brandFilter = null;
    brokerFilter = null;
    reloadFirstPage(read);
  }

  void loadForm(UTerminalResponse? t) {
    editing = t;
    serial.text = t?.serial ?? "";
    simCardNumber.text = t?.simCardNumber ?? "";
    simCardSerial.text = t?.simCardSerial ?? "";
    imei.text = t?.imei ?? "";
    terminalId.text = t?.terminalId ?? "";
    brand = t?.terminalBrand;
    broker = t?.terminalBroker;
  }

  Future<bool> save() async {
    final UTerminalResponse? t = editing;
    if (t == null && (brand == null || broker == null)) {
      UToast.error(message: U.s.required);
      return false;
    }
    final dynamic ok = await submit(
      t == null
          ? UServices.terminal.create(
              p: UTerminalCreateParams(
                tags: <int>[TagTerminal.notAssigned.number],
                serial: serial.text.trim(),
                simCardNumber: simCardNumber.text.nullIfEmpty(),
                simCardSerial: simCardSerial.text.nullIfEmpty(),
                imei: imei.text.nullIfEmpty(),
                terminalBrandId: brand!.id,
                terminalBrokerId: broker!.id,
              ),
            )
          : UServices.terminal.update(
              p: UTerminalUpdateParams(
                id: t.id,
                serial: serial.text.nullIfEmpty(),
                simCardNumber: simCardNumber.text.nullIfEmpty(),
                simCardSerial: simCardSerial.text.nullIfEmpty(),
                imei: imei.text.nullIfEmpty(),
                terminalId: terminalId.text.nullIfEmpty(),
                terminalBrandId: brand?.id,
                terminalBrokerId: broker?.id,
              ),
            ),
      read,
    );
    return ok != null;
  }

  void approve(UTerminalResponse i) => confirmAction(
    () => UServices.terminal.approve(p: UIdParams(id: i.id)),
    read,
    title: U.s.approve,
    message: U.s.areYouSureYouWantToApproveAndRegisterThisTerminalInTheAvreenSystem,
  );

  Future<bool> reject(UTerminalResponse i) async =>
      await submit(UServices.terminal.reject(p: UTerminalRejectParams(id: i.id, reason: rejectReason.text.nullIfEmpty())), read) != null;

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
    otpSerial.clear();
    otpLength.text = "6";
    otpCode.clear();
    otpGenerate = true;
    otpAdmin = false;
    otpResult = "";
    otpValid = null;
  }

  void runOtp() {
    final String s = otpSerial.text.trim();
    if (s.isEmpty) return UToast.error(message: U.s.required);
    if (otpGenerate) {
      final int len = int.tryParse(otpLength.text.trim()) ?? 6;
      otpResult = otpAdmin ? UOtp.generateAdminOtp(s, len) : UOtp.generateOtp(s, len);
      otpValid = null;
      return;
    }
    final String code = otpCode.text.trim();
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
}
