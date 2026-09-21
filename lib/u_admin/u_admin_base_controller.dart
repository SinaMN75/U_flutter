part of "u_admin.dart";

abstract class UBaseController {
  final URxState state = URxState();
  URxState state2 = URxState();
  final GlobalKey<FormState> formKey = GlobalKey();

  /// Bag for any extra text controllers a subclass needs; disposed with the controller.
  final UAdminFields fields = UAdminFields();

  int totalCount = 0;
  URxInt pageNumber = 1.obs;
  URxInt totalPages = 1.obs;
  int pageSize = 20;
  URx<TagOrderBy> tagOrderBy = TagOrderBy.createdAt.obs;

  DateTime? fromCreatedAt;
  DateTime? toCreatedAt;
  DateTime? startDate;
  DateTime? endDate;

  bool orderByCreatedAt = false;
  bool orderByCreatedAtDesc = false;

  final TextEditingController controllerStartDate = TextEditingController();
  final TextEditingController controllerEndDate = TextEditingController();

  void setTotalPages(int totalCount) => totalPages((totalCount / pageSize).ceil().clamp(1, 1 << 30));

  void firstPage() => pageNumber(1);

  void setListState({required bool isEmpty}) => isEmpty ? state.emptying() : state.loaded();

  void setError([String? message]) {
    state.error();
    if (message != null) UToast.error(message: message);
  }

  void reloadFirstPage(void Function() read) {
    firstPage();
    read();
  }

  void okCallback(String? message, void Function() reload) {
    UToast.snackBar(message: message ?? U.s.submitted);
    reload();
  }

  void errorCallBack(String? message, void Function() reload) {
    UToast.error(message: message ?? U.s.errorSubmittingForm);
    reload();
  }

  /// Releases everything this controller owns. The page that created the
  /// controller calls this from its own `State.dispose()`; a subclass that adds
  /// its own controllers overrides this and ends with `super.dispose()`.
  ///
  /// Both the text controllers and the [URx] fields are [ChangeNotifier]s, so
  /// without this every page visit leaves its listeners behind.
  @mustCallSuper
  void dispose() {
    controllerStartDate.dispose();
    controllerEndDate.dispose();
    state.dispose();
    state2.dispose();
    pageNumber.dispose();
    totalPages.dispose();
    tagOrderBy.dispose();
    fields.dispose();
  }
}
