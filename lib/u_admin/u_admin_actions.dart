part of "u_admin.dart";

class UAdminAction {
  UAdminAction({required this.label, required this.icon, required this.onTap, this.roles, this.visible = true, this.destructive = false, this.color});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<TagUser>? roles;
  final bool visible;
  final bool destructive;
  final Color? color;

  bool get allowed => visible && UAdmin.canAccess(roles);
}

class UAdminActionHandlers<T> {
  UAdminActionHandlers({this.onEdit, this.onDelete, this.onDetail, this.extras});

  final void Function(T item)? onEdit;
  final void Function(T item)? onDelete;
  final void Function(T item)? onDetail;
  final Map<String, void Function(T item)>? extras;
}

class UAdminActionContext<T> {
  UAdminActionContext(this.item, this._handlers);

  final T item;
  final UAdminActionHandlers<T> _handlers;

  UAdminAction edit({List<TagUser>? roles}) => UAdminAction(label: U.s.edit, icon: Icons.edit, roles: roles, onTap: () => _handlers.onEdit?.call(item));

  UAdminAction delete({List<TagUser>? roles}) => UAdminAction(label: U.s.delete, icon: Icons.delete, destructive: true, roles: roles, onTap: () => _handlers.onDelete?.call(item));

  UAdminAction detail({String? label, IconData icon = Icons.info_outline, List<TagUser>? roles}) =>
      UAdminAction(label: label ?? U.s.viewItem(U.s.details), icon: icon, roles: roles, onTap: () => _handlers.onDetail?.call(item));

  UAdminAction extra(String key, {required String label, required IconData icon, bool destructive = false, bool visible = true, Color? color, List<TagUser>? roles}) =>
      UAdminAction(label: label, icon: icon, destructive: destructive, visible: visible, color: color, roles: roles, onTap: () => _handlers.extras?[key]?.call(item));
}

typedef UAdminActionBuilder<T> = List<UAdminAction> Function(UAdminActionContext<T> ctx);

// Renders a row's "operations" popup. A page calls this with its [handlers] and its
// own [fallback] default actions; if the app supplied [actions], those win.
abstract class UAdminOps {
  static Widget menu<T>(
    BuildContext context, {
    required T item,
    required UAdminActionHandlers<T> handlers,
    required UAdminActionBuilder<T> fallback,
    UAdminActionBuilder<T>? actions,
  }) {
    final UAdminActionContext<T> ctx = UAdminActionContext<T>(item, handlers);
    final List<UAdminAction> shown = (actions ?? fallback)(ctx).where((UAdminAction a) => a.allowed).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) => shown.map((UAdminAction a) {
        final Color? color = a.destructive ? Theme.of(context).colorScheme.error : a.color;
        return PopupMenuItem<String>(
          onTap: a.onTap,
          child: UIconTextHorizontal(
            leading: Icon(a.icon, size: 20, color: color),
            trailing: Text(a.label, style: color == null ? null : TextStyle(color: color)),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Cross-page navigation links used inside action builders so an admin can jump
// between related records ("navigate everywhere from everywhere").
// ---------------------------------------------------------------------------

abstract class UAdminLinks {
  // ---- from a user ----
  static UAdminAction adminUserDetail(UUserResponse u, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.viewItem(U.s.details),
    icon: Icons.visibility_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.adminUserDetail(user: u),
  );

  static UAdminAction hotelUserDetail(UUserResponse u, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.details,
    icon: Icons.badge_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.hotelUserDetail(user: u),
  );

  static UAdminAction userMerchants(UUserResponse u, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.merchants,
    icon: Icons.storefront_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.merchants(user: u),
  );

  static UAdminAction userContracts(UUserResponse u, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.contracts,
    icon: Icons.description_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.contracts(user: u),
  );

  // ---- from a merchant ----
  static UAdminAction merchantTerminals(UMerchantResponse m, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.viewItem(U.s.terminals),
    icon: Icons.point_of_sale_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.terminals(merchant: m),
  );

  // ---- from a parking ----
  static UAdminAction parkingReport(UParkingResponse p, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.viewItem(U.s.parkingReports),
    icon: Icons.assessment_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.parkingReport(parking: p),
  );

  static UAdminAction parkingTariff(UParkingResponse p, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.tariffs,
    icon: Icons.request_quote_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.parkingTariff(parking: p),
  );

  static UAdminAction parkingSubscription(UParkingResponse p, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.subscriptions,
    icon: Icons.card_membership_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.parkingSubscription(parking: p),
  );

  static UAdminAction parkingStaff(UParkingResponse p, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.staff,
    icon: Icons.badge_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.parkingStaff(parking: p),
  );

  static UAdminAction parkingPlateFlag(UParkingResponse p, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.specialPlates,
    icon: Icons.gpp_maybe_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.parkingPlateFlag(parking: p),
  );

  static UAdminAction parkingShift(UParkingResponse p, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.shift,
    icon: Icons.point_of_sale_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.parkingShift(parking: p),
  );

  // ---- from a hotel / room ----
  static UAdminAction hotelRooms(UHotelResponse h, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.rooms,
    icon: Icons.meeting_room_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.hotelRooms(hotel: h),
  );

  static UAdminAction hotelReservations(UHotelResponse h, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.reservations,
    icon: Icons.event_available_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.reservations(hotel: h),
  );

  static UAdminAction roomReservations(UHotelRoomResponse r, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.reservations,
    icon: Icons.event_available_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.reservations(room: r),
  );

  // ---- from a dorm / room / bed ----
  static UAdminAction dormRooms(UDormResponse d, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.room,
    icon: Icons.meeting_room_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.dormRooms(dorm: d),
  );

  static UAdminAction dormBeds(UDormResponse d, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.beds,
    icon: Icons.bed_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.dormBeds(dorm: d),
  );

  static UAdminAction roomBeds(UDormRoomResponse r, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.beds,
    icon: Icons.bed_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.dormBeds(room: r),
  );

  static UAdminAction bedContracts(UDormBedResponse b, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.contracts,
    icon: Icons.description_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.contracts(bed: b),
  );

  // ---- from a contract ----
  static UAdminAction contractInvoices(UDormBedContractResponse c, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.viewItem(U.s.invoices),
    icon: Icons.receipt_long_outlined,
    roles: roles,
    onTap: () => UAdminPageSwitcher.invoices(contract: c),
  );

  static UAdminAction contractTenant(UUserResponse u, {List<TagUser>? roles}) => UAdminAction(
    label: U.s.tenant,
    icon: Icons.person_outline,
    roles: roles,
    onTap: () => UAdminPageSwitcher.hotelUserDetail(user: u),
  );
}
