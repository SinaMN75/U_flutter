part of "u_admin.dart";

abstract class UBaseController {
  final URxState state = URxState();
  final URxState state2 = URxState();
  final GlobalKey<FormState> formKey = GlobalKey();

  int totalCount = 0;
  final URxInt pageNumber = 1.obs;
  final URxInt totalPages = 1.obs;
  int pageSize = 20;
  final URx<TagOrderBy> tagOrderBy = TagOrderBy.createdAt.obs;

  /// The list filter's date range, shown in [startDateController] / [endDateController].
  DateTime? startDate;
  DateTime? endDate;
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  void setTotalPages(int count) {
    totalCount = count;
    totalPages((count / pageSize).ceil().clamp(1, 1 << 30));
  }

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

  void clearDates() {
    startDate = null;
    endDate = null;
    startDateController.clear();
    endDateController.clear();
  }

  /// Awaits a service call's `(ok, error, exception)` result: on success toasts and runs [reload], otherwise toasts the error.
  /// Returns the ok response (its `result` is the new id on create), or null on failure.
  Future<dynamic> submit(Future<(dynamic, dynamic, String?)> call, VoidCallback? reload) async {
    final (dynamic ok, dynamic error, String? exception) = await call;
    if (ok == null) {
      UToast.error(message: (error?.message as String?).nullIfEmpty() ?? exception.nullIfEmpty() ?? U.s.errorSubmittingForm);
      return null;
    }
    UToast.snackBar(message: (ok.message as String?).nullIfEmpty() ?? U.s.submitted);
    reload?.call();
    return ok;
  }

  /// Users matching [query], for user pickers.
  Future<List<UUserResponse>> searchUsers(String query) async =>
      (await UServices.user.read(p: UUserReadParams(query: query.nullIfEmpty(), pageSize: 20))).$1?.result ?? <UUserResponse>[];

  /// The users with [ids]; the ones that fail to load are skipped.
  Future<List<UUserResponse>> readUsersById(List<String> ids) async => <UUserResponse>[
    for (final String id in ids) ?(await UServices.user.readById(p: UIdParams(id: id))).$1?.result,
  ];

  /// The number typed in [c] (Persian digits and separators allowed); null when empty.
  double? numOf(TextEditingController c) => c.text.trim().isEmpty ? null : c.numDouble();

  int? intOf(TextEditingController c) => c.text.trim().isEmpty ? null : c.numInt();

  /// "a, b، c" → ["a", "b", "c"] (Latin and Persian commas).
  List<String> splitList(String text) => text.split(RegExp("[،,]")).map((String i) => i.trim()).where((String i) => i.isNotEmpty).toList();

  /// Asks for confirmation (the dialog closes itself), then runs [call] through [submit]. Defaults to a delete prompt.
  void confirmAction(Future<(dynamic, dynamic, String?)> Function() call, void Function() reload, {String? title, String? message}) => UNavigator.confirm(
    title: title ?? U.s.delete,
    message: message ?? U.s.areYouSureYouWantToDelete,
    destructive: title == null,
    onConfirm: () => submit(call(), reload),
  );

  /// Releases everything this controller owns. The page that created the controller calls this from its own
  /// `State.dispose()`; a subclass that adds its own notifiers overrides this and ends with `super.dispose()`.
  @mustCallSuper
  void dispose() {
    state.dispose();
    state2.dispose();
    pageNumber.dispose();
    totalPages.dispose();
    tagOrderBy.dispose();
    startDateController.dispose();
    endDateController.dispose();
  }
}
