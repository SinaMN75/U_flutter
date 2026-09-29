part of "../../u_admin.dart";

class UAdminBlogPage extends StatefulWidget {
  const UAdminBlogPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.blogs,
    icon: Icons.article_rounded,
    page: () => const UAdminBlogPage(),
    roles: roles,
  );

  @override
  State<UAdminBlogPage> createState() => _UAdminBlogPageState();
}

class _UAdminBlogPageState extends State<UAdminBlogPage> {
  final UAdminBlogController c = UAdminBlogController();

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
    title: U.s.blogs,
    onFilter: _filter,
    onCreate: _form,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UBlogResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.blogs),
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell("", flex: 0),
        UAdminTable.headerCell(U.s.title, flex: 3),
        UAdminTable.headerCell(U.s.status),
        UAdminTable.headerCell(U.s.comments),
        UAdminTable.headerCell(U.s.createdAt),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
  );

  Widget _itemDesktop(UBlogResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      SizedBox(width: 48, child: i.media?.firstOrNull?.url != null ? UImage(i.media!.first.url!, borderRadius: 8) : const Icon(Icons.article_outlined)).expanded(flex: 0),
      UAdminTable.cell(i.title, flex: 3),
      UAdminTable.statusChip(label: _isPublished(i) ? U.s.published : U.s.draft, color: _isPublished(i) ? UAdminTheme.green : UAdminTheme.grey).alignAtCenter().expanded(),
      UAdminTable.cell((i.commentCount ?? 0).toString()),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemMobile(UBlogResponse i, int index) => UAdminTable.mobileCard(
    leading: i.media?.firstOrNull?.url != null ? SizedBox(width: 44, height: 44, child: UImage(i.media!.first.url!, borderRadius: 12)) : UAdminTable.leadingIcon(Icons.article_outlined),
    title: i.title,
    badge: UAdminTable.statusChip(label: _isPublished(i) ? U.s.published : U.s.draft, color: _isPublished(i) ? UAdminTheme.green : UAdminTheme.grey),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.comments, (i.commentCount ?? 0).toString()),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UBlogResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, onTap: () => _form(i)),
      UPopupMenuItem(label: _isPublished(i) ? U.s.unpublish : U.s.publish, icon: _isPublished(i) ? Icons.unpublished_outlined : Icons.publish_rounded, onTap: () => c.setPublished(i, !_isPublished(i))),
      UPopupMenuItem(label: U.s.comments, icon: Icons.comment_outlined, onTap: () => _comments(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.blogs),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[UTextField(controller: c.titleFilterController, labelText: U.s.title, margin: const EdgeInsets.symmetric(vertical: 6))],
  );

  bool _isPublished(UBlogResponse i) => i.tags.contains(TagBlog.published.number);

  void _comments(UBlogResponse i) {
    UNavigator.dialog(
      AlertDialog(
        title: Text("${U.s.comments} · ${i.title}"),
        content: SizedBox(
          width: context.dialogWidth(),
          child: (i.comments?.isEmpty ?? true)
              ? Center(child: Text(U.s.noItemsFound(U.s.comments)).pSymmetric(vertical: 24))
              : SingleChildScrollView(
                  child: UColumn(
                    children: (i.comments ?? <UCommentResponse>[])
                        .map(
                          (UCommentResponse cm) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: UTextBodyMedium(cm.description),
                            subtitle: UTextBodySmall("${cm.user?.userName ?? "---"} • ${cm.createdAt.toJalaliDate()}"),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ),
        actions: <Widget>[TextButton(onPressed: UNavigator.back, child: Text(U.s.ok))],
      ),
    );
  }

  Future<void> _form([UBlogResponse? b]) async {
    await c.loadForm(b);
    await UFormDialog.show(
      title: b == null ? U.s.createItem(U.s.blog) : U.s.editItem(U.s.blog),
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: c.titleController, labelText: U.s.title, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.subtitleController, labelText: U.s.subtitle, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.slugController, labelText: U.s.slug, margin: const EdgeInsets.symmetric(vertical: 6)),
        const Divider(height: 20),
        UTextBodySmall(U.s.content, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UContainer(
          onTap: () async {
            final String? html = await URichTextEditor.open(initialHtml: c.contentController.text);
            if (html != null) setState(() => c.contentController.text = html);
          },
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 72, maxHeight: 220),
          padding: const EdgeInsets.all(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          radius: 8,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: c.contentController.text.trim().isEmpty
              ? URow(children: <Widget>[const Icon(Icons.edit_note), const SizedBox(width: 8), Text(U.s.richTextEditor)])
              : SingleChildScrollView(child: UHtmlView(html: c.contentController.text)),
        ),
        if (c.categories.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: c.categories
                .map(
                  (UCategoryResponse cat) => FilterChip(
                    label: Text(cat.title),
                    selected: c.isSelected(cat),
                    onSelected: (bool on) => setState(() => c.toggleCategory(cat, on)),
                  ),
                )
                .toList(),
          ).pSymmetric(vertical: 12),
        UFilePicker(onFilesChanged: (List<UFileData> i) => c.files = i),
      ],
    );
  }
}
