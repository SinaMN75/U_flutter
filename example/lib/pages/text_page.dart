import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the `UText*` family — one widget per Material 3 type-scale role.
/// Always prefer these over a raw `Text`: the string is the first positional
/// argument and every style property is an optional named argument.
class TextPage extends StatelessWidget {
  const TextPage({super.key});

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Text",
    intro: "UText* wraps Theme.of(context).textTheme so text is themed and consistent. "
        "The text is positional; color, weight, alignment, maxLines, decoration and more are named.",
    sections: <Widget>[
      DemoSection(
        title: "The type scale",
        description: "Every Material role has a matching widget, from display down to label.",
        code: r'''
UTextDisplaySmall("Display small");
UTextHeadlineMedium("Headline medium");
UTextTitleLarge("Title large", fontWeight: FontWeight.w700);
UTextBodyMedium("Body medium");
UTextLabelLarge("LABEL LARGE");''',
        child: const UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            UTextDisplaySmall("Display small"),
            UTextHeadlineMedium("Headline medium"),
            UTextTitleLarge("Title large", fontWeight: FontWeight.w700),
            UTextBodyMedium("Body medium — the default reading size."),
            UTextLabelLarge("LABEL LARGE"),
          ],
        ),
      ),
      DemoSection(
        title: "Styling props",
        description: "Color, weight, letterSpacing, decoration and overflow are all named args.",
        code: r'''
UTextTitleMedium(
  "Themed, bold, underlined",
  color: Theme.of(context).colorScheme.primary,
  fontWeight: FontWeight.w800,
  decoration: TextDecoration.underline,
);''',
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: <Widget>[
            UTextTitleMedium(
              "Themed, bold, underlined",
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
            const UTextBodyMedium(
              "A long paragraph that is clamped to a single line so you can see how "
              "maxLines and overflow cooperate to keep layouts tidy.",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      DemoSection(
        title: "UAnimatedCounter",
        description: "Tweens from 0 to the target value; the builder renders each frame's value.",
        code: r'''
UAnimatedCounter(
  value: 1280,
  builder: (BuildContext context, double v) =>
      UTextHeadlineMedium(v.toInt().separate3By3(), fontWeight: FontWeight.w700),
);''',
        child: UAnimatedCounter(
          value: 1280,
          builder: (BuildContext context, double v) =>
              UTextHeadlineMedium(v.toInt().separate3By3(), fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}
