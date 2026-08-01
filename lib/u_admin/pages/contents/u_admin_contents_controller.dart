part of "../../u_admin.dart";

class UAdminContentsController extends UBaseController {
  List<UContentResponse> list = <UContentResponse>[];
  final GlobalKey<FormState> filterFormKey = GlobalKey<FormState>();

  final Rxn<TagContent> tagFilter = Rxn<TagContent>();

  Future<void> init() async {
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.content.read(
      p: UContentReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        tags: tagFilter.value == null ? null : <int>[tagFilter.value!.number],
        selectorArgs: const ContentSelectorArgs(media: MediaSelectorArgs()),
      ),
      onOk: (UResponse<List<UContentResponse>> r) {
        list = r.result ?? <UContentResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    tagFilter.value = null;
    reloadFirstPage(read);
  }

  void create({required UContentCreateParams p}) => UServices.content.create(
    p: p,
    onOk: (UResponse<String> r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UContentUpdateParams p}) => UServices.content.update(
    p: p,
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void delete(UContentResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.content.delete(
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
