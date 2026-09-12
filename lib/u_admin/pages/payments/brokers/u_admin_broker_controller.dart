part of "../../../u_admin.dart";

class UAdminBrokerController extends UBaseController {
  List<UBrokerResponse> list = <UBrokerResponse>[];

  final TextEditingController titleFilter = TextEditingController();
  final TextEditingController codeFilter = TextEditingController();

  Future<void> init() async => read();

  Future<void> read() async {
    state.loading();
    await UServices.broker.readBroker(
      p: UBrokerReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        code: codeFilter.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
        selectorArgs: const BrokerSelectorArgs(brands: TerminalBrandSelectorArgs()),
      ),
      onOk: (UResponse<List<UBrokerResponse>> r) {
        list = r.result ?? <UBrokerResponse>[];
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
    titleFilter.clear();
    codeFilter.clear();
    reloadFirstPage(read);
  }

  Future<List<UAgreementTemplateResponse>> fetchTemplates() async {
    final Completer<List<UAgreementTemplateResponse>> completer = Completer<List<UAgreementTemplateResponse>>();
    await UServices.broker.readAgreementTemplate(
      p: UAgreementTemplateReadParams(pageSize: 200),
      onOk: (UResponse<List<UAgreementTemplateResponse>> r) => completer.complete(r.result ?? <UAgreementTemplateResponse>[]),
      onError: (_) => completer.complete(<UAgreementTemplateResponse>[]),
      onException: (_) => completer.complete(<UAgreementTemplateResponse>[]),
    );
    return completer.future;
  }

  void create({required UBrokerCreateParams p}) {
    ULoading.show();
    UServices.broker.createBroker(
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

  void update({required UBrokerUpdateParams p}) {
    ULoading.show();
    UServices.broker.updateBroker(
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

  void delete(UBrokerResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.broker.deleteBroker(
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
}

class UAdminTerminalBrandController extends UBaseController {
  List<UTerminalBrandResponse> list = <UTerminalBrandResponse>[];

  final TextEditingController titleFilter = TextEditingController();
  final TextEditingController codeFilter = TextEditingController();
  Rxn<UBrokerResponse> brokerFilter = Rxn<UBrokerResponse>();
  List<UBrokerResponse> brokers = <UBrokerResponse>[];

  Future<void> init() async {
    brokers = await fetchBrokers();
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.broker.readBrand(
      p: UTerminalBrandReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        code: codeFilter.text.nullIfEmpty(),
        brokerId: brokerFilter.value?.id,
        orderBy: tagOrderBy.value.number,
        selectorArgs: const TerminalBrandSelectorArgs(broker: true),
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
    titleFilter.clear();
    codeFilter.clear();
    brokerFilter(null);
    reloadFirstPage(read);
  }

  Future<List<UBrokerResponse>> fetchBrokers() async {
    final Completer<List<UBrokerResponse>> completer = Completer<List<UBrokerResponse>>();
    await UServices.broker.readBroker(
      p: UBrokerReadParams(pageSize: 200),
      onOk: (UResponse<List<UBrokerResponse>> r) => completer.complete(r.result ?? <UBrokerResponse>[]),
      onError: (_) => completer.complete(<UBrokerResponse>[]),
      onException: (_) => completer.complete(<UBrokerResponse>[]),
    );
    return completer.future;
  }

  Future<List<UAgreementTemplateResponse>> fetchTemplates() async {
    final Completer<List<UAgreementTemplateResponse>> completer = Completer<List<UAgreementTemplateResponse>>();
    await UServices.broker.readAgreementTemplate(
      p: UAgreementTemplateReadParams(pageSize: 200),
      onOk: (UResponse<List<UAgreementTemplateResponse>> r) => completer.complete(r.result ?? <UAgreementTemplateResponse>[]),
      onError: (_) => completer.complete(<UAgreementTemplateResponse>[]),
      onException: (_) => completer.complete(<UAgreementTemplateResponse>[]),
    );
    return completer.future;
  }

  void create({required UTerminalBrandCreateParams p}) {
    ULoading.show();
    UServices.broker.createBrand(
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

  void update({required UTerminalBrandUpdateParams p}) {
    ULoading.show();
    UServices.broker.updateBrand(
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

  void delete(UTerminalBrandResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.broker.deleteBrand(
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
}

class UAdminAgreementTemplateController extends UBaseController {
  List<UAgreementTemplateResponse> list = <UAgreementTemplateResponse>[];

  final TextEditingController titleFilter = TextEditingController();

  Future<void> init() async => read();

  Future<void> read() async {
    state.loading();
    await UServices.broker.readAgreementTemplate(
      p: UAgreementTemplateReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.text.nullIfEmpty(),
        orderBy: tagOrderBy.value.number,
      ),
      onOk: (UResponse<List<UAgreementTemplateResponse>> r) {
        list = r.result ?? <UAgreementTemplateResponse>[];
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
    titleFilter.clear();
    reloadFirstPage(read);
  }

  void create({required UAgreementTemplateCreateParams p}) {
    ULoading.show();
    UServices.broker.createAgreementTemplate(
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

  void update({required UAgreementTemplateUpdateParams p}) {
    ULoading.show();
    UServices.broker.updateAgreementTemplate(
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

  void delete(UAgreementTemplateResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.broker.deleteAgreementTemplate(
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
}
