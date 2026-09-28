import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("extracts logical Persian text with usable geometry from a real PDF", () async {
    final Uint8List bytes = File("example/assets/docs/sample_fa_en.pdf").readAsBytesSync();
    final UPdfDocument document = await UPdfDocument.open(bytes: bytes);
    expect(document.pageCount, 4);
    final UPdfPageRenderer renderer = UPdfPageRenderer(document);

    final UDocTextPage first = await renderer.extractText((await document.page(0))!);
    // Print the first lines for manual inspection of the reading order.
    for (final UDocTextRun run in first.runs.take(6)) {
      // ignore: avoid_print
      print("${run.rtl ? "RTL" : "LTR"} reliable=${run.reliable} | ${run.text}");
    }
    expect(first.text, contains("راهنمای نمونه"));
    // Vazir's ToUnicode maps its digit glyphs to ASCII digits; search normalises both forms.
    expect(first.locate("۱۴۰۳"), isNotNull);
    expect(first.text, contains("«u_flutter version 3.0»"));
    expect(first.text, contains("بخش ۱: انتخاب و هایلایت متن"));
    expect(first.text, contains("می‌دهد"));
    expect(first.text, contains("2024"));
    expect(first.reliability, greaterThan(0.8));

    final (int, int)? word = first.locate("هایلایت");
    expect(word, isNotNull);
    final List<Rect> rects = first.rectsForRange(word!.$1, word.$2);
    expect(rects, isNotEmpty);
    // A single word must produce a tight box, not a whole line.
    final UDocTextRun line = first.runs.firstWhere((UDocTextRun run) => run.text.contains("هایلایت"));
    expect(rects.first.width, lessThan(line.rect.width * 0.5));

    final UDocTextPage second = await renderer.extractText((await document.page(1))!);
    expect(second.text, contains("Two columns"));
    expect(second.text, contains("library"));
    expect(second.text, contains("کتابخانه"));
    await document.close();
  });
}
