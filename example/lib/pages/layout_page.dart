import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the layout primitives: UColumn/URow (Column/Row with spacing,
/// padding and decoration built in), UCard, UGlassCard, UHeaderCard, UListTile
/// and UEmptyState.
class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
      title: "Layout",
      intro: "UColumn and URow are Column/Row with spacing, padding, and container decoration "
          "folded in, so you rarely need to nest Padding + Container by hand.",
      sections: <Widget>[
        DemoSection(
          title: "URow with spacing",
          description: "spacing replaces manual SizedBox separators between children.",
          code: r'''
URow(
  spacing: 12,
  children: <Widget>[Icon(Icons.star), UTextBodyMedium("Rated"), Spacer(), UTextLabelLarge("4.8")],
);''',
          child: URow(
            spacing: 12,
            children: <Widget>[
              Icon(Icons.star, color: scheme.primary),
              const UTextBodyMedium("Rated"),
              const Spacer(),
              const UTextLabelLarge("4.8"),
            ],
          ),
        ),
        DemoSection(
          title: "UGlassCard & UHeaderCard",
          description: "A frosted-glass surface and a ready-made icon + title + subtitle header.",
          code: r'''
UGlassCard(child: UTextBodyMedium("Frosted content"));
UHeaderCard(icon: Icons.bolt, title: "Fast", subtitle: "Sub-second cold start");''',
          child: UColumn(
            spacing: 12,
            children: <Widget>[
              UGlassCard(
                child: const UTextBodyMedium("Frosted content over the theme surface").pAll(16),
              ),
              const UHeaderCard(
                icon: Icons.bolt,
                title: "Fast",
                subtitle: "Sub-second cold start",
              ),
            ],
          ),
        ),
        DemoSection(
          title: "UListTile",
          description: "A compact, tappable list row with an icon, title and optional subtitle.",
          code: r'''
UListTile(
  icon: Icons.person,
  title: "Profile",
  subtitle: "View and edit your details",
  onTap: () {},
);''',
          child: UColumn(
            spacing: 4,
            children: <Widget>[
              UListTile(icon: Icons.person, title: "Profile", subtitle: "View and edit your details", onTap: () {}),
              UListTile(icon: Icons.settings, title: "Settings", onTap: () {}),
            ],
          ),
        ),
        DemoSection(
          title: "UEmptyState",
          description: "A centered placeholder for empty lists and zero-result screens.",
          code: r'''UEmptyState(title: "Nothing here yet");''',
          child: const SizedBox(height: 160, child: UEmptyState(title: "Nothing here yet")),
        ),
      ],
    );
  }
}
