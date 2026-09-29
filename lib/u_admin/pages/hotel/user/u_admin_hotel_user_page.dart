part of "../../../u_admin.dart";

class UAdminHotelUserPage extends StatefulWidget {
  const UAdminHotelUserPage({super.key, this.user});

  static UAdminModule module({List<TagUser>? roles, UUserResponse? user}) => UAdminModule(
    title: user == null ? U.s.users : "${U.s.users} · ${user.displayName}",
    icon: Icons.person_rounded,
    page: () => UAdminHotelUserPage(user: user),
    roles: roles,
  );

  /// Opens this page for one user (from reservations or contracts) and pops up that user's dialog.
  final UUserResponse? user;

  @override
  State<UAdminHotelUserPage> createState() => _UAdminHotelUserPageState();
}

class _UAdminHotelUserPageState extends State<UAdminHotelUserPage> {
  final UAdminHotelUserController c = UAdminHotelUserController();

  @override
  void initState() {
    c.init(user: widget.user);
    if (widget.user != null) WidgetsBinding.instance.addPostFrameCallback((_) => _form(widget.user));
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
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? _form : null,
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
            onTap: () => _form(i),
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
        onTap: () => _form(i),
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

  /// The one user dialog: register a new user, or show an existing user's details with the edit fields below them.
  Future<void> _form([UUserResponse? user]) {
    c.loadForm(user);
    if (user != null) c.readDetail(user);
    final bool canEdit = U.user.hasPermission(TagUser.permissionManageUsers);
    return UFormDialog.show(
      title: user == null ? U.s.register : user.displayName.nullIfEmpty() ?? user.userName,
      maxWidth: user == null ? 440 : 900,
      onSubmit: user == null || canEdit ? c.save : null,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (user != null) ...<Widget>[
          UObx(() {
            if (c.detailState.isError()) {
              return UColumn(
                spacing: 12,
                children: <Widget>[
                  Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.error),
                  UTextBodyMedium(U.s.errorReadingData),
                  UButton(title: U.s.tryAgain, icon: const Icon(Icons.refresh), onTap: () => c.readDetail(user), width: 180),
                ],
              ).alignAtCenter();
            }
            if (!c.detailState.isLoaded()) return const CircularProgressIndicator().alignAtCenter().pAll(24);
            return UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[_detailHeader(user), _detailRoles(user), _detailContracts(), _detailPayments()],
            );
          }),
          if (canEdit) const Divider(height: 32),
        ],
        if (user == null || canEdit) ...<Widget>[
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
      ],
    );
  }

  Widget _detailHeader(UUserResponse u) {
    final String name = u.displayName.nullIfEmpty() ?? u.userName;
    return UContainer(
      padding: const EdgeInsets.all(20),
      radius: 22,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Theme.of(context).colorScheme.primary, UAdminTheme.indigo.shade400],
      ),
      boxShadow: <BoxShadow>[BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.30), blurRadius: 22, offset: const Offset(0, 10))],
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: <Widget>[
          URow(
            spacing: 16,
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: UAdminTheme.white24,
                child: UTextHeadlineSmall(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "?", color: UAdminTheme.white, fontWeight: FontWeight.w800),
              ),
              UColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                expanded: 1,
                children: <Widget>[
                  UTextTitleLarge(name, color: UAdminTheme.white, fontWeight: FontWeight.w800, maxLines: 1, overflow: TextOverflow.ellipsis),
                  UTextBodyMedium("@${u.userName}", color: UAdminTheme.white).ltr(),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(u.phoneNumber ?? U.s.notUploaded, UAdminTheme.white, Icons.phone_rounded, onDark: true),
              _chip(u.email ?? U.s.notUploaded, UAdminTheme.white, Icons.email_rounded, onDark: true),
              _chip(u.createdAt.toJalaliDate(), UAdminTheme.white, Icons.event_rounded, onDark: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRoles(UUserResponse u) {
    final List<TagUser> perms = TagUser.permissions.where((TagUser t) => u.tags.contains(t.number)).toList();
    return _card(
      title: U.s.permissions,
      icon: Icons.badge_outlined,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              if (u.isFullAdmin())
                _chip(U.s.admin, UAdminTheme.indigo, Icons.shield_rounded)
              else if (u.isSubAdmin())
                _chip(U.s.subAdmin, UAdminTheme.blue, Icons.admin_panel_settings_rounded)
              else if (u.tags.contains(TagUser.guest.number))
                _chip(U.s.guest, UAdminTheme.blueGrey, Icons.person_outline_rounded),
              if (c.contracts.isNotEmpty) _chip(U.s.tenant, UAdminTheme.green, Icons.home_rounded),
              _chip(u.isMale() ? U.s.male : U.s.female, u.isMale() ? UAdminTheme.blue : UAdminTheme.pink, u.isMale() ? Icons.male_rounded : Icons.female_rounded),
              if (u.tags.contains(TagUser.verified.number)) _chip(U.s.verified, UAdminTheme.green, Icons.verified_rounded),
            ],
          ),
          if (u.isSubAdmin()) ...<Widget>[
            const Divider(height: 22),
            if (perms.isEmpty)
              UTextBodySmall(U.s.noData, color: UAdminTheme.grey)
            else
              Wrap(spacing: 8, runSpacing: 8, children: perms.map((TagUser t) => _chip(t.titleFa, UAdminTheme.orange, Icons.check_rounded)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _detailContracts() => _card(
    title: U.s.contracts,
    icon: Icons.description_outlined,
    trailing: _chip(c.contracts.length.separate3By3(), Theme.of(context).colorScheme.primary, Icons.tag_rounded),
    child: c.contracts.isEmpty
        ? UTextBodySmall(U.s.noData, color: UAdminTheme.grey, margin: const EdgeInsets.symmetric(vertical: 8))
        : UAdminResponsiveGrid(minTileWidth: 320, children: c.contracts.map(_detailContract).toList()),
  );

  Widget _detailContract(UDormBedContractResponse ct) {
    final List<UDormBedInvoiceResponse> invoices = ct.invoices ?? <UDormBedInvoiceResponse>[];
    final double outstanding = c.outstandingOf(ct);
    return UContainer(
      padding: const EdgeInsets.all(14),
      radius: 16,
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: <Widget>[
          URow(
            spacing: 8,
            children: <Widget>[
              const Icon(Icons.bed_rounded, size: 18),
              UTextBodyLarge(
                "${ct.bed?.room?.dorm?.title ?? "-"} · ${ct.bed?.room?.title ?? "-"} · ${ct.bed?.title ?? "-"}",
                fontWeight: FontWeight.w700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                expanded: 1,
              ),
              switch (c.lifecycleOf(ct)) {
                UAdminHotelContractLifecycle.active => _chip(U.s.active, UAdminTheme.green, Icons.check_circle_rounded),
                UAdminHotelContractLifecycle.upcoming => _chip(U.s.upcoming, UAdminTheme.orange, Icons.schedule_rounded),
                UAdminHotelContractLifecycle.expired => _chip(U.s.expired, UAdminTheme.grey, Icons.history_rounded),
              },
            ],
          ),
          const Divider(height: 12),
          _line(Icons.event_available_rounded, "${ct.startDate.toJalaliDate()} → ${ct.endDate.toJalaliDate()}"),
          _line(Icons.payments_rounded, "${U.s.rent}: ${ct.rent.rial()} · ${U.s.deposit}: ${ct.deposit.rial()}"),
          _line(Icons.receipt_long_rounded, "${U.s.invoices}: ${invoices.length} · ${U.s.unpaid}: ${invoices.where((UDormBedInvoiceResponse i) => !i.isPaid).length}"),
          if (outstanding > 0) _line(Icons.account_balance_wallet_rounded, "${U.s.debt}: ${outstanding.rial()}", color: UAdminTheme.red),
          UButton(
            type: UButtonType.text,
            title: U.s.invoices,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => UAdminHotelInvoicePage.module(contract: ct).open(),
          ),
        ],
      ),
    );
  }

  Widget _detailPayments() => _card(
    title: U.s.payments,
    icon: Icons.account_balance_wallet_outlined,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UAdminResponsiveGrid(
          minTileWidth: 220,
          children: <Widget>[
            _stat(U.s.walletBalance, c.totalWalletBalance.rial(), Icons.account_balance_wallet_rounded, UAdminTheme.green),
            _stat(U.s.wallets, c.wallets.length.separate3By3(), Icons.wallet_rounded, UAdminTheme.indigo),
            _stat(U.s.merchants, c.merchants.length.separate3By3(), Icons.storefront_rounded, UAdminTheme.orange),
          ],
        ),
        if (c.merchants.isNotEmpty) ...<Widget>[
          const Divider(height: 22),
          Wrap(spacing: 8, runSpacing: 8, children: c.merchants.map((UMerchantResponse m) => _chip(m.title, UAdminTheme.orange, Icons.storefront_rounded)).toList()),
        ],
      ],
    ),
  );

  Widget _card({required String title, required IconData icon, required Widget child, Widget? trailing}) => UContainer(
    padding: const EdgeInsets.all(18),
    radius: 20,
    color: Theme.of(context).cardTheme.color,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 8,
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            UTextTitleSmall(title, fontWeight: FontWeight.w700, expanded: 1),
            ?trailing,
          ],
        ),
        const Divider(height: 18),
        child,
      ],
    ),
  );

  Widget _chip(String label, Color color, IconData icon, {bool onDark = false}) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    color: onDark ? UAdminTheme.white24 : color.withValues(alpha: 0.14),
    radius: 30,
    child: URow(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
      ],
    ),
  );

  Widget _line(IconData icon, String text, {Color? color}) => URow(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Icon(icon, size: 15, color: color ?? UAdminTheme.grey),
      UTextBodySmall(text, color: color, expanded: 1),
    ],
  );

  Widget _stat(String label, String value, IconData icon, Color color) => UContainer(
    padding: const EdgeInsets.all(14),
    radius: 14,
    color: color.withValues(alpha: 0.10),
    child: URow(
      spacing: 10,
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          expanded: 1,
          children: <Widget>[
            UTextTitleSmall(value, fontWeight: FontWeight.w800, maxLines: 1),
            UTextBodySmall(label, color: UAdminTheme.grey),
          ],
        ),
      ],
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
      UPopupMenuItem(label: U.s.details, icon: Icons.badge_outlined, onTap: () => _form(i)),
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminHotelContractPage.module(user: i).open()),
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
