import "package:u/components/persian_date_picker.dart";
import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Cards, motion and read-more/scrolling text, credit-card UI, badges, icon rows
/// and the Jalali date picker.
class MiscPage extends StatelessWidget {
  const MiscPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GalleryPage(
      title: "Cards & misc",
      intro: "Flip cards, expandable and marquee text, a credit-card widget, notification badges, "
          "icon-text rows and the Jalali (Shamsi) date picker.",
      sections: <Widget>[
        DemoSection(
          title: "FlipCard",
          description: "Tap to flip between a front and back widget.",
          code: r'''FlipCard(front: frontWidget, back: backWidget);''',
          child: SizedBox(
            height: 120,
            child: FlipCard(
              front: _face(scheme.primaryContainer, scheme.onPrimaryContainer, "Front — tap me"),
              back: _face(scheme.tertiaryContainer, scheme.onTertiaryContainer, "Back!"),
            ),
          ),
        ),
        DemoSection(
          title: "CreditCardWidget",
          description: "An animated card that detects the brand from the number.",
          code: r'''
CreditCardWidget(
  cardNumber: "6274 1211 2233 4455",
  expiryDate: "08/29",
  cardHolderName: "SINA MN",
  cvvCode: "123",
  showBackView: false,
);''',
          child: const SizedBox(
            height: 200,
            child: CreditCardWidget(
              cardNumber: "6274 1211 2233 4455",
              expiryDate: "08/29",
              cardHolderName: "SINA MN",
              cvvCode: "123",
              showBackView: false,
            ),
          ),
        ),
        DemoSection(
          title: "ReadMoreText",
          description: "Collapse long text to N lines with a read-more / show-less toggle.",
          code: r'''ReadMoreText("A very long description…", trimLines: 2);''',
          child: const ReadMoreText(
            "The u plugin bundles a large, opinionated toolkit so that you can build a full app from a "
            "single import. This paragraph is intentionally long to show how ReadMoreText clamps text "
            "to a couple of lines and reveals the rest on demand.",
            trimLines: 2,
          ),
        ),
        DemoSection(
          title: "ScrollingText",
          description: "A marquee for text too long to fit on one line.",
          code: r'''ScrollingText(text: "Breaking news — this text scrolls horizontally …");''',
          child: const SizedBox(
            height: 24,
            child: ScrollingText(text: "Breaking news — this marquee text scrolls horizontally across the row."),
          ),
        ),
        DemoSection(
          title: "BadgeWidget",
          description: "Overlay a count or dot on any child.",
          code: r'''BadgeWidget(badgeContent: UTextLabelSmall("3"), child: Icon(Icons.notifications));''',
          child: BadgeWidget(
            badgeContent: const UTextLabelSmall("3"),
            child: Icon(Icons.notifications, color: scheme.onSurface),
          ),
        ),
        DemoSection(
          title: "UIconTextHorizontal / Vertical",
          description: "Pre-aligned icon + label rows and columns.",
          code: r'''UIconTextHorizontal(leading: Icon(Icons.place), trailing: UTextBodyMedium("Tehran"));''',
          child: URow(
            spacing: 24,
            children: <Widget>[
              UIconTextHorizontal(leading: Icon(Icons.place, color: scheme.primary), trailing: const UTextBodyMedium("Tehran")),
              UIconTextVertical(leading: Icon(Icons.favorite, color: scheme.error), trailing: const UTextLabelMedium("Liked")),
              UIconBackground(Icons.star, color: scheme.primary),
            ],
          ),
        ),
        DemoSection(
          title: "Jalali date picker",
          description: "A Shamsi calendar dialog; onDateSelected returns the chosen Jalali date.",
          code: r'''
showDialog(context: context, builder: (_) => JalaliDatePickerDialog(
  initialDate: Jalali.now(),
  onDateSelected: (Jalali d) => print(d),
));''',
          child: UButton(
            title: "Pick a Jalali date",
            icon: const Icon(Icons.calendar_month, size: 18),
            onTap: () => showDialog<void>(
              context: context,
              builder: (BuildContext _) => JalaliDatePickerDialog(
                initialDate: Jalali.fromDateTime(DateTime.now()),
                onDateSelected: (DateTime d, Jalali j) => UToast.success(message: j.formatFullDate()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _face(Color bg, Color fg, String label) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: UTextTitleMedium(label, color: fg, fontWeight: FontWeight.w700),
  );
}
