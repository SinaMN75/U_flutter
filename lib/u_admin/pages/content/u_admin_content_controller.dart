part of "../../u_admin.dart";

class UAdminContentController extends UAdminBaseController {
  List<UContentResponse> list = <UContentResponse>[];
  TagContent? tagFilter;

  UContentResponse? editing;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subTitleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController detail1Controller = TextEditingController();
  final TextEditingController detail2Controller = TextEditingController();
  final TextEditingController buttonTextController = TextEditingController();
  final TextEditingController buttonLinkController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController orderController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  TagContent tag = TagContent.aboutUs;
  String? imageBase64;
  String? iconBase64;
  List<UAdminContentItemForm> items = <UAdminContentItemForm>[];
  List<UAdminContentLinkForm> links = <UAdminContentLinkForm>[];

  static TagContent? tagOf(UContentResponse i) => TagContent.values.firstWhereOrNull((TagContent t) => i.tags.contains(t.number));

  Future<void> init() => read();

  Future<void> read() async {
    state.loading();
    await UServices.content.read(
      p: UContentReadParams(
        pageNumber: pageNumber.value,
        pageSize: pageSize,
        tags: tagFilter == null ? null : <int>[tagFilter!.number],
        selectorArgs: const UContentSelectorArgs(media: UMediaSelectorArgs()),
      ),
      onOk: (UResponse<List<UContentResponse>> r) {
        list = r.result ?? <UContentResponse>[];
        setTotalPages(r.totalCount);
        list.isEmpty ? state.emptying() : state.loaded();
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() {
    pageNumber(1);
    read();
  }

  void clearFilters() {
    tagFilter = null;
    pageNumber(1);
    read();
  }

  void loadForm(UContentResponse? p) {
    final UContentJson? d = p?.jsonData;
    editing = p;
    titleController.text = d?.title ?? "";
    subTitleController.text = d?.subTitle ?? "";
    descriptionController.text = d?.description ?? "";
    detail1Controller.text = d?.detail1 ?? "";
    detail2Controller.text = d?.detail2 ?? "";
    buttonTextController.text = d?.buttonText ?? "";
    buttonLinkController.text = d?.buttonLink ?? "";
    linkController.text = d?.link ?? "";
    orderController.text = d?.order?.toString() ?? "";
    instagramController.text = d?.instagram ?? "";
    telegramController.text = d?.telegram ?? "";
    whatsappController.text = d?.whatsapp ?? "";
    phoneController.text = d?.phone ?? "";
    tag = (p == null ? null : tagOf(p)) ?? TagContent.aboutUs;
    imageBase64 = d?.imageBase64;
    iconBase64 = d?.iconBase64;
    _disposeRows();
    items = <UAdminContentItemForm>[...?d?.items.map(UAdminContentItemForm.new)];
    links = <UAdminContentLinkForm>[...?d?.links.map(UAdminContentLinkForm.new)];
  }

  void addItem() => items.add(UAdminContentItemForm());

  void removeItem(int index) => items.removeAt(index).dispose();

  void addLink() => links.add(UAdminContentLinkForm());

  void removeLink(int index) => links.removeAt(index).dispose();

  void _disposeRows() {
    for (final UAdminContentItemForm i in items) {
      i.dispose();
    }
    for (final UAdminContentLinkForm l in links) {
      l.dispose();
    }
  }

  Future<bool> save() async {
    final UContentResponse? p = editing;
    final List<UContentItem> itemModels = items.map((UAdminContentItemForm e) => e.toModel()).toList();
    final List<UContentLink> linkModels = links.map((UAdminContentLinkForm e) => e.toModel()).toList();
    return await submit(
      p == null
          ? UServices.content.create(
              p: UContentCreateParams(
                tags: <int>[tag.number],
                title: titleController.text.nullIfEmpty(),
                subTitle: subTitleController.text.nullIfEmpty(),
                description: descriptionController.text.nullIfEmpty(),
                detail1: detail1Controller.text.nullIfEmpty(),
                detail2: detail2Controller.text.nullIfEmpty(),
                imageBase64: imageBase64,
                iconBase64: iconBase64,
                buttonText: buttonTextController.text.nullIfEmpty(),
                buttonLink: buttonLinkController.text.nullIfEmpty(),
                link: linkController.text.nullIfEmpty(),
                order: int.tryParse(orderController.text),
                instagram: instagramController.text.nullIfEmpty(),
                telegram: telegramController.text.nullIfEmpty(),
                whatsapp: whatsappController.text.nullIfEmpty(),
                phone: phoneController.text.nullIfEmpty(),
                items: itemModels,
                links: linkModels,
              ),
            )
          : UServices.content.update(
              p: UContentUpdateParams(
                id: p.id,
                tags: <int>[tag.number],
                title: titleController.text.nullIfEmpty(),
                subTitle: subTitleController.text.nullIfEmpty(),
                description: descriptionController.text.nullIfEmpty(),
                detail1: detail1Controller.text.nullIfEmpty(),
                detail2: detail2Controller.text.nullIfEmpty(),
                imageBase64: imageBase64,
                iconBase64: iconBase64,
                buttonText: buttonTextController.text.nullIfEmpty(),
                buttonLink: buttonLinkController.text.nullIfEmpty(),
                link: linkController.text.nullIfEmpty(),
                order: int.tryParse(orderController.text),
                instagram: instagramController.text.nullIfEmpty(),
                telegram: telegramController.text.nullIfEmpty(),
                whatsapp: whatsappController.text.nullIfEmpty(),
                phone: phoneController.text.nullIfEmpty(),
                items: itemModels,
                links: linkModels,
              ),
            ),
      read,
    ) !=
        null;
  }

  void delete(UContentResponse i) => confirmAction(() => UServices.content.delete(p: UIdParams(id: i.id)), read);

  @override
  void dispose() {
    titleController.dispose();
    subTitleController.dispose();
    descriptionController.dispose();
    detail1Controller.dispose();
    detail2Controller.dispose();
    buttonTextController.dispose();
    buttonLinkController.dispose();
    linkController.dispose();
    orderController.dispose();
    instagramController.dispose();
    telegramController.dispose();
    whatsappController.dispose();
    phoneController.dispose();
    _disposeRows();
    super.dispose();
  }
}

/// One editable row of a content's `items`.
class UAdminContentItemForm {
  UAdminContentItemForm([UContentItem? m])
    : titleController = TextEditingController(text: m?.title),
      subTitleController = TextEditingController(text: m?.subTitle),
      descriptionController = TextEditingController(text: m?.description),
      linkController = TextEditingController(text: m?.link),
      orderController = TextEditingController(text: m?.order?.toString()),
      iconBase64 = m?.iconBase64,
      imageBase64 = m?.imageBase64;

  final TextEditingController titleController;
  final TextEditingController subTitleController;
  final TextEditingController descriptionController;
  final TextEditingController linkController;
  final TextEditingController orderController;
  String? iconBase64;
  String? imageBase64;

  UContentItem toModel() => UContentItem(
    title: titleController.text.nullIfEmpty(),
    subTitle: subTitleController.text.nullIfEmpty(),
    description: descriptionController.text.nullIfEmpty(),
    link: linkController.text.nullIfEmpty(),
    order: int.tryParse(orderController.text),
    iconBase64: iconBase64,
    imageBase64: imageBase64,
  );

  void dispose() {
    titleController.dispose();
    subTitleController.dispose();
    descriptionController.dispose();
    linkController.dispose();
    orderController.dispose();
  }
}

/// One editable row of a content's `links`.
class UAdminContentLinkForm {
  UAdminContentLinkForm([UContentLink? m]) : titleController = TextEditingController(text: m?.title), urlController = TextEditingController(text: m?.url), iconBase64 = m?.iconBase64;

  final TextEditingController titleController;
  final TextEditingController urlController;
  String? iconBase64;

  UContentLink toModel() => UContentLink(title: titleController.text.nullIfEmpty(), url: urlController.text.nullIfEmpty(), iconBase64: iconBase64);

  void dispose() {
    titleController.dispose();
    urlController.dispose();
  }
}
