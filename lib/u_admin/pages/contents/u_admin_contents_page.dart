import "package:u/utilities.dart";

class UAdminContentsPage extends StatefulWidget {
  const UAdminContentsPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.content, const UAdminContentsPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.content,
    icon: Icons.content_copy,
    selectedIcon: Icons.content_copy_outlined,
    page: () => const UAdminContentsPage(),
    roles: roles,
  );

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

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.contents,
    onFilter: _filter,
    onCreate: _form,
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
    child: base64.isNotNullOrEmpty() ? UImage("", fileData: UFileData(bytes: _decodeBase64(base64!)), borderRadius: 8) : const Icon(Icons.image_outlined),
  );

  Widget _itemMobile(UContentResponse i, int index) => UAdminTable.mobileCard(
    leading: _thumb(i.jsonData.imageBase64 ?? i.jsonData.iconBase64, size: 44),
    title: i.jsonData.title ?? "---",
    badge: UAdminTable.statusChip(label: UAdminContentsController.tagOf(i)?.localizedTitle ?? "---", color: Theme.of(context).colorScheme.primary),
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
      UAdminTable.cell(UAdminContentsController.tagOf(i)?.localizedTitle ?? "---"),
      UAdminTable.cell(i.jsonData.title ?? "---"),
      UTextBodyMedium(i.jsonData.description ?? i.jsonData.detail1 ?? "---", textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, expanded: 2),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _menu(UContentResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.contents),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagContent?>(
        initialValue: c.tagFilter,
        labelText: U.s.contentType,
        items: <DropdownMenuItem<TagContent?>>[
          DropdownMenuItem<TagContent?>(child: Text(U.s.all)),
          ...TagContent.values.map((TagContent t) => DropdownMenuItem<TagContent?>(value: t, child: Text(t.localizedTitle))),
        ],
        onChanged: (TagContent? v) => c.tagFilter = v,
      ).pSymmetric(vertical: 6),
    ],
  );

  Future<void> _form([UContentResponse? p]) async {
    c.loadForm(p);
    await UAdminForm.editDialog(
      title: p == null ? U.s.createItem(U.s.content) : U.s.editItem(U.s.content),
      formKey: c.formKey,
      maxWidth: 520,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<TagContent>(
          initialValue: c.tag,
          labelText: U.s.contentType,
          items: TagContent.values.map((TagContent t) => DropdownMenuItem<TagContent>(value: t, child: Text(t.localizedTitle))).toList(),
          onChanged: (TagContent? v) => c.tag = v ?? c.tag,
        ).pSymmetric(vertical: 6),
        UAdminForm.text(c.title, U.s.title),
        UAdminForm.text(c.subTitle, U.s.subtitle),
        UAdminForm.text(c.description, U.s.description, lines: 3),
        UAdminForm.text(c.detail1, U.s.detail1, lines: 2),
        UAdminForm.text(c.detail2, U.s.detail2, lines: 2),
        UAdminForm.text(c.order, U.s.order, number: true),
        URow(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          margin: const EdgeInsets.symmetric(vertical: 8),
          children: <Widget>[
            _Base64ImageField(label: U.s.image, initial: c.imageBase64, onChanged: (String? v) => c.imageBase64 = v).expanded(),
            _Base64ImageField(label: U.s.icon, initial: c.iconBase64, onChanged: (String? v) => c.iconBase64 = v).expanded(),
          ],
        ),
        UAdminForm.text(c.buttonText, U.s.buttonText),
        UAdminForm.text(c.buttonLink, U.s.buttonLink),
        UAdminForm.text(c.link, U.s.link),
        UAdminForm.sectionTitle(U.s.socialMedia),
        UAdminForm.text(c.instagram, U.s.instagram),
        UAdminForm.text(c.telegram, U.s.telegram),
        UAdminForm.text(c.whatsapp, U.s.whatsApp),
        UTextFieldPhoneNumber(controller: c.phone, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        _listHeader(U.s.items, U.s.addItem(""), () => setState(c.addItem)),
        ...c.items.mapIndexed((int index, UAdminContentItemForm e) => _itemCard(index, e, () => setState(() => c.items.removeAt(index)))),
        _listHeader(U.s.links, U.s.addItem(U.s.link), () => setState(c.addLink)),
        ...c.links.mapIndexed((int index, UAdminContentLinkForm e) => _linkCard(index, e, () => setState(() => c.links.removeAt(index)))),
      ],
    );
  }

  Widget _listHeader(String title, String addLabel, VoidCallback onAdd) => URow(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    margin: const EdgeInsets.only(top: 12),
    children: <Widget>[
      UTextBodyLarge(title),
      TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: Text(addLabel)),
    ],
  );

  Widget _itemCard(int index, UAdminContentItemForm e, VoidCallback onRemove) => UContainer(
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

  Widget _linkCard(int index, UAdminContentLinkForm e, VoidCallback onRemove) => UContainer(
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
    action: (List<UFileData> files) {
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
                  ? UImage("", fileData: UFileData(bytes: _decodeBase64(_value!)), borderRadius: 12)
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
