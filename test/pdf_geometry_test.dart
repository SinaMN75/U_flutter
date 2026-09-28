import "dart:ui" as ui;

import "package:flutter_test/flutter_test.dart";
import "package:u/utilities.dart";

/// Text boxes must cover the ink they describe, otherwise selections and
/// highlights float above/below the words (regression: positive Descent in
/// Chrome-generated Persian PDFs put every box above the line).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("text boxes cover the rendered glyphs", (WidgetTester tester) async {
    await tester.runAsync(() async {
      final UPdfDocument document = await UPdfDocument.open(bytes: File("example/assets/docs/sample_fa_en.pdf").readAsBytesSync());
      for (int pageIndex = 0; pageIndex < 2; pageIndex++) {
        final UPdfPage page = (await document.page(pageIndex))!;
        final UPdfRenderResult result = await UPdfPageRenderer(document).render(page);
        final int width = result.deviceSize.width.round();
        final int height = result.deviceSize.height.round();
        final ui.Image image = await result.picture!.toImage(width, height);
        final ByteData pixels = (await image.toByteData())!;
        bool dark(int x, int y) {
          if (x < 0 || y < 0 || x >= width || y >= height) return false;
          final int offset = (y * width + x) * 4;
          return pixels.getUint8(offset) + pixels.getUint8(offset + 1) + pixels.getUint8(offset + 2) < 380;
        }

        int checked = 0;
        for (final UDocTextRun run in result.text.runs) {
          final Rect box = run.rect;
          if (box.width < 40 || box.height < 4) continue;
          int inside = 0;
          int around = 0;
          // Only the band up to halfway to the neighbouring lines, so their ink doesn't count.
          double above = box.top - box.height * 0.6;
          double below = box.bottom + box.height * 0.6;
          for (final UDocTextRun other in result.text.runs) {
            if (identical(other, run) || other.rect.right < box.left || other.rect.left > box.right) continue;
            if (other.rect.bottom <= box.top + 1) above = max(above, (other.rect.bottom + box.top) / 2);
            if (other.rect.top >= box.bottom - 1) below = min(below, (other.rect.top + box.bottom) / 2);
          }
          final int top = above.floor();
          final int bottom = below.ceil();
          for (int y = top; y <= bottom; y++) {
            for (int x = box.left.floor(); x <= box.right.ceil(); x += 2) {
              if (!dark(x, y)) continue;
              around++;
              if (y >= box.top - 1 && y <= box.bottom + 1) inside++;
            }
          }
          if (around < 20) continue;
          checked++;
          expect(inside / around, greaterThan(0.85), reason: "page $pageIndex line \"${run.text}\" box=$box covers ${(inside * 100 / around).round()}%");
        }
        expect(checked, greaterThan(5));
      }
      await document.close();
    });
  });
}
