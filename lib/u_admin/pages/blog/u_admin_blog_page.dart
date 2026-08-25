import "package:u/utilities.dart";

class UAdminBlogPage extends StatefulWidget {
  const UAdminBlogPage({super.key});

  @override
  State<UAdminBlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<UAdminBlogPage> {
  final UAdminBlogController c = UAdminBlogController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.blogs,
    onFilter: _showFilterDialog,
    onCreate: _showEditDialog,
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
      mobileRow: _itemResponsive,
    ),
  );

  bool _isPublished(UBlogResponse i) => i.tags.contains(TagBlog.published.number);

  Widget _itemDesktop(UBlogResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      SizedBox(width: 48, child: i.media?.firstOrNull?.url != null ? UImage(i.media!.first.url!, borderRadius: 8) : const Icon(Icons.article_outlined)).expanded(flex: 0),
      UAdminTable.cell(i.title, flex: 3),
      UAdminTable.statusChip(context, label: _isPublished(i) ? U.s.published : U.s.draft, color: _isPublished(i) ? UAdminTheme.green : UAdminTheme.grey).alignAtCenter().expanded(),
      UAdminTable.cell((i.commentCount ?? 0).toString()),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UBlogResponse i, int index) => UAdminTable.mobileCard(
    context,
    leading: i.media?.firstOrNull?.url != null ? SizedBox(width: 44, height: 44, child: UImage(i.media!.first.url!, borderRadius: 12)) : UAdminTable.leadingIcon(context, Icons.article_outlined),
    title: i.title,
    badge: UAdminTable.statusChip(context, label: _isPublished(i) ? U.s.published : U.s.draft, color: _isPublished(i) ? UAdminTheme.green : UAdminTheme.grey),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.comments, (i.commentCount ?? 0).toString()),
      UAdminField(U.s.createdAt, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UBlogResponse i) => UAdminOps.menu<UBlogResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UBlogResponse>(
      onEdit: (UBlogResponse x) => _showEditDialog(p: x),
      onDelete: c.delete,
      extras: <String, void Function(UBlogResponse)>{
        "togglePublish": (UBlogResponse x) => _isPublished(x) ? c.unpublish(x) : c.publish(x),
        "comments": _showCommentsDialog,
      },
    ),
    fallback: (UAdminActionContext<UBlogResponse> ctx) => <UAdminAction>[
      ctx.edit(),
      ctx.extra("togglePublish", label: _isPublished(ctx.item) ? U.s.unpublish : U.s.publish, icon: _isPublished(ctx.item) ? Icons.unpublished_outlined : Icons.publish_rounded),
      ctx.extra("comments", label: U.s.comments, icon: Icons.comment_outlined),
      ctx.delete(),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.blogs)),
      content: Form(
        key: c.filterFormKey,
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.titleFilter, labelText: U.s.title).pSymmetric(vertical: 6),
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
  );

  void _showCommentsDialog(UBlogResponse i) {
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

  Future<void> _showEditDialog({UBlogResponse? p}) async {
    final TextEditingController title = TextEditingController(text: p?.title);
    final TextEditingController subtitle = TextEditingController(text: p?.subtitle);
    final TextEditingController slug = TextEditingController(text: p?.slug);
    final TextEditingController content = TextEditingController(text: p?.content);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    List<FileData> files = <FileData>[];
    final List<UCategoryResponse> selectedCategories = <UCategoryResponse>[...(p?.categories ?? <UCategoryResponse>[])];
    final List<UCategoryResponse> allCategories = await c.fetchCategories();

    await UNavigator.dialog(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(p == null ? U.s.createItem(U.s.blog) : U.s.editItem(U.s.blog)),
          content: SizedBox(
            width: context.dialogWidth(max: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: UColumn(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextField(
                      controller: title,
                      labelText: U.s.title,
                      validator: UValidators.required(message: ""),
                    ).pSymmetric(vertical: 6),
                    UTextField(controller: subtitle, labelText: U.s.subtitle).pSymmetric(vertical: 6),
                    UTextField(controller: slug, labelText: U.s.slug).pSymmetric(vertical: 6),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: UTextBodyMedium(U.s.content, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ).pOnly(top: 6, bottom: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final String? html = await URichTextEditor.open(initialHtml: content.text);
                        if (html != null) setDialogState(() => content.text = html);
                      },
                      child: UContainer(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 72, maxHeight: 220),
                        padding: const EdgeInsets.all(12),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        radius: 8,
                        child: content.text.trim().isEmpty
                            ? URow(children: <Widget>[const Icon(Icons.edit_note), const SizedBox(width: 8), Text(U.s.richTextEditor)])
                            : SingleChildScrollView(child: UHtmlView(html: content.text)),
                      ),
                    ).pSymmetric(vertical: 6),
                    const SizedBox(height: 12),
                    if (allCategories.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: allCategories
                            .map(
                              (UCategoryResponse cat) => FilterChip(
                                label: Text(cat.title),
                                selected: selectedCategories.any((UCategoryResponse x) => x.id == cat.id),
                                onSelected: (bool selected) => setDialogState(() {
                                  if (selected) {
                                    selectedCategories.add(cat);
                                  } else {
                                    selectedCategories.removeWhere((UCategoryResponse x) => x.id == cat.id);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ).pSymmetric(vertical: 6),
                    const SizedBox(height: 12),
                    UFilePicker(onFilesChanged: (List<FileData> i) => files = i),
                    const SizedBox(height: 20),
                    UButtonSubmitCancel(
                      onSubmit: () => UValidators.validateForm(
                        key: formKey,
                        action: () {
                          final List<String> categoryIds = selectedCategories.map((UCategoryResponse cat) => cat.id).toList();
                          if (p == null) {
                            c.create(
                              p: UBlogCreateParams(
                                tags: <int>[TagBlog.draft.number],
                                title: title.text,
                                subtitle: subtitle.text.nullIfEmpty(),
                                slug: slug.text.nullIfEmpty(),
                                content: content.text.nullIfEmpty(),
                                categories: categoryIds,
                              ),
                              files: files,
                            );
                          } else {
                            c.update(
                              p: UBlogUpdateParams(
                                id: p.id,
                                title: title.text,
                                subtitle: subtitle.text.nullIfEmpty(),
                                slug: slug.text.nullIfEmpty(),
                                content: content.text.nullIfEmpty(),
                                categories: categoryIds,
                              ),
                              files: files,
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
}
