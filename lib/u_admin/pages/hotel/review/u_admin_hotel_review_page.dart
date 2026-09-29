part of "../../../u_admin.dart";

class UAdminHotelReviewPage extends StatefulWidget {
  const UAdminHotelReviewPage({super.key});

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.reviews,
    icon: Icons.rate_review_rounded,
    page: () => const UAdminHotelReviewPage(),
    roles: roles,
  );

  @override
  State<UAdminHotelReviewPage> createState() => _UAdminHotelReviewPageState();
}

class _UAdminHotelReviewPageState extends State<UAdminHotelReviewPage> {
  final UAdminHotelReviewController c = UAdminHotelReviewController();

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
          desktopHeader: () => <Widget>[
            UAdminTable.headerCell(U.s.user),
            UAdminTable.headerCell(U.s.type),
            UAdminTable.headerCell(U.s.score),
            UAdminTable.headerCell(U.s.description),
            UAdminTable.headerCell(U.s.created),
            UAdminTable.headerCell(U.s.operations),
          ],
          desktopRow: _itemDesktop,
          mobileRow: _itemMobile,
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

  Widget _itemMobile(UCommentResponse i, int index) => UAdminTable.mobileCard(
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

  Widget _menu(UCommentResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.approve, icon: Icons.check_circle_outline, visible: !i.tags.contains(TagComment.released.number), onTap: () => c.approve(i)),
      UPopupMenuItem(label: U.s.reject, icon: Icons.block_outlined, visible: !i.tags.contains(TagComment.rejected.number), onTap: () => c.reject(i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteHotels]), onTap: () => c.delete(i)),
    ],
  );
}
