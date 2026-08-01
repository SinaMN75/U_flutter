part of "../../u_admin.dart";

class UAdminBlogController extends UBaseController {
  List<UBlogResponse> list = <UBlogResponse>[];
  final GlobalKey<FormState> filterFormKey = GlobalKey<FormState>();

  final TextEditingController titleFilter = TextEditingController();
  bool? onlyPublishedFilter;

  Future<void> init() async {
    await read();
  }

  Future<void> read() async {
    state.loading();
    await UServices.blog.read(
      p: UBlogReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilter.valueOrNull(),
        selectorArgs: const BlogSelectorArgs(media: MediaSelectorArgs(), category: CategorySelectorArgs(), commentsCount: true),
      ),
      onOk: (UResponse<List<UBlogResponse>> r) {
        list = r.result ?? <UBlogResponse>[];
        setTotalPages(r.totalCount);
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    titleFilter.clear();
    onlyPublishedFilter = null;
    reloadFirstPage(read);
  }

  Future<List<UCategoryResponse>> fetchCategories() async {
    final Completer<List<UCategoryResponse>> completer = Completer<List<UCategoryResponse>>();
    await UServices.category.read(
      p: UCategoryReadParams(pageSize: 200),
      onOk: (UResponse<List<UCategoryResponse>> r) => completer.complete(r.result ?? <UCategoryResponse>[]),
      onError: (_) => completer.complete(<UCategoryResponse>[]),
      onException: (_) => completer.complete(<UCategoryResponse>[]),
    );
    return completer.future;
  }

  void create({required UBlogCreateParams p, List<FileData>? files}) => UServices.blog.create(
    p: p,
    onOk: (UResponse<String> r) {
      if (files.isNotNullOrEmpty() && r.result != null) {
        _uploadMedia(blogId: r.result!, files: files!, onDone: () => okCallback(r.message, read));
      } else {
        okCallback(r.message, read);
      }
    },
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void update({required UBlogUpdateParams p, List<FileData>? files}) => UServices.blog.update(
    p: p,
    onOk: (UEmptyResponse r) {
      if (files.isNotNullOrEmpty()) {
        _uploadMedia(blogId: p.id, files: files!, onDone: () => okCallback(r.message, read));
      } else {
        okCallback(r.message, read);
      }
    },
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  Future<void> _uploadMedia({required String blogId, required List<FileData> files, required VoidCallback onDone}) async {
    for (final FileData file in files) {
      await UServices.media.create(
        p: UMediaCreateParams(file: file, blogId: blogId, tag1: TagMedia.image.number),
        onOk: (_) {},
        onError: (_) {},
        onException: (_) {},
      );
    }
    onDone();
  }

  void delete(UBlogResponse i) => UNavigator.confirm(
    title: U.s.delete,
    message: U.s.areYouSureYouWantToDelete,
    onConfirm: () => UServices.blog.delete(
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

  void publish(UBlogResponse i) => UServices.blog.publish(
    p: UIdParams(id: i.id),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );

  void unpublish(UBlogResponse i) => UServices.blog.unpublish(
    p: UIdParams(id: i.id),
    onOk: (UEmptyResponse r) => okCallback(r.message, read),
    onError: (UEmptyResponse r) => errorCallBack(r.message, read),
    onException: (String e) => errorCallBack(U.s.errorSubmittingForm, read),
  );
}
