import "package:u/utilities.dart";

class UAdminUserPage extends StatefulWidget {
  const UAdminUserPage({required this.args, super.key});

  final UAdminUsersPageArgs args;

  @override
  State<UAdminUserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UAdminUserPage> {
  final UAdminUsersController c = UAdminUsersController();

  @override
  void initState() {
    c.init(args: widget.args);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UAdminScaffold(
    title: U.s.usersManagement,
    onFilter: _showFilterDialog,
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? () => UAdminPageSwitcher.userCreateUpdate().then((_) => c.read()) : null,
    pageNumber: c.pageNumber,
    totalPages: c.totalPages,
    onPageChanged: (int page) {
      c.pageNumber(page);
      c.read();
    },
    body: UAdminListView<UUserResponse>(
      state: c.state,
      items: () => c.list,
      totalCount: () => c.totalCount,
      onRetry: c.read,
      emptyText: U.s.noItemsFound(U.s.user),
      desktopHeader: () => UAdminTable.header(
        <String>[
          U.s.gender,
          U.s.name,
          U.s.username,
          U.s.phoneNumber,
          U.s.email,
          U.s.joinedDate,
          U.s.operations,
        ],
      ),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _roleChip(UUserResponse i) {
    final String label = i.isFullAdmin()
        ? U.s.admin
        : i.isSubAdmin()
        ? U.s.subAdmin
        : i.tags.contains(TagUser.guest.number)
        ? U.s.guest
        : U.s.user;
    final Color color = i.isFullAdmin()
        ? UAdminTheme.indigo
        : i.isSubAdmin()
        ? UAdminTheme.blue
        : i.tags.contains(TagUser.guest.number)
        ? UAdminTheme.blueGrey
        : UAdminTheme.grey;
    return UAdminTable.statusChip(context, label: label, color: color);
  }

  ({IconData icon, Color color}) _genderStyle(UUserResponse i) {
    final bool male = i.isMale();
    final bool female = i.isFemaleMale();
    return (
      icon: male
          ? Icons.male_rounded
          : female
          ? Icons.female_rounded
          : Icons.person_outline_rounded,
      color: male
          ? UAdminTheme.blue
          : female
          ? UAdminTheme.pink
          : UAdminTheme.grey,
    );
  }

  Widget _itemDesktop(UUserResponse i, int index) {
    final ({IconData icon, Color color}) gender = _genderStyle(i);
    return URow(
      spacing: 8,
      color: UAdminTable.rowColor(context, index),
      padding: UAdminTable.rowPadding,
      children: <Widget>[
        Icon(gender.icon, color: gender.color, size: 20).alignAtCenter().expanded(),
        URow(
          onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i),
          spacing: 6,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _roleChip(i),
            Flexible(
              child: UTextBodyMedium("${i.firstName ?? ""} ${i.lastName ?? ""}".trim(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ).expanded(),
        UTextBodyMedium(i.userName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis).onTap(() => UClipboard.set(i.userName)).expanded(),
        UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.center, textDirection: TextDirection.ltr).expanded(),
        UTextBodyMedium(i.email ?? "-", textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis).expanded(),
        UAdminTable.cell(i.createdAt.toJalaliDate()),
        _menu(i).expanded(),
      ],
    );
  }

  Widget _itemResponsive(UUserResponse i, int index) {
    final ({IconData icon, Color color}) gender = _genderStyle(i);
    return UAdminTable.mobileCard(
      context,
      leading: UContainer(
        width: 44,
        height: 44,
        radius: 12,
        color: gender.color.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Icon(gender.icon, color: gender.color, size: 22),
      ),
      title: "${i.firstName ?? ""} ${i.lastName ?? ""}".trim().nullIfEmpty() ?? i.userName,
      subtitle: i.userName,
      badge: _roleChip(i),
      trailing: _menu(i),
      onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i),
      fields: <UAdminField>[
        UAdminField(U.s.phoneNumber, null, valueWidget: UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.end, textDirection: TextDirection.ltr, fontWeight: FontWeight.w500)),
        UAdminField(U.s.email, i.email ?? "-"),
        UAdminField(U.s.joinedDate, i.createdAt.toJalaliDateTime()),
      ],
    );
  }

  Widget _menu(UUserResponse i) => UAdminOps.menu<UUserResponse>(
    context,
    item: i,
    handlers: UAdminActionHandlers<UUserResponse>(
      onEdit: (UUserResponse x) => UAdminPageSwitcher.userCreateUpdate(user: x).then((_) => c.read()),
      onDelete: c.delete,
    ),
    fallback: (UAdminActionContext<UUserResponse> ctx) => <UAdminAction>[
      UAdminLinks.hotelUserDetail(ctx.item),
      UAdminLinks.userContracts(ctx.item),
      ctx.edit(roles: <TagUser>[TagUser.permissionManageUsers]),
      ctx.delete(roles: <TagUser>[TagUser.permissionDeleteUsers]),
    ],
  );

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.users)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: Form(
          key: c.filterFormKey,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setLocal) => UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextField(controller: c.queryController, labelText: U.s.search, prefix: const Icon(Icons.search)).pSymmetric(vertical: 6),
                  UTextField(controller: c.userNameController, labelText: U.s.username).pSymmetric(vertical: 6),
                  UTextField(controller: c.phoneNumberController, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone).pSymmetric(vertical: 6),
                  UTextField(controller: c.emailController, labelText: U.s.email, keyboardType: TextInputType.emailAddress).pSymmetric(vertical: 6),
                  UTextField(controller: c.firstNameController, labelText: U.s.firstName).pSymmetric(vertical: 6),
                  UTextField(controller: c.lastNameController, labelText: U.s.lastName).pSymmetric(vertical: 6),
                  UTextField(controller: c.nationalCodeController, labelText: U.s.nationalCode, keyboardType: TextInputType.number).pSymmetric(vertical: 6),
                  UDropDownField<TagUser?>(
                    labelText: U.s.gender,
                    initialValue: c.selectedGender,
                    items: <DropdownMenuItem<TagUser?>>[
                      DropdownMenuItem<TagUser?>(child: Text(U.s.all)),
                      DropdownMenuItem<TagUser?>(value: TagUser.male, child: Text(U.s.male)),
                      DropdownMenuItem<TagUser?>(value: TagUser.female, child: Text(U.s.female)),
                    ],
                    onChanged: (TagUser? value) => setLocal(() => c.selectedGender = value),
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    jalali: true,
                    controller: c.fromCreatedAtController,
                    labelText: U.s.fromDate,
                    onChange: (DateTime d, Jalali j) {
                      c.fromCreatedAtController.text = j.formatCompactDate();
                      c.fromCreatedAt = d;
                    },
                  ).pSymmetric(vertical: 6),
                  UTextFieldDatePicker(
                    jalali: true,
                    controller: c.toCreatedAtController,
                    labelText: U.s.toDate,
                    onChange: (DateTime d, Jalali j) {
                      c.toCreatedAtController.text = j.formatCompactDate();
                      c.toCreatedAt = d;
                    },
                  ).pSymmetric(vertical: 6),
                  UDropDownField<int>(
                    labelText: U.s.createdDate,
                    initialValue: c.orderByCreatedAtDesc ? 1 : 0,
                    items: <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(value: 0, child: Text(U.s.accenting)),
                      DropdownMenuItem<int>(value: 1, child: Text(U.s.descending)),
                    ],
                    onChanged: (int? i) => setLocal(() {
                      c.orderByCreatedAt = i == 0;
                      c.orderByCreatedAtDesc = i == 1;
                    }),
                  ).pSymmetric(vertical: 6),
                  UDropDownField<TagUser>(
                    labelText: U.s.tags,
                    initialValue: c.selectedTag!,
                    items: TagUser.values.map((TagUser tag) => DropdownMenuItem<TagUser>(value: tag, child: Text(c.isFa ? tag.titleFa : tag.titleEn))).toList(),
                    onChanged: (TagUser? value) => setLocal(() => c.selectedTag = value),
                  ).pSymmetric(vertical: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(U.s.verified),
                    value: c.verifiedOnly,
                    onChanged: (bool v) => setLocal(() => c.verifiedOnly = v),
                  ),
                  const SizedBox(height: 20),
                  UButtonSubmitCancel(
                    submitTitle: U.s.filter,
                    cancelTitle: U.s.clearFilters,
                    onSubmit: () {
                      if (c.filterFormKey.currentState?.validate() ?? false) {
                        c.applyFilters();
                        UNavigator.back();
                      }
                    },
                    onCancel: () {
                      c.clearFilters();
                      c.filterFormKey.currentState?.reset();
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
}
