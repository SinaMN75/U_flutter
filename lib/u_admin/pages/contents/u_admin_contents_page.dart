import "package:u/utilities.dart";

class UAdminContentsPage extends StatefulWidget {
  const UAdminContentsPage({super.key});

  @override
  State<UAdminContentsPage> createState() => _ContentsPageState();
}

class _ContentsPageState extends State<UAdminContentsPage> {
  final UAdminContentsController c = UAdminContentsController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  TagContent? _tagOf(UContentResponse i) => TagContent.values.firstWhereOrNull((TagContent t) => i.tags.contains(t.number));

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.contents,
    onFilter: _showFilterDialog,
    onCreate: _showEditDialog,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UContentResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.contents),
      desktopBreakpoint: 720,
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.image),
        UAdminTable.headerCell(U.s.contentType),
        UAdminTable.headerCell(U.s.title),
        UAdminTable.headerCell(U.s.description, flex: 2),
        UAdminTable.headerCell(U.s.createdAt),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
  );

  Widget _thumb(String? base64, {double size = 48}) => SizedBox(
    width: size,
    height: size,
    child: base64.isNotNullOrEmpty() ? UImage("", fileData: FileData(bytes: _decodeBase64(base64!)), borderRadius: 8) : const Icon(Icons.image_outlined),
  );

  Widget _itemMobile(UContentResponse i, int index) => UAdminTable.mobileCard(
    leading: _thumb(i.jsonData.imageBase64 ?? i.jsonData.iconBase64, size: 44),
    title: i.jsonData.title ?? "---",
    badge: UAdminTable.statusChip(label: _tagOf(i)?.localizedTitle ?? "---", color: Theme.of(context).colorScheme.primary),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.description, i.jsonData.description ?? i.jsonData.detail1 ?? "---"),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _itemDesktop(UContentResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      _thumb(i.jsonData.imageBase64 ?? i.jsonData.iconBase64).expanded(),
      UAdminTable.cell(_tagOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(i.jsonData.title ?? "---"),
      UTextBodyMedium(i.jsonData.description ?? i.jsonData.detail1 ?? "---", textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, expanded: 2),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _menu(UContentResponse i) => UAdminOps.menu<UContentResponse>(
    item: i,
    handlers: UAdminActionHandlers<UContentResponse>(
      onEdit: (UContentResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UContentResponse> ctx) => <UAdminAction>[ctx.edit(), ctx.delete()],
  );

  void _showFilterDialog() => UNavigator.dialog(
    Builder(
      builder: (BuildContext context) => AlertDialog(
        title: Text(U.s.filterItem(U.s.contents)),
        content: SizedBox(
          width: context.dialogWidth(),
          child: Form(
            key: c.filterFormKey,
            child: SingleChildScrollView(
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Obx(
                    () => UDropDownField<TagContent?>(
                      initialValue: c.tagFilter.value,
                      labelText: U.s.contentType,
                      items: <DropdownMenuItem<TagContent?>>[
                        DropdownMenuItem<TagContent?>(child: Text(U.s.all)),
                        ...TagContent.values.map(
                          (TagContent t) => DropdownMenuItem<TagContent?>(value: t, child: Text(t.localizedTitle)),
                        ),
                      ],
                      onChanged: (TagContent? v) => c.tagFilter.value = v,
                    ),
                  ).pSymmetric(vertical: 6),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    submitTitle: U.s.filter,
                    cancelTitle: U.s.clearFilters,
                    onSubmit: () {
                      c.applyFilters();
                      UNavigator.back();
                    },
                    onCancel: () {
                      c.clearFilters();
                      UNavigator.back();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _showEditDialog({UContentResponse? p}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController title = TextEditingController(text: p?.jsonData.title);
    final TextEditingController subTitle = TextEditingController(text: p?.jsonData.subTitle);
    final TextEditingController description = TextEditingController(text: p?.jsonData.description);
    final TextEditingController detail1 = TextEditingController(text: p?.jsonData.detail1);
    final TextEditingController detail2 = TextEditingController(text: p?.jsonData.detail2);
    final TextEditingController buttonText = TextEditingController(text: p?.jsonData.buttonText);
    final TextEditingController buttonLink = TextEditingController(text: p?.jsonData.buttonLink);
    final TextEditingController link = TextEditingController(text: p?.jsonData.link);
    final TextEditingController order = TextEditingController(text: p?.jsonData.order?.toString());
    final TextEditingController instagram = TextEditingController(text: p?.jsonData.instagram);
    final TextEditingController telegram = TextEditingController(text: p?.jsonData.telegram);
    final TextEditingController whatsapp = TextEditingController(text: p?.jsonData.whatsapp);
    final TextEditingController phone = TextEditingController(text: p?.jsonData.phone);
    final Rx<TagContent> tag = ((p == null ? null : _tagOf(p)) ?? TagContent.aboutUs).obs;
    final List<_ItemForm> items = <_ItemForm>[...?p?.jsonData.items.map(_ItemForm.fromModel)];
    final List<_LinkForm> links = <_LinkForm>[...?p?.jsonData.links.map(_LinkForm.fromModel)];
    String? imageBase64 = p?.jsonData.imageBase64;
    String? iconBase64 = p?.jsonData.iconBase64;

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.content) : U.s.editItem(U.s.content)),
          content: SizedBox(
            width: context.dialogWidth(max: 520),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    UDropDownField<TagContent>(
                      initialValue: tag.value,
                      labelText: U.s.contentType,
                      items: TagContent.values.map((TagContent t) => DropdownMenuItem<TagContent>(value: t, child: Text(t.localizedTitle))).toList(),
                      onChanged: (TagContent? v) {
                        if (v != null) tag.value = v;
                      },
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: title, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: subTitle, labelText: U.s.subtitle, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: description, labelText: U.s.description, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: detail1, labelText: U.s.detail1, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: detail2, labelText: U.s.detail2, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: order, labelText: U.s.order, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
                    const SizedBox(height: 8),
                    URow(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Base64ImageField(label: U.s.image, initial: imageBase64, onChanged: (String? v) => imageBase64 = v).expanded(),
                        _Base64ImageField(label: U.s.icon, initial: iconBase64, onChanged: (String? v) => iconBase64 = v).expanded(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    UTextField(controller: buttonText, labelText: U.s.buttonText, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: buttonLink, labelText: U.s.buttonLink, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: link, labelText: U.s.link, margin: const EdgeInsets.symmetric(vertical: 6)),
                    const SizedBox(height: 8),
                    UTextBodyLarge(U.s.socialMedia, margin: const EdgeInsets.only(bottom: 4)),
                    UTextField(controller: instagram, labelText: U.s.instagram, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: telegram, labelText: U.s.telegram, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: whatsapp, labelText: U.s.whatsApp, margin: const EdgeInsets.symmetric(vertical: 6)),
                    UTextField(controller: phone, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
                    const SizedBox(height: 12),
                    URow(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        UTextBodyLarge(U.s.items),
                        TextButton.icon(
                          onPressed: () => setDialogState(() => items.add(_ItemForm())),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(U.s.addItem("")),
                        ),
                      ],
                    ),
                    ...items.mapIndexed(
                      (int index, _ItemForm e) => _itemCard(index, e, () => setDialogState(() => items.removeAt(index))),
                    ),
                    const SizedBox(height: 12),
                    URow(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        UTextBodyLarge(U.s.links),
                        TextButton.icon(
                          onPressed: () => setDialogState(() => links.add(_LinkForm())),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(U.s.addItem(U.s.link)),
                        ),
                      ],
                    ),
                    ...links.mapIndexed(
                      (int index, _LinkForm e) => _linkCard(index, e, () => setDialogState(() => links.removeAt(index))),
                    ),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final List<UContentItem> itemModels = items.map((_ItemForm e) => e.toModel()).toList();
                          final List<UContentLink> linkModels = links.map((_LinkForm e) => e.toModel()).toList();
                          if (p == null) {
                            c.create(
                              p: UContentCreateParams(
                                tags: <int>[tag.value.number],
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
                            );
                          } else {
                            c.update(
                              p: UContentUpdateParams(
                                id: p.id,
                                tags: <int>[tag.value.number],
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
                            );
                          }
                          UNavigator.back();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemCard(int index, _ItemForm e, VoidCallback onRemove) => UContainer(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
    radius: 8,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            UTextBodyMedium("${U.s.item} ${index + 1}"),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error),
              onPressed: onRemove,
            ),
          ],
        ),
        UTextField(controller: e.title, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.subTitle, labelText: U.s.subtitle, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.description, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.link, labelText: U.s.link, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.order, labelText: U.s.order, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 4)),
        const SizedBox(height: 8),
        URow(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Base64ImageField(label: U.s.icon, initial: e.iconBase64, onChanged: (String? v) => e.iconBase64 = v).expanded(),
            _Base64ImageField(label: U.s.image, initial: e.imageBase64, onChanged: (String? v) => e.imageBase64 = v).expanded(),
          ],
        ),
      ],
    ),
  );

  Widget _linkCard(int index, _LinkForm e, VoidCallback onRemove) => UContainer(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 6),
    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
    radius: 8,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            UTextBodyMedium("${U.s.link} ${index + 1}"),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.error),
              onPressed: onRemove,
            ),
          ],
        ),
        UTextField(controller: e.title, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.url, labelText: U.s.url, margin: const EdgeInsets.symmetric(vertical: 4)),
        const SizedBox(height: 8),
        _Base64ImageField(label: U.s.icon, initial: e.iconBase64, onChanged: (String? v) => e.iconBase64 = v),
      ],
    ),
  );
}

// Decodes a base64 string, tolerating an optional data-uri prefix.
Uint8List _decodeBase64(String base64) => (base64.contains(",") ? base64.split(",").last : base64).toBytesFromBase64();

class _Base64ImageField extends StatefulWidget {
  const _Base64ImageField({required this.label, required this.initial, required this.onChanged});

  final String label;
  final String? initial;
  final ValueChanged<String?> onChanged;

  @override
  State<_Base64ImageField> createState() => _Base64ImageFieldState();
}

class _Base64ImageFieldState extends State<_Base64ImageField> {
  String? _value;

  @override
  void initState() {
    _value = widget.initial;
    super.initState();
  }

  Future<void> _pick() => UFile.showFilePicker(
    allowedExtensions: const <String>["jpg", "jpeg", "png", "gif", "webp", "svg"],
    action: (List<FileData> files) {
      if (files.isEmpty || files.first.bytes == null) return;
      final String encoded = files.first.bytes!.toBase64();
      setState(() => _value = encoded);
      widget.onChanged(encoded);
    },
  );

  void _clear() {
    setState(() => _value = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextBodySmall(widget.label, color: scheme.onSurfaceVariant, margin: const EdgeInsets.only(bottom: 4)),
        Stack(
          children: <Widget>[
            UContainer(
              onTap: _pick,
              height: 96,
              width: double.infinity,
              radius: 12,
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: _value.isNotNullOrEmpty()
                  ? UImage("", fileData: FileData(bytes: _decodeBase64(_value!)), borderRadius: 12)
                  : Icon(Icons.add_photo_alternate_outlined, size: 32, color: scheme.onSurfaceVariant),
            ),
            if (_value.isNotNullOrEmpty())
              Positioned(
                top: 4,
                right: 4,
                child: UContainer(
                  onTap: _clear,
                  color: scheme.error,
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, size: 14, color: UAdminTheme.white),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ItemForm {
  _ItemForm({String? title, String? subTitle, String? description, String? link, int? order, this.iconBase64, this.imageBase64})
    : title = TextEditingController(text: title),
      subTitle = TextEditingController(text: subTitle),
      description = TextEditingController(text: description),
      link = TextEditingController(text: link),
      order = TextEditingController(text: order?.toString());

  factory _ItemForm.fromModel(UContentItem m) => _ItemForm(
    title: m.title,
    subTitle: m.subTitle,
    description: m.description,
    link: m.link,
    order: m.order,
    iconBase64: m.iconBase64,
    imageBase64: m.imageBase64,
  );

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

class _LinkForm {
  _LinkForm({String? title, String? url, this.iconBase64}) : title = TextEditingController(text: title), url = TextEditingController(text: url);

  factory _LinkForm.fromModel(UContentLink m) => _LinkForm(title: m.title, url: m.url, iconBase64: m.iconBase64);

  final TextEditingController title;
  final TextEditingController url;
  String? iconBase64;

  UContentLink toModel() => UContentLink(
    title: title.text.nullIfEmpty(),
    url: url.text.nullIfEmpty(),
    iconBase64: iconBase64,
  );
}
