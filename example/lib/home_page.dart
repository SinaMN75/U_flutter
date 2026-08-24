import "package:u/utilities.dart";

import "pages/admin_reference_page.dart";
import "pages/advanced_page.dart";
import "pages/api_reference_page.dart";
import "pages/buttons_page.dart";
import "pages/extensions_page.dart";
import "pages/feedback_page.dart";
import "pages/formatters_page.dart";
import "pages/inputs_page.dart";
import "pages/layout_page.dart";
import "pages/media_page.dart";
import "pages/misc_page.dart";
import "pages/navigation_page.dart";
import "pages/screen_guard_page.dart";
import "pages/text_page.dart";
import "pages/utils_page.dart";

/// One tappable card on the gallery home grid.
class GalleryEntry {
  const GalleryEntry({required this.title, required this.subtitle, required this.icon, required this.builder});

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function() builder;
}

final List<GalleryEntry> kEntries = <GalleryEntry>[
  GalleryEntry(title: "Text", subtitle: "UText* type scale", icon: Icons.title, builder: () => const TextPage()),
  GalleryEntry(title: "Buttons", subtitle: "UButton & variants", icon: Icons.smart_button, builder: () => const ButtonsPage()),
  GalleryEntry(title: "Inputs", subtitle: "Fields, OTP, validators", icon: Icons.edit_note, builder: () => const InputsPage()),
  GalleryEntry(title: "Layout", subtitle: "Scaffold, cards, lists", icon: Icons.dashboard, builder: () => const LayoutPage()),
  GalleryEntry(title: "Navigation", subtitle: "Tab bar & side menu", icon: Icons.menu_open, builder: () => const NavigationPage()),
  GalleryEntry(title: "Feedback", subtitle: "Toast, dialogs, progress", icon: Icons.notifications_active, builder: () => const FeedbackPage()),
  GalleryEntry(title: "Media & files", subtitle: "Images, QR, web, files", icon: Icons.perm_media, builder: () => const MediaPage()),
  GalleryEntry(title: "Cards & misc", subtitle: "Flip, credit card, badges", icon: Icons.style, builder: () => const MiscPage()),
  GalleryEntry(title: "Advanced forms", subtitle: "Rich text, signature, process", icon: Icons.edit_document, builder: () => const AdvancedPage()),
  GalleryEntry(title: "Utilities", subtitle: "Crypto, Persian, storage", icon: Icons.handyman, builder: () => const UtilsPage()),
  GalleryEntry(title: "Formatters", subtitle: "Money, numbers, Jalali", icon: Icons.calculate, builder: () => const FormattersPage()),
  GalleryEntry(title: "Extensions", subtitle: "Widget & value sugar", icon: Icons.extension, builder: () => const ExtensionsPage()),
  GalleryEntry(title: "ScreenGuard", subtitle: "Native capture block", icon: Icons.screenshot_monitor, builder: () => const ScreenGuardPage()),
  GalleryEntry(title: "API services", subtitle: "UServices reference", icon: Icons.cloud, builder: () => const ApiReferencePage()),
  GalleryEntry(title: "Admin panel", subtitle: "u_admin reference", icon: Icons.admin_panel_settings, builder: () => const AdminReferencePage()),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: const UTextTitleLarge("u plugin gallery", fontWeight: FontWeight.w700), centerTitle: false),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.15),
        itemCount: kEntries.length,
        itemBuilder: (BuildContext context, int index) {
          final GalleryEntry e = kEntries[index];
          return UCard(
            child: UColumn(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                UContainer(
                  color: scheme.primaryContainer,
                  radius: 12,
                  padding: const EdgeInsets.all(10),
                  child: Icon(e.icon, color: scheme.onPrimaryContainer),
                ),
                const Spacer(),
                UTextTitleSmall(e.title, fontWeight: FontWeight.w700),
                UTextBodySmall(e.subtitle, color: scheme.onSurfaceVariant, maxLines: 2),
              ],
            ),
          ).onPress(() => UNavigator.push<void>(e.builder()));
        },
      ),
    );
  }
}
