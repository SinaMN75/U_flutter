part of "../../../u_admin.dart";

class UAdminTerminalController extends UBaseController {
  List<UTerminalResponse> list = <UTerminalResponse>[];

  UMerchantResponse? merchant;

  final TextEditingController serialFilter = TextEditingController();
  final TextEditingController merchantIdFilter = TextEditingController();
  final TextEditingController creatorIdFilter = TextEditingController();
  final TextEditingController fromCreatedController = TextEditingController();
  final TextEditingController toCreatedController = TextEditingController();
  Rxn<TagTerminal> typeFilter = Rxn<TagTerminal>();

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
        tags: typeFilter.value == null ? null : <int>[typeFilter.value!.number],
        fromCreatedAt: fromCreatedAt,
        toCreatedAt: toCreatedAt,
        orderBy: tagOrderBy.value.number,
        selectorArgs: const TerminalSelectorArgs(merchant: MerchantSelectorArgs()),
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

  void supportPassword(UTerminalResponse i) {
    ULoading.show();
    UServices.terminal.readSupportPassword(
      p: UIdParams(id: i.id),
      onOk: (UResponse<UTerminalReadSupportPasswordResponse> r) {
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
    action: (List<FileData> i) {
      ULoading.show();
      if (i.length == 1 && i.first.extension!.toLowerCase().contains("xlsx")) {
        UServices.terminal.import(
          p: UTerminalImportParams(file: i.first.bytes!.toBase64()),
          onOk: (UResponse<UTerminalImportResponse> response) {
            ULoading.dismiss();
            UToast.snackBar(message: response.message);
          },
          onError: (UEmptyResponse response) {
            ULoading.dismiss();
            UToast.snackBar(message: response.message);
          },
          onException: (String response) {
            ULoading.dismiss();
            UToast.error(message: response);
          },
        );
      }
    },
  );
}
