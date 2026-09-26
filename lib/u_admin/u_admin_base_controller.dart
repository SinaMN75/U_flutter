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

  /// Awaits a service call's `(ok, error, exception)` result: on success toasts and runs [reload], otherwise toasts the error.
  /// Returns the ok response (its `result` is the new id on create), or null on failure.
  Future<dynamic> submit(Future<(dynamic, dynamic, String?)> call, void Function() reload) async {
    final (dynamic ok, dynamic error, String? exception) = await call;
    if (ok == null) {
      UToast.error(message: (error?.message as String?).nullIfEmpty() ?? exception.nullIfEmpty() ?? U.s.errorSubmittingForm);
      return null;
    }
    okCallback((ok.message as String?).nullIfEmpty(), reload);
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
