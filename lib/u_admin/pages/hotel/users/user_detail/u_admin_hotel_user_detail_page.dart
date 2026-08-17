import "package:u/utilities.dart";

class UAdminHotelUserDetailPage extends StatefulWidget {
  const UAdminHotelUserDetailPage({required this.user, super.key});

  final UUserResponse user;

  @override
  State<UAdminHotelUserDetailPage> createState() => _HotelUserDetailPageState();
}

class _HotelUserDetailPageState extends State<UAdminHotelUserDetailPage> {
  late final UAdminHotelUserDetailController c = UAdminHotelUserDetailController(user: widget.user);

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.userDetails),
      actions: <Widget>[
        if (U.user.hasPermission(TagUser.permissionManageUsers))
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: U.s.edit,
            onPressed: () => UAdminPageSwitcher.userCreateUpdate(user: c.user).then((_) => c.read()),
          ),
        IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: U.s.refresh, onPressed: c.read),
      ],
    ),
    body: Obx(() {
      if (c.state.isError()) return _error();
      if (!c.state.isLoaded()) return const CircularProgressIndicator().alignAtCenter();
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: UAdminPageBody(
          maxWidth: 1100,
          child: UColumn(
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(),
              const SizedBox(height: 16),
              _roleSection(),
              const SizedBox(height: 16),
              _contractsSection(),
              const SizedBox(height: 16),
              _paymentsSection(),
            ],
          ),
        ),
      );
    }),
  );

  Widget _error() => UColumn(
    spacing: 0,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.error),
      const SizedBox(height: 12),
      UTextBodyMedium(U.s.errorReadingData),
      const SizedBox(height: 12),
      UButton(title: U.s.tryAgain, icon: const Icon(Icons.refresh), onTap: c.read, width: 180),
    ],
  ).alignAtCenter();

  Widget _header() {
    final UUserResponse u = c.user;
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
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 0,
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: UAdminTheme.white24,
                child: UTextHeadlineSmall(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "?", color: UAdminTheme.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: UColumn(
                  spacing: 0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    UTextTitleLarge(name, color: UAdminTheme.white, fontWeight: FontWeight.w800, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    UTextBodyMedium("@${u.userName}", color: UAdminTheme.white).ltr(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill(Icons.phone_rounded, u.phoneNumber ?? U.s.notUploaded),
              _pill(Icons.email_rounded, u.email ?? U.s.notUploaded),
              _pill(Icons.event_rounded, u.createdAt.toJalaliDate()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: UAdminTheme.white24, borderRadius: BorderRadius.circular(30)),
    child: URow(
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: UAdminTheme.white),
        const SizedBox(width: 6),
        UTextBodySmall(text, color: UAdminTheme.white),
      ],
    ),
  );

  Widget _roleSection() {
    final UUserResponse u = c.user;
    final List<Widget> chips = <Widget>[
      if (u.isFullAdmin())
        _chip(U.s.admin, UAdminTheme.indigo, Icons.shield_rounded)
      else if (u.isSubAdmin())
        _chip(U.s.subAdmin, UAdminTheme.blue, Icons.admin_panel_settings_rounded)
      else if (u.tags.contains(TagUser.guest.number))
        _chip(U.s.guest, UAdminTheme.blueGrey, Icons.person_outline_rounded),
      if (c.contracts.isNotEmpty) _chip(U.s.tenant, UAdminTheme.green, Icons.home_rounded),
      _chip(u.isMale() ? U.s.male : U.s.female, u.isMale() ? UAdminTheme.blue : UAdminTheme.pink, u.isMale() ? Icons.male_rounded : Icons.female_rounded),
      if (u.tags.contains(TagUser.verified.number)) _chip(U.s.verified, UAdminTheme.green, Icons.verified_rounded),
    ];
    final List<TagUser> perms = TagUser.permissions.where((TagUser t) => u.tags.contains(t.number)).toList();
    return _card(
      title: U.s.permissions,
      icon: Icons.badge_outlined,
      child: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(spacing: 8, runSpacing: 8, children: chips),
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

  Widget _contractsSection() => _card(
    title: U.s.contracts,
    icon: Icons.description_outlined,
    trailing: _countBadge(c.contracts.length),
    child: c.contracts.isEmpty
        ? UTextBodySmall(U.s.noData, color: UAdminTheme.grey).pSymmetric(vertical: 8)
        : UAdminResponsiveGrid(
            minTileWidth: 320,
            children: c.contracts.map(_contractCard).toList(),
          ),
  );

  Widget _contractCard(UDormBedContractResponse ct) {
    final UAdminContractLifecycle life = c.lifecycleOf(ct);
    final String dorm = ct.bed?.room?.dorm?.title ?? "-";
    final String room = ct.bed?.room?.title ?? "-";
    final String bed = ct.bed?.title ?? "-";
    final int unpaid = c.unpaidCountOf(ct);
    final double outstanding = c.outstandingOf(ct);
    return UContainer(
      padding: const EdgeInsets.all(14),
      radius: 16,
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      child: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 0,
            children: <Widget>[
              const Icon(Icons.bed_rounded, size: 18),
              const SizedBox(width: 8),
              UTextBodyLarge("$dorm · $room · $bed", fontWeight: FontWeight.w700, maxLines: 1, overflow: TextOverflow.ellipsis).expanded(),
              _lifecycleChip(life),
            ],
          ),
          const Divider(height: 18),
          _kv(Icons.event_available_rounded, "${ct.startDate.toJalaliDate()} → ${ct.endDate.toJalaliDate()}"),
          const SizedBox(height: 6),
          _kv(Icons.payments_rounded, "${U.s.rent}: ${ct.rent.rial()} · ${U.s.deposit}: ${ct.deposit.rial()}"),
          const SizedBox(height: 6),
          _kv(Icons.receipt_long_rounded, "${U.s.invoices}: ${c.invoicesOf(ct).length} · ${U.s.unpaid}: $unpaid"),
          if (outstanding > 0) ...<Widget>[
            const SizedBox(height: 6),
            _kv(Icons.account_balance_wallet_rounded, "${U.s.debt}: ${outstanding.rial()}", color: UAdminTheme.red),
          ],
          const SizedBox(height: 10),
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

  Widget _lifecycleChip(UAdminContractLifecycle life) => switch (life) {
    UAdminContractLifecycle.active => _chip(U.s.active, UAdminTheme.green, Icons.check_circle_rounded),
    UAdminContractLifecycle.upcoming => _chip(U.s.upcoming, UAdminTheme.orange, Icons.schedule_rounded),
    UAdminContractLifecycle.expired => _chip(U.s.expired, UAdminTheme.grey, Icons.history_rounded),
  };

  Widget _paymentsSection() => _card(
    title: U.s.payments,
    icon: Icons.account_balance_wallet_outlined,
    child: UColumn(
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UAdminResponsiveGrid(
          minTileWidth: 220,
          children: <Widget>[
            _miniStat(U.s.walletBalance, c.totalWalletBalance.rial(), Icons.account_balance_wallet_rounded, UAdminTheme.green),
            _miniStat(U.s.wallets, c.wallets.length.separate3By3(), Icons.wallet_rounded, UAdminTheme.indigo),
            _miniStat(U.s.merchants, c.merchants.length.separate3By3(), Icons.storefront_rounded, UAdminTheme.orange),
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
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            UTextTitleSmall(title, fontWeight: FontWeight.w700).expanded(),
            ?trailing,
          ],
        ),
        const Divider(height: 18),
        child,
      ],
    ),
  );

  Widget _chip(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(30)),
    child: URow(
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        UTextBodySmall(label, color: color, fontWeight: FontWeight.w600),
      ],
    ),
  );

  Widget _countBadge(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(30)),
    child: UTextBodySmall(count.separate3By3(), color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
  );

  Widget _kv(IconData icon, String text, {Color? color}) => URow(
    spacing: 0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, size: 15, color: color ?? UAdminTheme.grey),
      const SizedBox(width: 8),
      UTextBodySmall(text, color: color).expanded(),
    ],
  );

  Widget _miniStat(String label, String value, IconData icon, Color color) => UContainer(
    padding: const EdgeInsets.all(14),
    radius: 14,
    color: color.withValues(alpha: 0.10),
    child: URow(
      spacing: 0,
      children: <Widget>[
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: UColumn(
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextTitleSmall(value, fontWeight: FontWeight.w800, maxLines: 1),
              UTextBodySmall(label, color: UAdminTheme.grey),
            ],
          ),
        ),
      ],
    ),
  );
}
