import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Reference page for the bundled `u_admin` panel — a full GetX admin suite for
/// the SinaMN75 backend. It needs U.baseUrl / U.apiKey and a signed-in admin,
/// so it is documented here rather than launched inside the gallery.
class AdminReferencePage extends StatelessWidget {
  const AdminReferencePage({super.key});

  static const List<String> _modules = <String>[
    "Login & splash", "Financial ops dashboard", "Blog", "Contents (CMS)",
    "Crypto", "File manager", "Hotel & dorm suite", "Parking",
    "Payments — merchants / terminals / moadi", "Users", "Wallet", "Logs",
    "Push notifications", "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
      title: "Admin panel (u_admin)",
      intro: "The plugin ships a complete admin panel. Reuse these pages instead of rebuilding "
          "admin screens — they are exported from package:u and wired to UServices.",
      sections: <Widget>[
        DemoSection(
          title: "Launching the panel",
          description: "Configure the backend, then push the admin splash/login page.",
          code: r'''
U.baseUrl = "https://api.example.com";
U.apiKey = "YOUR_API_KEY";
UNavigator.push(const UAdminSplashPage());''',
          child: const UTextBodySmall("Entry points: UAdminSplashPage, UAdminLoginPage."),
        ),
        DemoSection(
          title: "Included modules",
          description: "Each module is a ready-made page backed by the matching UServices area.",
          code: null,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: _modules
                .map((String m) => URow(
                      spacing: 8,
                      children: <Widget>[
                        Icon(Icons.check_circle, size: 18, color: scheme.primary),
                        Expanded(child: UTextBodyMedium(m)),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
