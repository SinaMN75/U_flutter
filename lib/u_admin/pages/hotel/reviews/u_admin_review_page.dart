import "package:u/utilities.dart";

class UAdminReviewPage extends StatefulWidget {
  const UAdminReviewPage({super.key});

  @override
  State<UAdminReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<UAdminReviewPage> {
  final UAdminReviewController c = UAdminReviewController();

  static const List<TagComment> _statuses = <TagComment>[TagComment.inQueue, TagComment.released, TagComment.rejected];

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
    title: U.s.reviews,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UColumn(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: _statuses
                .map(
                  (TagComment s) => ChoiceChip(
                    label: Text(s.localizedTitle),
                    selected: c.status == s,
                    onSelected: (bool _) => setState(() => c.changeStatus(s)),
                  ),
                )
                .toList(),
          ),
        ),
        UAdminListView<UCommentResponse>(
          state: c.state,
          items: () => c.list,
          totalCount: () => c.totalCount,
          onRetry: c.read,
          emptyText: U.s.noItemsFound(U.s.reviews),
          desktopHeader: () => UAdminTable.header(<String>[U.s.user, U.s.type, U.s.score, U.s.description, U.s.created, U.s.operations]),
          desktopRow: _itemDesktop,
          mobileRow: _itemResponsive,
        ).expanded(),
      ],
    ),
  );

  String _kind(UCommentResponse i) => i.hotelId != null ? U.s.hotel : U.s.dorm;

  String _user(UCommentResponse i) => i.user?.userName ?? "-";

  Widget _itemDesktop(UCommentResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell(_user(i)),
      UAdminTable.cell(_kind(i)),
      UAdminTable.cell(i.score.toStringAsFixed(1)),
      UAdminTable.cell(i.description, flex: 3),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UCommentResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.rate_review_outlined,
    title: _user(i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(U.s.type, _kind(i)),
      UAdminField(U.s.score, i.score.toStringAsFixed(1)),
      UAdminField(U.s.description, i.description),
      UAdminField(U.s.created, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UCommentResponse i) => UAdminOps.menu<UCommentResponse>(
    item: i,
    handlers: UAdminActionHandlers<UCommentResponse>(onDelete: c.delete),
    fallback: (UAdminActionContext<UCommentResponse> ctx) => <UAdminAction>[
      if (!i.tags.contains(TagComment.released.number)) UAdminAction(label: U.s.approve, icon: Icons.check_circle_outline, onTap: () => c.approve(i)),
      if (!i.tags.contains(TagComment.rejected.number)) UAdminAction(label: U.s.reject, icon: Icons.block_outlined, onTap: () => c.reject(i)),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteHotels]),
    ],
  );
}
