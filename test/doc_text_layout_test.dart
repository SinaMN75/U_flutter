import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

/// Builds glyphs laid out left-to-right (visual order), 10pt wide, 12pt tall.
List<UPdfPositionedGlyph> _visual(List<String> texts, {double width = 10, double y = 100}) {
  final List<UPdfPositionedGlyph> glyphs = <UPdfPositionedGlyph>[];
  double x = 20;
  for (final String text in texts) {
    glyphs.add(UPdfPositionedGlyph(text: text, rect: Rect.fromLTWH(x, y, width, 12), fontSize: 12, isSpace: text == " "));
    x += width;
  }
  return glyphs;
}

void main() {
  group("UPdfTextLayout", () {
    test("recovers Persian logical order and keeps numbers left-to-right", () {
      // Visual order of "سلام دنیا ۱۲۳" as drawn on the page.
      final List<String> visual = <String>["۱", "۲", "۳", " ", "ا", "ی", "ن", "د", " ", "م", "ا", "ل", "س"];
      final UDocTextPage page = UPdfTextLayout.build(0, const Size(600, 800), _visual(visual));
      expect(page.runs, hasLength(1));
      final UDocTextRun run = page.runs.single;
      expect(run.rtl, isTrue);
      expect(run.text, "سلام دنیا ۱۲۳");
      expect(run.reliable, isTrue);
      expect(run.charRects, hasLength(run.text.length));
      // "س" is the first logical char and the right-most glyph.
      expect(run.charRects.first.left, 20 + 12 * 10);
      // "دنیا" = offsets 5..9 → the four middle glyphs (visual 4..7).
      final List<Rect> rects = page.rectsForRange(5, 9);
      expect(rects, hasLength(1));
      expect(rects.single.left, 20 + 4 * 10);
      expect(rects.single.right, 20 + 8 * 10);
    });

    test("unfolds presentation forms without breaking char geometry", () {
      // "ﻻ" (lam-alef ligature, FEFB) is one glyph for two logical letters.
      final UDocTextPage page = UPdfTextLayout.build(0, const Size(600, 800), _visual(<String>["ﻻ", "ﺱ"]));
      final UDocTextRun run = page.runs.single;
      expect(run.text, "سلا");
      expect(run.charRects, hasLength(3));
      expect(run.charRects[1].right <= run.charRects[0].left + 0.001, isTrue);
    });

    test("keeps an LTR paragraph with an embedded Persian word readable", () {
      final List<String> visual = <String>["H", "i", " ", "م", "ا", "ل", "س", " ", "y", "o"];
      final UDocTextRun run = UPdfTextLayout.build(0, const Size(600, 800), _visual(visual)).runs.single;
      expect(run.rtl, isFalse);
      expect(run.text, "Hi سلام yo");
    });

    test("falls back to the whole line box when glyph widths are broken", () {
      final List<UPdfPositionedGlyph> glyphs = _visual(<String>["م", "ا", "ل", "س", "ی", "ک"], width: 0.2);
      final UDocTextPage page = UPdfTextLayout.build(0, const Size(600, 800), glyphs);
      final UDocTextRun run = page.runs.single;
      expect(run.reliable, isFalse);
      expect(page.rectsForRange(1, 3), <Rect>[run.rect]);
      expect(page.rectsForRange(1, 3, geometry: UDocTextGeometry.precise), isNot(<Rect>[run.rect]));
    });

    test("splits side-by-side columns into separate runs", () {
      final List<UPdfPositionedGlyph> left = _visual(<String>["a", "b"]);
      final List<UPdfPositionedGlyph> right = <UPdfPositionedGlyph>[
        const UPdfPositionedGlyph(text: "c", rect: Rect.fromLTWH(300, 100, 10, 12)),
        const UPdfPositionedGlyph(text: "d", rect: Rect.fromLTWH(310, 100, 10, 12)),
      ];
      final UDocTextPage page = UPdfTextLayout.build(0, const Size(600, 800), <UPdfPositionedGlyph>[...left, ...right]);
      expect(page.runs.map((UDocTextRun run) => run.text).toList(), <String>["ab", "cd"]);
    });

    test("maps a point back to the logical offset", () {
      final List<String> visual = <String>["م", "ا", "ل", "س"];
      final UDocTextPage page = UPdfTextLayout.build(0, const Size(600, 800), _visual(visual));
      // Right-most glyph is "س" = offset 0.
      expect(page.offsetAt(const Offset(55, 106)), 0);
      expect(page.offsetAt(const Offset(25, 106)), 3);
      expect(page.wordAround(1), (0, 4));
    });
  });

  group("UDocAnnotationController", () {
    test("round-trips through export/import", () {
      final UDocAnnotationController source = UDocAnnotationController();
      source.add(UDocMarkup.create(kind: UDocMarkupKind.squiggly, pageIndex: 3, color: const Color(0xFF4FC3F7), text: "سلام", rects: const <Rect>[Rect.fromLTRB(0.1, 0.2, 0.3, 0.25)], note: "یادداشت"));
      source.toggleBookmark(7, title: "Chapter 2");
      final UDocAnnotationController target = UDocAnnotationController(initialData: source.export());
      expect(target.markups, hasLength(1));
      expect(target.markups.single.kind, UDocMarkupKind.squiggly);
      expect(target.markups.single.note, "یادداشت");
      expect(target.markups.single.rects.single.left, closeTo(0.1, 1e-6));
      expect(target.isBookmarked(7), isTrue);
      expect(target.markupsOn(3), hasLength(1));
    });

    test("imports the legacy SinApp payload", () {
      const String legacy = '{"markers":[{"pageNumber":2,"color":4294198070,"range":{"pageNumber":2,"text":"hello","start":4,"end":9},"type":"border","text":"note"}],"pageMarks":[1,5]}';
      final UDocAnnotationController controller = UDocAnnotationController(initialData: legacy.toBase64());
      final UDocMarkup markup = controller.markups.single;
      expect(markup.pageIndex, 1);
      expect(markup.kind, UDocMarkupKind.border);
      expect(markup.isPlaced, isFalse);
      expect(markup.text, "hello");
      expect(controller.bookmarks.map((UDocBookmark bookmark) => bookmark.pageIndex).toList(), <int>[0, 4]);
    });

    test("undo and redo restore state", () {
      final UDocAnnotationController controller = UDocAnnotationController();
      final UDocMarkup markup = controller.add(UDocMarkup.create(kind: UDocMarkupKind.highlight, pageIndex: 0, color: const Color(0xFFFFEB3B)));
      controller.remove(markup.id);
      expect(controller.markups, isEmpty);
      controller.undo();
      expect(controller.markups, hasLength(1));
      controller.redo();
      expect(controller.markups, isEmpty);
    });

    test("picks the newest of two payloads", () {
      final UDocAnnotationController a = UDocAnnotationController();
      a.add(UDocMarkup.create(kind: UDocMarkupKind.highlight, pageIndex: 0, color: const Color(0xFFFFEB3B)));
      final String older = a.export();
      a.add(UDocMarkup.create(kind: UDocMarkupKind.underline, pageIndex: 1, color: const Color(0xFFFFEB3B)));
      final String newer = a.export();
      expect(UDocAnnotationController.pickNewest(older, newer), newer);
      expect(UDocAnnotationController.pickNewest(newer, older), newer);
    });
  });
}
