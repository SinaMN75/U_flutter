part of "u_admin.dart";

/// Presentation pieces shared by the admin dashboards.
///
/// The dashboards grew their own copies of these and drifted apart — one drew a
/// bare [Icon] where the other used [UIconBackground], one hid the sub-label in
/// the subtitle column where the other put it in the trailing slot. Two boards in
/// the same panel should not look like two products, so they share these now.
abstract class UAdminDashboard {
  /// A single metric inside the coloured hero banner at the top of a dashboard.
  static Widget heroMetric(String label, String value, IconData icon) => ListTile(
    leading: UIconBackground(icon, color: UAdminTheme.white),
    title: UTextBodyMedium(label, color: UAdminTheme.white),
    subtitle: UTextBodyLarge(value, color: UAdminTheme.white),
  );

  /// A headline figure with its caption, and an optional coloured note in the trailing slot.
  static Widget statCard(String title, String value, String sub, IconData icon, Color color, VoidCallback? onTap) => UCard(
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: UIconBackground(icon, color: color),
      title: UTextTitleMedium(value, fontWeight: FontWeight.w800, maxLines: 1),
      subtitle: UTextBodySmall(title, color: UAdminTheme.grey),
      trailing: sub.isNullOrEmpty() ? null : UTextBodySmall(sub, color: color, fontWeight: FontWeight.w600),
      onTap: onTap,
    ),
  );

  /// A fixed-height titled panel that a chart is dropped into.
  static Widget chartCard(BuildContext context, {required String title, required Widget child}) => UContainer(
    height: 320,
    padding: const EdgeInsets.all(18),
    radius: 20,
    color: Theme.of(context).cardTheme.color,
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextTitleSmall(title, fontWeight: FontWeight.w700),
        const Divider(height: 18),
        child.expanded(),
      ],
    ),
  );
}
