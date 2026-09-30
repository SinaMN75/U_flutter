import "package:u/utilities.dart";

/// One item of UPopupMenu: label, icon, action, destructive style.
class UPopupMenuItem {
  const UPopupMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.visible = true,
    this.destructive = false,
    this.color,
  });

  /// Label text.
  final String label;

  /// Icon shown with it.
  final IconData icon;

  /// Called when tapped.
  final VoidCallback onTap;

  /// False hides it completely (takes no space).
  final bool visible;

  /// Paints it in the error color (delete).
  final bool destructive;

  /// Main color (defaults to the theme).
  final Color? color;
}

/// ⋮ button that opens a menu of UPopupMenuItem. `UPopupMenu(items: [UPopupMenuItem(label: "Delete", icon: Icons.delete, onTap: delete, destructive: true)])`
class UPopupMenu extends StatelessWidget {
  const UPopupMenu({
    required this.items,
    super.key,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  /// The items to show.
  final List<UPopupMenuItem> items;

  /// Icon shown with it.
  final IconData icon;

  /// Text shown on long press / mouse hover.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final List<UPopupMenuItem> shown = items.where((UPopupMenuItem i) => i.visible).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<void>(
      icon: Icon(icon),
      tooltip: tooltip,
      itemBuilder: (BuildContext context) => shown.map((UPopupMenuItem i) {
        final Color? color = i.destructive ? Theme.of(context).colorScheme.error : i.color;
        return PopupMenuItem<void>(
          onTap: i.onTap,
          child: UIconTextHorizontal(
            leading: Icon(i.icon, size: 20, color: color),
            trailing: Text(i.label, style: color == null ? null : TextStyle(color: color)),
          ),
        );
      }).toList(),
    );
  }
}
