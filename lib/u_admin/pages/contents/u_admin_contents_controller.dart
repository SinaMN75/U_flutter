part of "../../u_admin.dart";

class UAdminContentsController extends UBaseController {
  List<UContentResponse> list = <UContentResponse>[];
  TagContent? tagFilter;

  UContentResponse? editing;
  late final TextEditingController title = fields.text();
  late final TextEditingController subTitle = fields.text();
  late final TextEditingController description = fields.text();
  late final TextEditingController detail1 = fields.text();
  late final TextEditingController detail2 = fields.text();
  late final TextEditingController buttonText = fields.text();
  late final TextEditingController buttonLink = fields.text();
  late final TextEditingController link = fields.text();
  late final TextEditingController order = fields.text();
  late final TextEditingController instagram = fields.text();
  late final TextEditingController telegram = fields.text();
  late final TextEditingController whatsapp = fields.text();
  late final TextEditingController phone = fields.text();
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
        setListState(isEmpty: list.isEmpty);
      },
      onError: (UEmptyResponse e) => setError(e.message),
      onException: (String e) => setError(),
    );
  }

  void applyFilters() => reloadFirstPage(read);

  void clearFilters() {
    tagFilter = null;
    reloadFirstPage(read);
  }

  void loadForm(UContentResponse? p) {
    final UContentJson? d = p?.jsonData;
    editing = p;
    title.text = d?.title ?? "";
    subTitle.text = d?.subTitle ?? "";
    description.text = d?.description ?? "";
    detail1.text = d?.detail1 ?? "";
    detail2.text = d?.detail2 ?? "";
    buttonText.text = d?.buttonText ?? "";
    buttonLink.text = d?.buttonLink ?? "";
    link.text = d?.link ?? "";
    order.text = d?.order?.toString() ?? "";
    instagram.text = d?.instagram ?? "";
    telegram.text = d?.telegram ?? "";
    whatsapp.text = d?.whatsapp ?? "";
    phone.text = d?.phone ?? "";
    tag = (p == null ? null : tagOf(p)) ?? TagContent.aboutUs;
    imageBase64 = d?.imageBase64;
    iconBase64 = d?.iconBase64;
    items = <UAdminContentItemForm>[...?d?.items.map((UContentItem m) => UAdminContentItemForm(fields, m))];
    links = <UAdminContentLinkForm>[...?d?.links.map((UContentLink m) => UAdminContentLinkForm(fields, m))];
  }

  void addItem() => items.add(UAdminContentItemForm(fields));

  void addLink() => links.add(UAdminContentLinkForm(fields));

  Future<bool> save() async {
    final UContentResponse? p = editing;
    final List<UContentItem> itemModels = items.map((UAdminContentItemForm e) => e.toModel()).toList();
    final List<UContentLink> linkModels = links.map((UAdminContentLinkForm e) => e.toModel()).toList();
    final dynamic ok = await submit(
      p == null
          ? UServices.content.create(
              p: UContentCreateParams(
                tags: <int>[tag.number],
                title: title.text.nullIfEmpty(),
                subTitle: subTitle.text.nullIfEmpty(),
                description: description.text.nullIfEmpty(),
                detail1: detail1.text.nullIfEmpty(),
                detail2: detail2.text.nullIfEmpty(),
                imageBase64: imageBase64,
                iconBase64: iconBase64,
                buttonText: buttonText.text.nullIfEmpty(),
                buttonLink: buttonLink.text.nullIfEmpty(),
                link: link.text.nullIfEmpty(),
                order: int.tryParse(order.text),
                instagram: instagram.text.nullIfEmpty(),
                telegram: telegram.text.nullIfEmpty(),
                whatsapp: whatsapp.text.nullIfEmpty(),
                phone: phone.text.nullIfEmpty(),
                items: itemModels,
                links: linkModels,
              ),
            )
          : UServices.content.update(
              p: UContentUpdateParams(
                id: p.id,
                tags: <int>[tag.number],
                title: title.text.nullIfEmpty(),
                subTitle: subTitle.text.nullIfEmpty(),
                description: description.text.nullIfEmpty(),
                detail1: detail1.text.nullIfEmpty(),
                detail2: detail2.text.nullIfEmpty(),
                imageBase64: imageBase64,
                iconBase64: iconBase64,
                buttonText: buttonText.text.nullIfEmpty(),
                buttonLink: buttonLink.text.nullIfEmpty(),
                link: link.text.nullIfEmpty(),
                order: int.tryParse(order.text),
                instagram: instagram.text.nullIfEmpty(),
                telegram: telegram.text.nullIfEmpty(),
                whatsapp: whatsapp.text.nullIfEmpty(),
                phone: phone.text.nullIfEmpty(),
                items: itemModels,
                links: linkModels,
              ),
            ),
      read,
    );
    return ok != null;
  }

  void delete(UContentResponse i) => confirmAction(() => UServices.content.delete(p: UIdParams(id: i.id)), read);
}

/// One editable row of a content's `items`; its text controllers live in the page controller's field bag.
class UAdminContentItemForm {
  UAdminContentItemForm(UAdminFields f, [UContentItem? m])
    : title = f.text(m?.title),
      subTitle = f.text(m?.subTitle),
      description = f.text(m?.description),
      link = f.text(m?.link),
      order = f.text(m?.order?.toString()),
      iconBase64 = m?.iconBase64,
      imageBase64 = m?.imageBase64;

  final TextEditingController title;
  final TextEditingController subTitle;
  final TextEditingController description;
  final TextEditingController link;
  final TextEditingController order;
  String? iconBase64;
  String? imageBase64;

  UContentItem toModel() => UContentItem(
    title: title.text.nullIfEmpty(),
    subTitle: subTitle.text.nullIfEmpty(),
    description: description.text.nullIfEmpty(),
    link: link.text.nullIfEmpty(),
    order: int.tryParse(order.text),
    iconBase64: iconBase64,
    imageBase64: imageBase64,
  );
}

/// One editable row of a content's `links`.
class UAdminContentLinkForm {
  UAdminContentLinkForm(UAdminFields f, [UContentLink? m]) : title = f.text(m?.title), url = f.text(m?.url), iconBase64 = m?.iconBase64;

  final TextEditingController title;
  final TextEditingController url;
  String? iconBase64;

  UContentLink toModel() => UContentLink(title: title.text.nullIfEmpty(), url: url.text.nullIfEmpty(), iconBase64: iconBase64);
}
