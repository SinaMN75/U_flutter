import "package:u/utilities.dart";

class UPopupMenuItem {
  const UPopupMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.visible = true,
    this.destructive = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool visible;
  final bool destructive;
  final Color? color;
}

class UPopupMenu extends StatelessWidget {
  const UPopupMenu({
    required this.items,
    super.key,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  final List<UPopupMenuItem> items;
  final IconData icon;
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
