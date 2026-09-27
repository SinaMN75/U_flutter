import "package:u/utilities.dart";

class UAdminUserPage extends StatefulWidget {
  const UAdminUserPage({super.key});

  /// The one create ([user] == null) and edit dialog of a user; also opened from [UAdminHotelUserDetailPage].
  static Future<void> form(UAdminUsersController c, [UUserResponse? user]) {
    c.loadForm(user);
    return UAdminForm.editDialog(
      title: user == null ? U.s.register : "${U.s.edit} · ${user.displayName}",
      formKey: c.formKey,
      maxWidth: 440,
      onSubmit: c.save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UAdminForm.pair(context, UAdminForm.text(c.firstName, U.s.firstName, required: true), UAdminForm.text(c.lastName, U.s.lastName, required: true)),
        UTextField(
          controller: c.userName,
          labelText: U.s.username,
          readOnly: user != null,
          prefix: const Icon(Icons.alternate_email_rounded, size: 18),
          validator: UValidators.required(message: U.s.required),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
        UAdminForm.text(c.fatherName, U.s.fatherName, required: true),
        UTextFieldPhoneNumber(controller: c.phone, labelText: U.s.phoneNumber, required: true, margin: const EdgeInsets.symmetric(vertical: 6)),
        UAdminForm.text(c.email, U.s.email),
        UAdminForm.date(c.birthText, U.s.birthdate, (DateTime d) => c.birthdate = d, initial: c.birthdate, required: true),
        UAdminForm.text(c.password, U.s.password),
        UAdminForm.sectionTitle(U.s.gender),
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
  State<UAdminUserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UAdminUserPage> {
  final UAdminUsersController c = UAdminUsersController();

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
    onCreate: U.user.hasPermission(TagUser.permissionManageUsers) ? () => UAdminUserPage.form(c) : null,
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
      desktopHeader: () => UAdminTable.header(<String>[U.s.gender, U.s.name, U.s.username, U.s.phoneNumber, U.s.email, U.s.joinedDate, U.s.operations]),
      desktopRow: (UUserResponse i, int index) => URow(
        spacing: 8,
        color: UAdminTable.rowColor(context, index),
        padding: UAdminTable.rowPadding,
        children: <Widget>[
          _genderIcon(i).alignAtCenter().expanded(),
          URow(
            onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i),
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
        onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i),
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
      UPopupMenuItem(label: U.s.details, icon: Icons.badge_outlined, onTap: () => UAdminPageSwitcher.hotelUserDetail(user: i)),
      UPopupMenuItem(label: U.s.contracts, icon: Icons.description_outlined, onTap: () => UAdminPageSwitcher.contracts(user: i)),
      UPopupMenuItem(label: U.s.edit, icon: Icons.edit, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionManageUsers]), onTap: () => UAdminUserPage.form(c, i)),
      UPopupMenuItem(label: U.s.delete, icon: Icons.delete, destructive: true, visible: UAdmin.canAccess(<TagUser>[TagUser.permissionDeleteUsers]), onTap: () => c.delete(i)),
    ],
  );

  void _filter() => UAdminForm.filter(
    title: U.s.filterItem(U.s.users),
    onApply: c.applyFilters,
    onClear: c.clearFilters,
    children: (StateSetter setState) => <Widget>[
      UTextField(controller: c.queryFilter, labelText: U.s.search, prefix: const Icon(Icons.search), margin: const EdgeInsets.symmetric(vertical: 6)),
      UAdminForm.text(c.userNameFilter, U.s.username),
      UTextFieldPhoneNumber(controller: c.phoneFilter, labelText: U.s.phoneNumber, margin: const EdgeInsets.symmetric(vertical: 6)),
      UAdminForm.text(c.emailFilter, U.s.email),
      UAdminForm.pair(context, UAdminForm.text(c.firstNameFilter, U.s.firstName), UAdminForm.text(c.lastNameFilter, U.s.lastName)),
      UAdminForm.text(c.nationalCodeFilter, U.s.nationalCode, number: true),
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
      UAdminForm.pair(
        context,
        UAdminForm.date(c.controllerStartDate, U.s.fromDate, (DateTime d) => c.startDate = d, initial: c.startDate),
        UAdminForm.date(c.controllerEndDate, U.s.toDate, (DateTime d) => c.endDate = d, initial: c.endDate),
      ),
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

/// One user: role and permissions, dorm contracts and payments.
class UAdminHotelUserDetailPage extends StatefulWidget {
  const UAdminHotelUserDetailPage({required this.user, super.key});

  final UUserResponse user;

  @override
  State<UAdminHotelUserDetailPage> createState() => _HotelUserDetailPageState();
}

class _HotelUserDetailPageState extends State<UAdminHotelUserDetailPage> {
  final UAdminUsersController c = UAdminUsersController();

  UUserResponse get _u => c.user ?? widget.user;

  @override
  void initState() {
    c.readDetail(widget.user);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.userDetails),
      actions: <Widget>[
        if (U.user.hasPermission(TagUser.permissionManageUsers))
          IconButton(icon: const Icon(Icons.edit_rounded), tooltip: U.s.edit, onPressed: () => UAdminUserPage.form(c, _u).then((_) => c.readDetail(_u))),
        IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: () => c.readDetail(_u)),
      ],
    ),
    body: UAdminPageBody(
      child: UObx(() {
        if (c.state.isError()) {
          return UColumn(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: <Widget>[
              Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.error),
              UTextBodyMedium(U.s.errorReadingData),
              UButton(title: U.s.tryAgain, icon: const Icon(Icons.refresh), onTap: () => c.readDetail(_u), width: 180),
            ],
          ).alignAtCenter();
        }
        if (!c.state.isLoaded()) return const CircularProgressIndicator().alignAtCenter();
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: UAdminPageBody(
            maxWidth: 1100,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[_header(), _roles(), _contracts(), _payments()],
            ),
          ),
        );
      }),
    ),
  );

  Widget _header() {
    final String name = _u.displayName.nullIfEmpty() ?? _u.userName;
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
                  UTextBodyMedium("@${_u.userName}", color: UAdminTheme.white).ltr(),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(_u.phoneNumber ?? U.s.notUploaded, UAdminTheme.white, Icons.phone_rounded, onDark: true),
              _chip(_u.email ?? U.s.notUploaded, UAdminTheme.white, Icons.email_rounded, onDark: true),
              _chip(_u.createdAt.toJalaliDate(), UAdminTheme.white, Icons.event_rounded, onDark: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roles() {
    final List<TagUser> perms = TagUser.permissions.where((TagUser t) => _u.tags.contains(t.number)).toList();
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
              if (_u.isFullAdmin())
                _chip(U.s.admin, UAdminTheme.indigo, Icons.shield_rounded)
              else if (_u.isSubAdmin())
                _chip(U.s.subAdmin, UAdminTheme.blue, Icons.admin_panel_settings_rounded)
              else if (_u.tags.contains(TagUser.guest.number))
                _chip(U.s.guest, UAdminTheme.blueGrey, Icons.person_outline_rounded),
              if (c.contracts.isNotEmpty) _chip(U.s.tenant, UAdminTheme.green, Icons.home_rounded),
              _chip(_u.isMale() ? U.s.male : U.s.female, _u.isMale() ? UAdminTheme.blue : UAdminTheme.pink, _u.isMale() ? Icons.male_rounded : Icons.female_rounded),
              if (_u.tags.contains(TagUser.verified.number)) _chip(U.s.verified, UAdminTheme.green, Icons.verified_rounded),
            ],
          ),
          if (_u.isSubAdmin()) ...<Widget>[
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

  Widget _contracts() => _card(
    title: U.s.contracts,
    icon: Icons.description_outlined,
    trailing: _chip(c.contracts.length.separate3By3(), Theme.of(context).colorScheme.primary, Icons.tag_rounded),
    child: c.contracts.isEmpty
        ? UTextBodySmall(U.s.noData, color: UAdminTheme.grey, margin: const EdgeInsets.symmetric(vertical: 8))
        : UAdminResponsiveGrid(minTileWidth: 320, children: c.contracts.map(_contract).toList()),
  );

  Widget _contract(UDormBedContractResponse ct) {
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
                UAdminContractLifecycle.active => _chip(U.s.active, UAdminTheme.green, Icons.check_circle_rounded),
                UAdminContractLifecycle.upcoming => _chip(U.s.upcoming, UAdminTheme.orange, Icons.schedule_rounded),
                UAdminContractLifecycle.expired => _chip(U.s.expired, UAdminTheme.grey, Icons.history_rounded),
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
            onTap: () => UAdminPageSwitcher.invoices(contract: ct),
          ),
        ],
      ),
    );
  }

  Widget _payments() => _card(
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
}
