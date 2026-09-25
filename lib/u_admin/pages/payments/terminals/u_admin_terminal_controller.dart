part of "../../../u_admin.dart";

class UAdminTerminalController extends UBaseController {
  List<UTerminalResponse> list = <UTerminalResponse>[];

  UMerchantResponse? merchant;

  final TextEditingController serialFilter = TextEditingController();
  final TextEditingController merchantIdFilter = TextEditingController();
  final TextEditingController creatorIdFilter = TextEditingController();
  final TextEditingController fromCreatedController = TextEditingController();
  final TextEditingController toCreatedController = TextEditingController();
  URxn<TagTerminal> typeFilter = URxn<TagTerminal>();
  URxn<UTerminalBrandResponse> brandFilter = URxn<UTerminalBrandResponse>();
  URxn<UTerminalBrokerResponse> brokerFilter = URxn<UTerminalBrokerResponse>();

  Future<void> init({UMerchantResponse? merchant}) async {
    this.merchant = merchant;
    await read();
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
        terminalBrandId: brandFilter.value?.id,
        terminalBrokerId: brokerFilter.value?.id,
        tags: typeFilter.value == null ? null : <int>[typeFilter.value!.number],
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
    typeFilter(null);
    brandFilter(null);
    brokerFilter(null);
    reloadFirstPage(read);
  }

  void create({required UTerminalCreateParams p}) {
    ULoading.show();
    UServices.terminal.create(
      p: p,
      onOk: (UResponse<String> r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        errorCallBack(U.s.errorSubmittingForm, read);
      },
    );
  }

  void bulkCreate({required UTerminalBulkCreateParams p}) {
    ULoading.show();
    UServices.terminal.bulkCreate(
      p: p,
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        errorCallBack(U.s.errorSubmittingForm, read);
      },
    );
  }

  void update({required UTerminalUpdateParams p}) {
    ULoading.show();
    UServices.terminal.update(
      p: p,
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        errorCallBack(U.s.errorSubmittingForm, read);
      },
    );
  }

  void assign({required UTerminalAssignParams p}) {
    ULoading.show();
    UServices.terminal.assign(
      p: p,
      onOk: (UResponse<UTerminalResponse> r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        errorCallBack(U.s.errorSubmittingForm, read);
      },
    );
  }

  void approve(UTerminalResponse i) => UNavigator.confirm(
    title: U.s.approve,
    message: U.s.areYouSureYouWantToApproveAndRegisterThisTerminalInTheAvreenSystem,
    onConfirm: () {
      ULoading.show();
      UServices.terminal.approve(
        p: UIdParams(id: i.id),
        onOk: (UResponse<UTerminalResponse> r) {
          ULoading.dismiss();
          okCallback(r.message, read);
        },
        onError: (UEmptyResponse r) {
          ULoading.dismiss();
          errorCallBack(r.message, read);
        },
        onException: (String e) {
          ULoading.dismiss();
          UToast.error(message: e);
        },
      );
    },
  );

  void reject({required UTerminalResponse i, String? reason}) {
    ULoading.show();
    UServices.terminal.reject(
      p: UTerminalRejectParams(id: i.id, reason: reason),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void viewAgreement(UTerminalResponse i) {
    ULoading.show();
    UServices.terminal.read(
      p: UTerminalReadParams(
        ids: <String>[i.id],
        selectorArgs: const UTerminalSelectorArgs(agreement: true),
      ),
      onOk: (UResponse<List<UTerminalResponse>> r) {
        ULoading.dismiss();
        final String? agreement = r.result?.firstOrNull?.agreement;
        if (agreement == null) {
          UToast.error(message: U.s.noItemsFound(U.s.agreement));
          return;
        }
        UPdf.open(base64Pdf: agreement);
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.error(message: r.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void supportPassword(UTerminalResponse i) {
    ULoading.show();
    UServices.terminal.readSupportPassword(
      p: UIdParams(id: i.id),
      onOk: (UResponse<UTerminalSupportPasswordResponse> r) {
        ULoading.dismiss();
        final String pass = r.result?.password ?? "-";
        UNavigator.dialog(
          AlertDialog(
            title: Text(U.s.supportPassword),
            content: SelectableText(pass, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            actions: <Widget>[
              UButton(
                type: UButtonType.text,
                title: U.s.ok,
                onTap: () {
                  UClipboard.set(pass);
                  UNavigator.back();
                },
              ),
            ],
          ),
        );
      },
      onError: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.error(message: r.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void delete(UTerminalResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.terminal.delete(
      p: UIdParams(id: i.id),
      onOk: (UEmptyResponse r) {
        UNavigator.back();
        okCallback(r.message, read);
      },
      onError: (UEmptyResponse r) {
        UNavigator.back();
        errorCallBack(r.message, read);
      },
      onException: (String e) {
        UNavigator.back();
        UToast.error(message: e);
      },
    ),
  );

  void import() => UFile.showFilePicker(
    allowedExtensions: const <String>["xlsx"],
    action: (List<UFileData> i) {
      if (i.length != 1 || i.first.bytes == null || !(i.first.extension ?? "").toLowerCase().contains("xlsx")) return;
      ULoading.show();
      UServices.terminal.import(
        p: UTerminalImportParams(file: i.first.bytes!.toBase64()),
        onOk: (UResponse<UTerminalImportResponse> response) {
          ULoading.dismiss();
          read();
          if (response.result != null) _showImportResult(response.result!);
        },
        onError: (UEmptyResponse response) {
          ULoading.dismiss();
          UToast.error(message: response.message);
        },
        onException: (String response) {
          ULoading.dismiss();
          UToast.error(message: response);
        },
      );
    },
  );

  void _showImportResult(UTerminalImportResponse r) => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.bulkImportTerminals),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UTextBodyLarge("${U.s.total}: ${r.totalRows}"),
              UTextBodyLarge("${U.s.imported}: ${r.imported}", color: UAdminTheme.green),
              UTextBodyLarge("${U.s.skipped}: ${r.skipped}", color: r.skipped > 0 ? UAdminTheme.red : null),
              if (r.skippedSerials.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                UTextTitleSmall(U.s.skippedRows),
                const SizedBox(height: 4),
                ...r.skippedSerials.map((String x) => SelectableText("• $x")),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (r.skippedSerials.isNotEmpty)
          UButton(
            type: UButtonType.text,
            title: U.s.copy,
            onTap: () => UClipboard.set(r.skippedSerials.join("\n"), snackBar: true),
          ),
        UButton(type: UButtonType.text, title: U.s.close, onTap: UNavigator.back),
      ],
    ),
  );

  Future<List<UTerminalBrokerResponse>> readBroker(String query) async {
    final List<UTerminalBrokerResponse> result = <UTerminalBrokerResponse>[];
    await UServices.terminal.readBroker(
      p: UTerminalBrokerReadParams(
        pageSize: 100,
        selectorArgs: const UTerminalBrokerSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrokerResponse>> r) => result.addAll(
        (r.result ?? <UTerminalBrokerResponse>[]).where((UTerminalBrokerResponse x) => _matches(query, x.title, x.code)),
      ),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }

  Future<List<UTerminalBrandResponse>> readBrand(String query) async {
    final List<UTerminalBrandResponse> result = <UTerminalBrandResponse>[];
    await UServices.terminal.readBrand(
      p: UTerminalBrandReadParams(
        pageSize: 100,
        selectorArgs: const UTerminalBrandSelectorArgs(),
      ),
      onOk: (UResponse<List<UTerminalBrandResponse>> r) => result.addAll(
        (r.result ?? <UTerminalBrandResponse>[]).where((UTerminalBrandResponse x) => _matches(query, x.title, x.code)),
      ),
      onError: (UEmptyResponse e) {},
      onException: (String e) {},
    );
    return result;
  }

  bool _matches(String query, String title, String code) {
    final String q = query.trim().toLowerCase();
    return q.isEmpty || title.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }

  @override
  void dispose() {
    serialFilter.dispose();
    merchantIdFilter.dispose();
    creatorIdFilter.dispose();
    fromCreatedController.dispose();
    toCreatedController.dispose();
    super.dispose();
  }
}
