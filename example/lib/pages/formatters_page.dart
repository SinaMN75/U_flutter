import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

/// Demonstrates the number, money, date and Persian/Latin digit extensions that
/// hang off int, double, String and DateTime.
class FormattersPage extends StatelessWidget {
  const FormattersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return GalleryPage(
      title: "Formatters",
      intro: "Money, compact and grouped number formatting, Jalali dates and Persian digits are "
          "all extension methods — call them directly on the value.",
      sections: <Widget>[
        _row("Money — rial()", "1500000.rial()", 1500000.rial()),
        _row("Money — toman()", "1500000.toman()", 1500000.toman()),
        _row("Grouped — separate3By3()", "1234567.separate3By3()", 1234567.separate3By3()),
        _row("Compact — toKMB()", "1250000.toKMB()", 1250000.toKMB()),
        _row("Persian digits", '"2026-08-01".toPersianNumber()', "2026-08-01".toPersianNumber()),
        _row("Grouped string", '"1234567".separateNumbers3By3()', "1234567".separateNumbers3By3()),
        _row("Jalali date", "DateTime.now().toJalaliDate()", now.toJalaliDate()),
        _row("Time ago", "now.toTimeAgo()", now.subtract(const Duration(hours: 3)).toTimeAgo()),
      ],
    );
  }

  DemoSection _row(String title, String code, String result) => DemoSection(
    title: title,
    description: "Input → formatted output.",
    code: code,
    child: UCard(
      color: null,
      child: URow(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        margin: const EdgeInsets.all(14),
        children: <Widget>[
          const UTextLabelMedium("Result"),
          UTextTitleMedium(result, fontWeight: FontWeight.w700),
        ],
      ),
    ),
  );
}
