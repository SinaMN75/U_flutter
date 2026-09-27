part of "../../u_admin.dart";

class UAdminHotelUserPage extends StatefulWidget {
  const UAdminHotelUserPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.users, const UAdminHotelUserPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.users,
    icon: Icons.person_rounded,
    page: () => const UAdminHotelUserPage(),
    roles: roles,
  );

  /// The one create ([user] == null) and edit dialog of a user; also opened from [UAdminHotelUserDetailDialog].
  static Future<void> form(UAdminHotelUserController c, [UUserResponse? user]) {
    c.loadForm(user);
    return UFormDialog.show(
      title: user == null ? U.s.register : "${U.s.edit} · ${user.displayName}",
      maxWidth: 440,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UFieldPair(
          UTextField(controller: c.firstNameController, labelText: U.s.firstName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.lastNameController, labelText: U.s.lastName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UTextField(
          controller: c.userNameController,
          labelText: U.s.username,
          readOnly: user != null,
          prefix: const Icon(Icons.alternate_email_rounded, size: 18),
          validator: UValidators.required(message: U.s.required),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(controller: c.fatherNameController, labelText: U.s.fatherName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldPhoneNumber(controller: c.phoneController, labelText: U.s.phoneNumber, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.emailController, labelText: U.s.email, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextFieldDatePicker(
          controller: c.birthDateController,
          labelText: U.s.birthdate,
          jalali: true,
          initialDate: c.birthdate,
          validator: UValidators.required(message: ""),
          margin: const EdgeInsets.symmetric(vertical: 6),
          onChange: (DateTime d, UJalali j) {
            c.birthdate = d;
            c.birthDateController.text = d.toJalaliDate();
          },
        ),
        UTextField(controller: c.passwordController, labelText: U.s.password, margin: const EdgeInsets.symmetric(vertical: 6)),
        const Divider(height: 20),
        UTextBodySmall(U.s.gender, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        USegmentedControl<int>(
          selectedValue: c.gender.number,
          items: <int, String>{TagUser.male.number: U.s.male, TagUser.female.number: U.s.female},
          onValueChanged: (int? i) => setState(() => c.gender = TagUser.values.fromNumber(i!) ?? c.gender),
        ).pSymmetric(vertical: 6),
        if (c.canManageRoles) ...<Widget>[
          USegmentedControl<int>(
            selectedValue: c.role.number,
            items: <int, String>{TagUser.superAdmin.number: U.s.admin, TagUser.subAdmin.number: U.s.subAdmin, TagUser.guest.number: U.s.guest},
            onValueChanged: (int? i) => setState(() => c.role = TagUser.values.fromNumber(i!) ?? c.role),
          ).pSymmetric(vertical: 6),
          if (c.role == TagUser.subAdmin) ...<Widget>[
            UTextBodySmall(U.s.permissions, color: UAdminTheme.grey),
            ...TagUser.permissions.map(
              (TagUser t) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(t.localizedTitle),
                value: c.permissions.contains(t),
                onChanged: (bool? on) => setState(() => (on ?? false) ? c.permissions.add(t) : c.permissions.remove(t)),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  State<UAdminHotelUserPage> createState() => _UAdminHotelUserPageState();
}

class _UAdminHotelUserPageState extends State<UAdminHotelUserPage> {
  final UAdminHotelUserController c = UAdminHotelUserController();

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
    title: U.s.usersManagement,
    onFilter: _filter,
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? () => UAdminHotelUserPage.form(c) : null,
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
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.gender),
        UAdminTable.headerCell(U.s.name),
        UAdminTable.headerCell(U.s.username),
        UAdminTable.headerCell(U.s.phoneNumber),
        UAdminTable.headerCell(U.s.email),
        UAdminTable.headerCell(U.s.joinedDate),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: (UUserResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          _genderIcon(i).alignAtCenter().expanded(),
          URow(
            onTap: () => UAdminHotelUserDetailDialog.show(i),
            spacing: 6,
            mainAxisAlignment: MainAxisAlignment.center,
            expanded: 1,
            children: <Widget>[
              _role(i),
              Flexible(
                child: UTextBodyMedium("${i.firstName ?? ""} ${i.lastName ?? ""}".trim(), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          UTextBodyMedium(i.userName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, onTap: () => UClipboard.set(i.userName), expanded: 1),
          UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.center, textDirection: TextDirection.ltr, expanded: 1),
          UTextBodyMedium(i.email ?? "-", textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, expanded: 1),
          UAdminTable.cell(i.createdAt.toJalaliDate()),
          _menu(i).expanded(),
        ],
      ),
      mobileRow: (UUserResponse i, int index) => UAdminTable.mobileCard(
        leading: _genderIcon(i),
        title: "${i.firstName ?? ""} ${i.lastName ?? ""}".trim().nullIfEmpty() ?? i.userName,
        subtitle: i.userName,
        badge: _role(i),
        trailing: _menu(i),
        onTap: () => UAdminHotelUserDetailDialog.show(i),
        fields: <UAdminField>[
          UAdminField(
            U.s.phoneNumber,
            null,
            valueWidget: UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.end, textDirection: TextDirection.ltr, fontWeight: FontWeight.w500),
          ),
          UAdminField(U.s.email, i.email ?? "-"),
          UAdminField(U.s.joinedDate, i.createdAt.toJalaliDateTime()),
        ],
      ),
    ),
  );

  Widget _role(UUserResponse i) => i.isFullAdmin()
      ? UAdminTable.statusChip(label: U.s.admin, color: UAdminTheme.indigo)
      : i.isSubAdmin()
      ? UAdminTable.statusChip(label: U.s.subAdmin, color: UAdminTheme.blue)
      : i.tags.contains(TagUser.guest.number)
      ? UAdminTable.statusChip(label: U.s.guest, color: UAdminTheme.blueGrey)
      : UAdminTable.statusChip(label: U.s.user, color: UAdminTheme.grey);

  Widget _genderIcon(UUserResponse i) => i.isMale()
      ? const Icon(Icons.male_rounded, color: UAdminTheme.blue)
      : i.isFemaleMale()
      ? const Icon(Icons.female_rounded, color: UAdminTheme.pink)
      : const Icon(Icons.person_outline_rounded, color: UAdminTheme.grey);

  Widget _menu(UUserResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.details, icon: Icons.badge_outlined, onTap: () => UAdminHotelUserDetailDialog.show(i)),
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminHotelContractPage.open(user: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageUsers]), onTap: () => UAdminHotelUserPage.form(c, i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteUsers]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
    title: U.s.filterItem(U.s.users),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UTextField(controller: c.queryFilterController, labelText: U.s.search, prefix: const Icon(Icons.search), margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.userNameFilterController, labelText: U.s.username, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.phoneFilterController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.emailFilterController, labelText: U.s.email, margin: const EdgeInsets.symmetric(vertical: 6)),
      UFieldPair(
        UTextField(controller: c.firstNameFilterController, labelText: U.s.firstName, margin: const EdgeInsets.symmetric(vertical: 6)),
        UTextField(controller: c.lastNameFilterController, labelText: U.s.lastName, margin: const EdgeInsets.symmetric(vertical: 6)),
      ),
      UTextField(controller: c.nationalCodeFilterController, labelText: U.s.nationalCode, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
      UDropDownField<TagUser?>(
        labelText: U.s.gender,
        initialValue: c.genderFilter,
        items: <DropdownMenuItem<TagUser?>>[
          DropdownMenuItem<TagUser?>(child: Text(U.s.all)),
          DropdownMenuItem<TagUser?>(value: TagUser.male, child: Text(U.s.male)),
          DropdownMenuItem<TagUser?>(value: TagUser.female, child: Text(U.s.female)),
        ],
        onChanged: (TagUser? v) => c.genderFilter = v,
      ).pSymmetric(vertical: 6),
      UFieldPair(UTextFieldDatePicker(
          controller: c.startDateController,
          labelText: U.s.fromDate,
          jalali: true,
          initialDate: c.startDate,
          margin: const EdgeInsets.symmetric(vertical: 6),
          onChange: (DateTime d, UJalali j) {
            c.startDate = d;
            c.startDateController.text = d.toJalaliDate();
          },
        ), UTextFieldDatePicker(
          controller: c.endDateController,
          labelText: U.s.toDate,
          jalali: true,
          initialDate: c.endDate,
          margin: const EdgeInsets.symmetric(vertical: 6),
          onChange: (DateTime d, UJalali j) {
            c.endDate = d;
            c.endDateController.text = d.toJalaliDate();
          },
        )),
      UDropDownField<TagOrderBy>(
        labelText: U.s.createdDate,
        initialValue: c.tagOrderBy.value,
        items: <DropdownMenuItem<TagOrderBy>>[
          DropdownMenuItem<TagOrderBy>(value: TagOrderBy.createdAt, child: Text(U.s.accenting)),
          DropdownMenuItem<TagOrderBy>(value: TagOrderBy.createdAtDescending, child: Text(U.s.descending)),
        ],
        onChanged: c.tagOrderBy.call,
      ).pSymmetric(vertical: 6),
      UDropDownField<TagUser?>(
        labelText: U.s.tags,
        initialValue: c.tagFilter,
        items: <DropdownMenuItem<TagUser?>>[
          DropdownMenuItem<TagUser?>(child: Text(U.s.all)),
          ...TagUser.values.map((TagUser t) => DropdownMenuItem<TagUser?>(value: t, child: Text(t.localizedTitle))),
        ],
        onChanged: (TagUser? v) => c.tagFilter = v,
      ).pSymmetric(vertical: 6),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(U.s.verified), value: c.verifiedOnly, onChanged: (bool v) => setState(() => c.verifiedOnly = v)),
    ],
  );
}
