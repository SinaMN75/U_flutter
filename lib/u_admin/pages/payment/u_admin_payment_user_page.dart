part of "../../u_admin.dart";

class UAdminPaymentUserPage extends StatefulWidget {
  const UAdminPaymentUserPage({super.key});

  static void open() => U.addOrSwitchTab(U.s.usersManagement, const UAdminPaymentUserPage());

  static UAdminModule module({List<TagUser>? roles}) => UAdminModule(
    title: U.s.usersManagement,
    icon: Icons.manage_accounts_rounded,
    page: () => const UAdminPaymentUserPage(),
    roles: roles,
  );

  static Future<void> form(UAdminPaymentUserController c, [UUserResponse? user]) {
    c.loadForm(user);
    return UFormDialog.show(
      title: user == null ? U.s.register : "${U.s.edit} · ${user.displayName}",
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
                UAdminPaymentUserDetailDialog.show(user);
              },
            ),
          ),
        const Divider(height: 20),
        UTextBodySmall(U.s.userInformation, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UFieldPair(
          UTextField(controller: c.firstNameController, labelText: U.s.firstName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
          UTextField(controller: c.lastNameController, labelText: U.s.lastName, validator: UValidators.required(message: ""), margin: const EdgeInsets.symmetric(vertical: 6)),
        ),
        UFieldPair(UTextField(
            controller: c.userNameController,
            labelText: U.s.username,
            readOnly: user != null,
            prefix: const Icon(Icons.alternate_email_rounded, size: 18),
            validator: UValidators.required(message: U.s.required),
          ), UTextField(controller: c.fatherNameController, labelText: U.s.fatherName)),
        UFieldPair(UTextField(
            controller: c.nationalCodeController,
            labelText: U.s.nationalCode,
            keyboardType: TextInputType.number,
            maxLength: 10,
            prefix: const Icon(Icons.badge_outlined, size: 18),
            validator: UValidators.iranianNationalCode(isRequired: false),
          ), UTextFieldDatePicker(
            controller: c.birthDateController,
            labelText: U.s.birthdate,
            jalali: true,
            margin: const EdgeInsets.symmetric(vertical: 6),
            onChange: (DateTime d, UJalali j) {
              c.birthdate = d;
              c.birthDateController.text = d.toJalaliDate();
            },
          )),
        UTextField(
          controller: c.passwordController,
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
        const Divider(height: 20),
        UTextBodySmall(U.s.contactInformation, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
        UFieldPair(
          UTextFieldPhoneNumber(controller: c.phoneNumberController, labelText: U.s.phoneNumber, required: true),
          UTextFieldPhoneNumber(controller: c.landLineController, labelText: U.s.landline),
        ),
        UTextField(
          controller: c.emailController,
          labelText: U.s.email,
          keyboardType: TextInputType.emailAddress,
          prefix: const Icon(Icons.email_rounded, size: 18),
          validator: UValidators.email(isRequired: false),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UTextField(controller: c.bioController, labelText: U.s.bio, lines: 3, margin: const EdgeInsets.symmetric(vertical: 6)),
        if (c.canManageRoles) ...<Widget>[
          const Divider(height: 20),
          UTextBodySmall(U.s.roles, color: UAdminTheme.grey, fontWeight: FontWeight.w700),
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
  State<UAdminPaymentUserPage> createState() => _UAdminPaymentUserPageState();
}

class _UAdminPaymentUserPageState extends State<UAdminPaymentUserPage> {
  final UAdminPaymentUserController c = UAdminPaymentUserController();

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
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? () => UAdminPaymentUserPage.form(c).then((_) => c.read()) : null,
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
      desktopHeader: () => <Widget>[
        UAdminTable.headerCell(U.s.name),
        UAdminTable.headerCell(U.s.username),
        UAdminTable.headerCell(U.s.phoneNumber),
        UAdminTable.headerCell(U.s.nationalCode),
        UAdminTable.headerCell(U.s.verificationStatus),
        UAdminTable.headerCell(U.s.joinedDate),
        UAdminTable.headerCell(U.s.operations),
      ],
      desktopRow: _itemDesktop,
      mobileRow: _itemMobile,
    ),
  );

  Widget _statusChip(UUserResponse i) {
    final bool verified = i.tags.containsAny(UAdminPaymentUserController.verifiedTags.map((TagUser t) => t.number).toList());
    final bool awaiting = i.tags.containsAny(UAdminPaymentUserController.awaitingTags.map((TagUser t) => t.number).toList());
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

  Widget _itemMobile(UUserResponse i, int index) => UAdminTable.mobileCard(
    icon: Icons.person_rounded,
    title: "${i.firstName ?? ""} ${i.lastName ?? ""}".trim().nullIfEmpty() ?? i.userName,
    subtitle: i.userName,
    badge: _statusChip(i),
    onTap: () => UAdminPaymentUserDetailDialog.show(i),
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
      UPopupMenuItem(label: U.s.viewItem(U.s.details), icon: Icons.visibility_outlined, onTap: () => UAdminPaymentUserDetailDialog.show(i)),
      UPopupMenuItem(label: U.s.merchants, icon: Icons.storefront_outlined, onTap: () => UAdminPaymentMerchantPage.open(user: i)),
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminHotelContractPage.open(user: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageUsers]), onTap: () => UAdminPaymentUserPage.form(c, i).then((_) => c.read())),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteUsers]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UFilterDialog.show(
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
      UTextField(controller: c.firstNameFilterController, labelText: U.s.firstName, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.lastNameFilterController, labelText: U.s.lastName, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.userNameFilterController, labelText: U.s.username, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.phoneNumberFilterController, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.nationalCodeFilterController, labelText: U.s.nationalCode, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.emailFilterController, labelText: U.s.email, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldPhoneNumber(controller: c.landLineFilterController, labelText: U.s.landline, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextField(controller: c.bioFilterController, labelText: U.s.bio, margin: const EdgeInsets.symmetric(vertical: 6)),
      UTextFieldDatePicker(
        controller: c.startDateController,
        labelText: U.s.fromDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.startDate = d;
          c.startDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.endDateController,
        labelText: U.s.toDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.endDate = d;
          c.endDateController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.fromBirthController,
        labelText: U.s.fromBirthDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.fromBirthDate = d;
          c.fromBirthController.text = d.toJalaliDate();
        },
      ),
      UTextFieldDatePicker(
        controller: c.toBirthController,
        labelText: U.s.toBirthDate,
        jalali: true,
        margin: const EdgeInsets.symmetric(vertical: 6),
        onChange: (DateTime d, UJalali j) {
          c.toBirthDate = d;
          c.toBirthController.text = d.toJalaliDate();
        },
      ),
    ],
  );
}
