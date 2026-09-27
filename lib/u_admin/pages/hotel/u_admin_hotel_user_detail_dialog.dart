part of "../../u_admin.dart";

/// One hotel user: role and permissions, dorm contracts and payments.
class UAdminHotelUserDetailDialog extends StatefulWidget {
  const UAdminHotelUserDetailDialog({required this.user, super.key});

  static Future<void> show(UUserResponse user) => UNavigator.dialog<void>(UAdminHotelUserDetailDialog(user: user));

  final UUserResponse user;

  @override
  State<UAdminHotelUserDetailDialog> createState() => _UAdminHotelUserDetailDialogState();
}

class _UAdminHotelUserDetailDialogState extends State<UAdminHotelUserDetailDialog> {
  final UAdminHotelUserDetailController c = UAdminHotelUserDetailController();
  final UAdminHotelUserController users = UAdminHotelUserController();

  @override
  void initState() {
    c.init(user: widget.user);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    users.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: SizedBox(
      width: context.dialogWidth(max: 1100),
      height: context.dialogHeight(max: 800),
      child: UScaffold(
        appBar: AppBar(
          title: Text(U.s.userDetails),
          actions: <Widget>[
            if (U.user.hasPermission(TagUser.permissionManageUsers))
              IconButton(icon: const Icon(Icons.edit_rounded), tooltip: U.s.edit, onPressed: () => UAdminHotelUserPage.form(users, c.user).then((_) => c.read())),
            IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: c.read),
          ],
        ),
        body: UObx(() {
          if (c.state.isError()) {
            return UColumn(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 12,
              children: <Widget>[
                Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.error),
                UTextBodyMedium(U.s.errorReadingData),
                UButton(title: U.s.tryAgain, icon: const Icon(Icons.refresh), onTap: c.read, width: 180),
              ],
            ).alignAtCenter();
          }
          if (!c.state.isLoaded()) return const CircularProgressIndicator().alignAtCenter();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[_header(), _roles(), _contracts(), _payments()],
            ),
          );
        }),
      ),
    ),
  );

  Widget _header() {
    final String name = c.user.displayName.nullIfEmpty() ?? c.user.userName;
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
                  UTextBodyMedium("@${c.user.userName}", color: UAdminTheme.white).ltr(),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(c.user.phoneNumber ?? U.s.notUploaded, UAdminTheme.white, Icons.phone_rounded, onDark: true),
              _chip(c.user.email ?? U.s.notUploaded, UAdminTheme.white, Icons.email_rounded, onDark: true),
              _chip(c.user.createdAt.toJalaliDate(), UAdminTheme.white, Icons.event_rounded, onDark: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roles() {
    final List<TagUser> perms = TagUser.permissions.where((TagUser t) => c.user.tags.contains(t.number)).toList();
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
              if (c.user.isFullAdmin())
                _chip(U.s.admin, UAdminTheme.indigo, Icons.shield_rounded)
              else if (c.user.isSubAdmin())
                _chip(U.s.subAdmin, UAdminTheme.blue, Icons.admin_panel_settings_rounded)
              else if (c.user.tags.contains(TagUser.guest.number))
                _chip(U.s.guest, UAdminTheme.blueGrey, Icons.person_outline_rounded),
              if (c.contracts.isNotEmpty) _chip(U.s.tenant, UAdminTheme.green, Icons.home_rounded),
              _chip(c.user.isMale() ? U.s.male : U.s.female, c.user.isMale() ? UAdminTheme.blue : UAdminTheme.pink, c.user.isMale() ? Icons.male_rounded : Icons.female_rounded),
              if (c.user.tags.contains(TagUser.verified.number)) _chip(U.s.verified, UAdminTheme.green, Icons.verified_rounded),
            ],
          ),
          if (c.user.isSubAdmin()) ...<Widget>[
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
            onTap: () => UAdminHotelInvoicePage.open(contract: ct),
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
