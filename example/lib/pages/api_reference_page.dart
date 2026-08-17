import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Reference page for the API layer. These calls hit the SinaMN75 backend, so
/// they are shown as code rather than run live — set U.baseUrl / U.apiKey first.
class ApiReferencePage extends StatelessWidget {
  const ApiReferencePage({super.key});

  static const List<String> _areas = <String>[
    "auth", "user", "product", "content", "category", "comment", "follow",
    "media", "wallet", "ipg", "txn", "merchant", "terminal", "bankAccount",
    "moadi", "inquiry", "chargeInternet", "sim", "vehicle", "parking",
    "hotel", "ticket", "notification", "pn", "blog", "address", "accounting",
    "appSettings", "dashboard", "process", "fileManager",
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
      title: "API services",
      intro: "Every network call goes through UServices.<area>.<method>(p:, onOk:, onError:, "
          "onException:). Configure U.baseUrl and U.apiKey once at startup; tokens and refresh "
          "are handled for you.",
      sections: <Widget>[
        DemoSection(
          title: "Setup",
          description: "Point the client at your backend before any call.",
          code: r'''
void main() {
  U.baseUrl = "https://api.example.com";
  U.apiKey = "YOUR_API_KEY";
  runApp(const MyApp());
}''',
          child: const UTextBodySmall("One-time configuration in main()."),
        ),
        DemoSection(
          title: "A typical call",
          description: "The callbacks split success, server error, and transport exception.",
          code: r'''
await UServices.auth.login(
  p: ULoginParams(email: email, password: password),
  onOk: (UResponse<ULoginResponse> r) => UNavigator.push(const HomePage()),
  onError: (UEmptyResponse e) => UToast.error(message: e.message ?? "Login failed"),
  onException: (String e) => UToast.error(message: e),
);''',
          child: const UTextBodySmall("Same shape for every service and method."),
        ),
        DemoSection(
          title: "Available services",
          description: "31 service areas exposed on UServices, each with matching *Params/*Response models.",
          code: null,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _areas
                .map((String a) => Chip(
                      label: UTextLabelSmall("UServices.$a", fontFamily: "monospace", color: scheme.onSecondaryContainer),
                      backgroundColor: scheme.secondaryContainer,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
