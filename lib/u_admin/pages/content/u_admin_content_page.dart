part of "../../u_admin.dart";

class UAdminContentPage extends StatefulWidget {
  const UAdminContentPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.content,
    icon: Icons.content_copy,
    selectedIcon: Icons.content_copy_outlined,
    page: () => const UAdminContentPage(),
    roles: roles,
  );

  @override
  State<UAdminContentPage> createState() => _UAdminContentPageState();
}

class _UAdminContentPageState extends State<UAdminContentPage> {
  final UAdminContentController c = UAdminContentController();

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
    child: base64.isNotNullOrEmpty() ? UImage("", fileData: UFileData(bytes: (base64!.contains(",") ? base64.split(",").last : base64).toBytesFromBase64()), borderRadius: 8) : const Icon(Icons.image_outlined),
  );

  Widget _itemMobile(UContentResponse i, int index) => UAdminTable.mobileCard(
    leading: _thumb(i.jsonData.imageBase64 ?? i.jsonData.iconBase64, size: 44),
    title: i.jsonData.title ?? "---",
    badge: UAdminTable.statusChip(label: UAdminContentController.tagOf(i)?.localizedTitle ?? "---", color: Theme.of(context).colorScheme.primary),
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
      UAdminTable.cell(UAdminContentController.tagOf(i)?.localizedTitle ?? "---"),
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

  void _filter() => UFilterDialog.show(
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
    await UFormDialog.show(
      title: p == null ? U.s.createItem(U.s.content) : U.s.editItem(U.s.content),
      maxWidth: 520,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<TagContent>(
          initialValue: c.tag,
          labelText: U.s.contentType,
          items: TagContent.values.map((TagContent t) => DropdownMenuItem<TagContent>(value: t, child: Text(t.localizedTitle))).toList(),
          onChanged: (TagContent? v) => c.tag = v ?? c.tag,
        ).pSymmetric(vertical: 6),
        UTextField(controller: c.titleController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.subTitleController, labelText: U.s.subtitle, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.descriptionController, labelText: U.s.description, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.detail1Controller, labelText: U.s.detail1, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.detail2Controller, labelText: U.s.detail2, lines: 2, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.orderController, labelText: U.s.order, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
        URow(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          margin: const EdgeInsets.symmetric(vertical: 8),
          children: <Widget>[
            UBase64ImagePicker(label: U.s.image, initial: c.imageBase64, onChanged: (String? v) => c.imageBase64 = v).expanded(),
            UBase64ImagePicker(label: U.s.icon, initial: c.iconBase64, onChanged: (String? v) => c.iconBase64 = v).expanded(),
          ],
        ),
        UTextField(controller: c.buttonTextController, labelText: U.s.buttonText, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.buttonLinkController, labelText: U.s.buttonLink, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.linkController, labelText: U.s.link, margin: const EdgeInsets.symmetric(vertical: 6)),
        const Divider(height: 20),
        UTextBodySmall(U.s.socialMedia, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UTextField(controller: c.instagramController, labelText: U.s.instagram, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.telegramController, labelText: U.s.telegram, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.whatsappController, labelText: U.s.whatsApp, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
        _listHeader(U.s.items, U.s.addItem(""), () => setState(c.addItem)),
        ...c.items.mapIndexed((int index, UAdminContentItemForm e) => _itemCard(index, e, () => setState(() => c.removeItem(index)))),
        _listHeader(U.s.links, U.s.addItem(U.s.link), () => setState(c.addLink)),
        ...c.links.mapIndexed((int index, UAdminContentLinkForm e) => _linkCard(index, e, () => setState(() => c.removeLink(index)))),
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
        UTextField(controller: e.titleController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.subTitleController, labelText: U.s.subtitle, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.descriptionController, labelText: U.s.description, lines: 2, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.linkController, labelText: U.s.link, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.orderController, labelText: U.s.order, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 4)),
        const SizedBox(height: 8),
        URow(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UBase64ImagePicker(label: U.s.icon, initial: e.iconBase64, onChanged: (String? v) => e.iconBase64 = v).expanded(),
            UBase64ImagePicker(label: U.s.image, initial: e.imageBase64, onChanged: (String? v) => e.imageBase64 = v).expanded(),
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
        UTextField(controller: e.titleController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 4)),
        UTextField(controller: e.urlController, labelText: U.s.url, margin: const EdgeInsets.symmetric(vertical: 4)),
        const SizedBox(height: 8),
        UBase64ImagePicker(label: U.s.icon, initial: e.iconBase64, onChanged: (String? v) => e.iconBase64 = v),
      ],
    ),
  );
}
