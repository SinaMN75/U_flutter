import "package:u/utilities.dart";

class UAdminUsersPage extends StatefulWidget {
  const UAdminUsersPage({super.key});

  static Future<void> form(UAdminPaymentUsersController c, [UUserResponse? user]) {
    c.loadForm(user);
    return UAdminForm.editDialog(
      title: user == null ? U.s.register : "${U.s.edit} · ${user.displayName}",
      formKey: c.formKey,
      maxWidth: 520,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (user != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: UButton(
              type: UButtonType.text,
              title: U.s.userDetails,
              icon: const Icon(Icons.link_rounded, size: 18),
              onTap: () {
                UNavigator.back();
                UAdminPageSwitcher.adminUserDetail(user: user);
              },
            ),
          ),
        UAdminForm.sectionTitle(U.s.userInformation),
        UAdminForm.pair(context, UAdminForm.text(c.firstName, U.s.firstName, required: true), UAdminForm.text(c.lastName, U.s.lastName, required: true)),
        UAdminForm.pair(
          context,
          UTextField(
            controller: c.userName,
            labelText: U.s.username,
            readOnly: user != null,
            prefix: const Icon(Icons.alternate_email_rounded, size: 18),
            validator: UValidators.required(message: U.s.required),
          ),
          UTextField(controller: c.fatherName, labelText: U.s.fatherName),
        ),
        UAdminForm.pair(
          context,
          UTextField(
            controller: c.nationalCode,
            labelText: U.s.nationalCode,
            keyboardType: TextInputType.number,
            maxLength: 10,
            prefix: const Icon(Icons.badge_outlined, size: 18),
            validator: UValidators.iranianNationalCode(isRequired: false),
          ),
          UAdminForm.date(c.birthDate, U.s.birthdate, (DateTime d) => c.birthdate = d),
        ),
        UTextField(
          controller: c.password,
          labelText: U.s.password,
          keyboardType: TextInputType.visiblePassword,
          prefix: const Icon(Icons.lock_outline_rounded, size: 18),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextBodySmall(U.s.gender, color: UAdminTheme.grey).alignAtCenterLeft(),
        USegmentedControl<TagUser>(
          selectedValue: c.gender,
          items: <TagUser, String>{TagUser.male: U.s.male, TagUser.female: U.s.female, TagUser.unspecified: TagUser.unspecified.localizedTitle},
          onValueChanged: (TagUser? v) => setState(() => c.gender = v ?? c.gender),
        ).pOnly(top: 6, bottom: 6),
        UAdminForm.sectionTitle(U.s.contactInformation),
        UAdminForm.pair(
          context,
          UTextFieldPhoneNumber(controller: c.phoneNumber, labelText: U.s.phoneNumber, required: true),
          UTextFieldPhoneNumber(controller: c.landLine, labelText: U.s.landline),
        ),
        UTextField(
          controller: c.email,
          labelText: U.s.email,
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(Icons.email_rounded, size: 18),
          validator: UValidators.email(isRequired: false),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UAdminForm.text(c.bio, U.s.bio, lines: 3),
        if (c.canManageRoles) ...<Widget>[
          UAdminForm.sectionTitle(U.s.roles),
          USegmentedControl<TagUser>(
            selectedValue: c.role,
            items: <TagUser, String>{TagUser.superAdmin: U.s.admin, TagUser.subAdmin: U.s.subAdmin, TagUser.guest: U.s.guest},
            onValueChanged: (TagUser? v) => setState(() => c.role = v ?? c.role),
          ).pOnly(top: 6, bottom: 6),
          if (c.role == TagUser.subAdmin) ...<Widget>[
            UTextBodySmall(U.s.permissions, color: UAdminTheme.grey).pOnly(top: 6),
            ...TagUser.permissions.map(
              (TagUser t) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(t.localizedTitle),
                value: c.permissions.contains(t),
                onChanged: (bool? v) => setState(() => c.togglePermission(t, v ?? false)),
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  State<UAdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<UAdminUsersPage> {
  final UAdminPaymentUsersController c = UAdminPaymentUsersController();

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
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? () => UAdminUsersPage.form(c).then((_) => c.read()) : null,
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
      emptyText: U.s.noItemsFound(U.s.users),
      desktopHeader: () => UAdminTable.header(
        <String>[
          U.s.name,
          U.s.username,
          U.s.phoneNumber,
          U.s.nationalCode,
          U.s.verificationStatus,
          U.s.joinedDate,
          U.s.operations,
        ],
      ),
      desktopRow: _itemDesktop,
      mobileRow: _itemResponsive,
    ),
  );

  Widget _statusChip(UUserResponse i) {
    final bool verified = i.tags.containsAny(UAdminPaymentUsersController.verifiedTags.map((TagUser t) => t.number).toList());
    final bool awaiting = i.tags.containsAny(UAdminPaymentUsersController.awaitingTags.map((TagUser t) => t.number).toList());
    final Color color = verified
        ? UAdminTheme.green
        : awaiting
        ? UAdminTheme.orange
        : UAdminTheme.grey;
    final String label = verified
        ? U.s.verified
        : awaiting
        ? U.s.pendingVerification
        : U.s.notUploaded;
    return UContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: color.withValues(alpha: 0.15),
      radius: 20,
      child: UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _itemDesktop(UUserResponse i, int index) => URow(
    spacing: 8,
    color: UAdminTable.rowColor(context, index),
    padding: UAdminTable.rowPadding,
    children: <Widget>[
      UAdminTable.cell("${i.firstName ?? ""} ${i.lastName ?? ""}".trim()),
      UAdminTable.cell(i.userName),
      UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.center, textDirection: TextDirection.ltr, expanded: 1),
      UAdminTable.cell(i.nationalCode ?? "-"),
      _statusChip(i).alignAtCenter().expanded(),
      UAdminTable.cell(i.createdAt.toJalaliDate()),
      _menu(i).expanded(),
    ],
  );

  Widget _itemResponsive(UUserResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.person_rounded,
    title: "${i.firstName ?? ""} ${i.lastName ?? ""}".trim().nullIfEmpty() ?? i.userName,
    subtitle: i.userName,
    badge: _statusChip(i),
    onTap: () => UAdminPageSwitcher.adminUserDetail(user: i),
    trailing: _menu(i),
    fields: <UAdminField>[
      UAdminField(
        U.s.phoneNumber,
        null,
        valueWidget: UTextBodyMedium(i.phoneNumber ?? "-", textAlign: TextAlign.end, textDirection: TextDirection.ltr, fontWeight: FontWeight.w500),
      ),
      UAdminField(U.s.nationalCode, i.nationalCode ?? "-"),
      UAdminField(U.s.joinedDate, i.createdAt.toJalaliDate()),
    ],
  );

  Widget _menu(UUserResponse i) => UPopupMenu(
    items: <UPopupMenuItem>[
      UPopupMenuItem(label: U.s.viewItem(U.s.details), icon: Icons.visibility_outlined, onTap: () => UAdminPageSwitcher.adminUserDetail(user: i)),
      UPopupMenuItem(label: U.s.merchants, icon: Icons.storefront_outlined, onTap: () => UAdminPageSwitcher.merchants(user: i)),
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminPageSwitcher.contracts(user: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageUsers]), onTap: () => UAdminUsersPage.form(c, i).then((_) => c.read())),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteUsers]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.users),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UDropDownField<TagUser?>(
        initialValue: c.verificationStatus,
        onChanged: (TagUser? v) => c.verificationStatus = v,
        items: <DropdownMenuItem<TagUser?>>[
          DropdownMenuItem<TagUser>(value: TagUser.verified, child: Text(TagUser.verified.localizedTitle)),
          DropdownMenuItem<TagUser>(value: TagUser.awaitingVerification, child: Text(TagUser.awaitingVerification.localizedTitle)),
          const DropdownMenuItem<TagUser?>(child: Text("---")),
        ],
      ).pSymmetric(vertical: 6),
      UAdminForm.text(c.firstNameFilter, U.s.firstName),
      UAdminForm.text(c.lastNameFilter, U.s.lastName),
      UAdminForm.text(c.userNameFilter, U.s.username),
      UTextFieldPhoneNumber(controller: c.phoneNumberFilter, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
      UAdminForm.text(c.nationalCodeFilter, U.s.nationalCode),
      UAdminForm.text(c.emailFilter, U.s.email),
      UTextFieldPhoneNumber(controller: c.landLineFilter, labelText: U.s.landline, margin: const EdgeInsets.symmetric(vertical: 6)),
      UAdminForm.text(c.bioFilter, U.s.bio),
      UAdminForm.date(c.fromCreatedController, U.s.fromDate, (DateTime d) => c.fromCreatedAt = d),
      UAdminForm.date(c.toCreatedController, U.s.toDate, (DateTime d) => c.toCreatedAt = d),
      UAdminForm.date(c.fromBirthController, U.s.fromBirthDate, (DateTime d) => c.fromBirthDate = d),
      UAdminForm.date(c.toBirthController, U.s.toBirthDate, (DateTime d) => c.toBirthDate = d),
    ],
  );
}
