part of "u_admin.dart";

abstract class UBaseController {
  final RxState state = RxState();
  RxState state2 = RxState();
  final GlobalKey<FormState> formKey = GlobalKey();

  int totalCount = 0;
  RxInt pageNumber = 1.obs;
  RxInt totalPages = 1.obs;
  int pageSize = 20;
  Rx<TagOrderBy> tagOrderBy = TagOrderBy.createdAt.obs;

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
}
