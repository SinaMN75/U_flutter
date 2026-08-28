import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the Widget extension methods that let you compose layouts
/// fluently: .pAll(), .onTap(), .rtl(), .card(), .rotate(), .expanded() …
class ExtensionsPage extends StatelessWidget {
  const ExtensionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget box = UContainer(color: scheme.primaryContainer, radius: 8, width: 90, height: 60, alignment: Alignment.center, child: const UTextLabelLarge("box"));

    return GalleryPage(
      title: "Extensions",
      intro:
          "Every Widget gains chainable helpers, so `child.pAll(16).onTap(...)` replaces nested "
          "Padding + GestureDetector. String, num and Iterable get similar sugar.",
      sections: <Widget>[
        DemoSection(
          title: ".pAll() / .onTap()",
          description: "Pad any widget and make it tappable inline. Tap the box.",
          code: r'''box.pAll(16).onTap(() => UToast.info(message: "Tapped"));''',
          child: box.pAll(16).onTap(() => UToast.info(message: "Tapped")),
        ),
        DemoSection(
          title: ".card() / .container()",
          description: "Wrap a widget in a themed card or a decorated container with one call.",
          code: r'''child.card(elevation: 3);''',
          child: const UTextBodyMedium("I live inside a card", margin: EdgeInsets.all(16)).card(),
        ),
        DemoSection(
          title: ".rotate() / .scale()",
          description: "Quick transforms without a Transform widget.",
          code: r'''box.rotate(0.15); box.scale(1.2);''',
          child: URow(spacing: 24, children: <Widget>[box.rotate(0.15), box.scale(1.2)]),
        ),
        DemoSection(
          title: ".rtl()",
          description: "Force right-to-left direction for a subtree — useful for Persian content.",
          code: r'''
URow(children: <Widget>[Icon(Icons.arrow_back), UTextBodyMedium("راست به چپ")]).rtl();''',
          child: URow(spacing: 8, children: <Widget>[const Icon(Icons.arrow_back), const UTextBodyMedium("راست به چپ")]).rtl(),
        ),
        DemoSection(
          title: "Iterable & String extensions",
          description: "mapIndexed, firstOrDefault, isNullOrEmpty, and String parsing helpers.",
          code: r'''
<String>["a", "b"].mapIndexed((int i, String s) => "$i:$s");   // (0:a, 1:b)
<int>[].firstOrDefault(defaultValue: -1);                       // -1
"42".toInt();  "3.14".toDouble();  "true".isTrue();             // parsing
"".isNullOrEmpty();                                             // true''',
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: <Widget>[
              DemoLabel('["a","b"].mapIndexed → ${<String>["a", "b"].mapIndexed((int i, String s) => "$i:$s").toList()}'),
              DemoLabel('"42".toInt() + 8 = ${"42".toInt() + 8}'),
              DemoLabel('"".isNullOrEmpty() = ${"".isNullOrEmpty()}'),
            ],
          ),
        ),
      ],
    );
  }
}
