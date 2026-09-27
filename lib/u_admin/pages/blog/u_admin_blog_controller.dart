part of "../../u_admin.dart";

class UAdminBlogController extends UBaseController {
  List<UBlogResponse> list = <UBlogResponse>[];
  final TextEditingController titleFilterController = TextEditingController();

  UBlogResponse? editing;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController slugController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  List<UCategoryResponse> categories = <UCategoryResponse>[];
  List<UCategoryResponse> selectedCategories = <UCategoryResponse>[];
  List<UFileData> files = <UFileData>[];

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.blog.read(
      p: UBlogReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        title: titleFilterController.valueOrNull(),
        selectorArgs: const UBlogSelectorArgs(media: UMediaSelectorArgs(), category: UCategorySelectorArgs(), commentsCount: true),
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
    titleFilterController.clear();
    reloadFirstPage(read);
  }

  Future<void> loadForm(UBlogResponse? b) async {
    editing = b;
    titleController.text = b?.title ?? "";
    subtitleController.text = b?.subtitle ?? "";
    slugController.text = b?.slug ?? "";
    contentController.text = b?.content ?? "";
    selectedCategories = <UCategoryResponse>[...?b?.categories];
    files = <UFileData>[];
    categories = (await UServices.category.read(p: UCategoryReadParams(pageSize: 200))).$1?.result ?? <UCategoryResponse>[];
  }

  bool isSelected(UCategoryResponse cat) => selectedCategories.any((UCategoryResponse x) => x.id == cat.id);

  void toggleCategory(UCategoryResponse cat, bool on) => on ? selectedCategories.add(cat) : selectedCategories.removeWhere((UCategoryResponse x) => x.id == cat.id);

  Future<bool> save() async {
    final UBlogResponse? b = editing;
    final List<String> categoryIds = selectedCategories.map((UCategoryResponse cat) => cat.id).toList();
    final dynamic ok = await submit(
      b == null
          ? UServices.blog.create(
              p: UBlogCreateParams(
                tags: <int>[TagBlog.draft.number],
                title: titleController.text,
                subtitle: subtitleController.text.nullIfEmpty(),
                slug: slugController.text.nullIfEmpty(),
                content: contentController.text.nullIfEmpty(),
                categories: categoryIds,
              ),
            )
          : UServices.blog.update(
              p: UBlogUpdateParams(
                id: b.id,
                title: titleController.text,
                subtitle: subtitleController.text.nullIfEmpty(),
                slug: slugController.text.nullIfEmpty(),
                content: contentController.text.nullIfEmpty(),
                categories: categoryIds,
              ),
            ),
      null,
    );
    if (ok == null) return false;
    final String? id = b?.id ?? ok.result as String?;
    if (id != null) {
      for (final UFileData file in files) {
        await UServices.media.create(
          p: UMediaCreateParams(file: file, blogId: id, tag1: TagMedia.image.number),
          onOk: (_) {},
          onError: (_) {},
          onException: (_) {},
        );
      }
    }
    unawaited(read());
    return true;
  }

  void setPublished(UBlogResponse i, bool on) => submit(
    UServices.blog.update(
      p: UBlogUpdateParams(
        id: i.id,
        addTags: <int>[if (on) TagBlog.published.number else TagBlog.draft.number],
        removeTags: <int>[if (on) TagBlog.draft.number else TagBlog.published.number],
      ),
    ),
    read,
  );

  void delete(UBlogResponse i) => confirmAction(() => UServices.blog.delete(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleFilterController.dispose();
    titleController.dispose();
    subtitleController.dispose();
    slugController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
