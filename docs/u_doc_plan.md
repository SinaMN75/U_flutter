# u_doc — PDF + EPUB engine for u_flutter

Decision (2026-09-10): replace `syncfusion_flutter_pdfviewer` with an in-house engine `u_doc` covering
PDF **and** EPUB, viewing **and** editing, on all 6 platforms (Android, iOS, macOS, Windows, Linux, Web).
Target quality is Acrobat-class. Target file size is **1 GB documents on a phone**.

Dropping `syncfusion_flutter_pdfviewer` (+ `syncfusion_pdf`, `syncfusion_flutter_core`) removes several MB
of pure-Dart code, so this engine ships **net smaller than what it replaces** and bundles **zero native libraries**.

## Core architecture decision

The page is rendered by a **pure-Dart PDF interpreter that draws into a Flutter `ui.Picture`**.
Native code bundles nothing and is used only for OCR and printing, which every OS provides for free.

Why not each platform's native PDF renderer (Android `PdfRenderer`, PDFKit, `Windows.Data.Pdf`, poppler, PDF.js):
- Windows and Android < 15 hand back pixels only — no text, no search, no forms — so the semantic layer has to be
  written in Dart anyway. Keeping the raster in Dart too removes the duplicate.
- Linux poppler is not guaranteed present; web needs an external PDF.js script.
- Output differs per platform. Same argument as rendering subtitles ourselves in u_media: Persian/RTL must be
  identical everywhere.
- Vector output means **zoom and rotate never re-rasterize** — they are GPU transforms on a retained `Picture`.
  On text-heavy documents this is faster than any raster pipeline after first paint.

An optional per-platform native raster fast path stays behind a capability flag for scanned/graphics-heavy pages,
added only if profiling asks for it.

## The 1 GB rule

Nothing ever holds a whole document. Every layer pulls bytes through `UDocByteSource`.

- `UDocByteSource` is random-access and lazy: `read(offset, length)`. Implementations: `RandomAccessFile`
  (mobile/desktop), memory, HTTP `Range` (open a remote 1 GB PDF without downloading it), and web `Blob.slice`.
- A block cache sits under it: fixed 64 KB blocks, LRU, **bounded in bytes not entries**.
- The xref is parsed lazily; objects are materialized on demand into a byte-bounded LRU object cache and evicted.
- Content streams are decoded per page and discarded after the `Picture` is built.
- Text extraction and the search index live on disk (JSONL, the same choice as `UMediaLibrary`), never in RAM.
- Saving is an **append-only incremental update**: writing to a 1 GB file appends a few KB, so saves are
  effectively instant regardless of document size. Full rewrite is a separate explicit "optimize" action.
- Page rasters, thumbnails and decoded images are three separate byte-bounded LRU caches with independent budgets.
- All parsing, text extraction and search run in isolates; the UI thread never blocks.

## Safety rules (carried over from u_media)

- Bounds-checked reads on every parse; a malformed or hostile PDF must fail with an exception, never a crash.
- Allocation caps on every declared length; a `/Length 4000000000` never becomes an allocation.
- Recursion depth limits on the page tree, object references, outlines and CSS.
- Cycle detection on indirect references and on the page/outline trees.
- No `dart:mirrors`, no code execution: PDF JavaScript is a formatting/calculation subset, never an interpreter.
- EPUB content is rendered by our own layout engine; no remote resource is fetched unless the caller opts in.

## File layout — deliberately consolidated

Same rule as u_media: this is an abstraction the app just consumes, so it lives in as few files as possible.
**Do not re-split it into a folder tree.**

### Dart
- `lib/doc/u_doc.dart` — shared streaming core. Enums, errors, `UDocByteSource` + block cache, byte-bounded LRU,
  isolate helpers, Persian/bidi/normalization utilities, on-disk index, `UDocLibrary`, `UDocController` base.
- `lib/doc/u_pdf.dart` — the whole PDF engine. Lexer, object model, xref, filters, encryption, page tree, fonts,
  content-stream interpreter, renderer, text layer, annotations, forms, outline, writer and editing operations.
- `lib/doc/u_epub.dart` — the whole EPUB engine. Streaming ZIP, OCF/OPF/NCX/NavDoc, font de-obfuscation,
  CSS parser and cascade, box layout, pagination, fixed layout, CFI, authoring.
- `lib/doc/u_doc_web.dart` — web-only implementations (`Blob.slice` source, `DecompressionStream` inflate, print).
- `lib/components/u_pdf_viewer.dart` — all PDF UI.
- `lib/components/u_epub_reader.dart` — all EPUB UI.

### Native (OCR + print only, nothing bundled)
- Android: ML Kit on-device text recognition via Play Services module (no APK growth) + `PrintManager`.
- iOS/macOS: Vision `VNRecognizeTextRequest` + `UIPrintInteractionController` / `NSPrintOperation`.
- Windows: `Windows.Media.Ocr` + the Win32 print dialog.
- Linux: `libtesseract` via `dlopen`, capability-flagged off when absent; printing via GTK.
- Web: `window.print()`; OCR reports `available: false` rather than faking it.

## Persian / RTL

- Bidi-correct selection: visual runs map back to logical order before copy.
- Search normalizes Arabic presentation forms (U+FB50–FDFF), ZWNJ, kashida, Persian vs Arabic ye/kaf,
  and Persian/Arabic/Latin digits.
- `Cp1256` fallback decoding reuses the existing codec in `lib/iso8583/cp1256.dart`.
- Recovery for missing or broken `/ToUnicode` in Persian PDFs from old Word/InDesign.
- RTL page progression and mirrored viewer chrome for both PDF and EPUB.

## Phases

1. `lib/doc/u_doc.dart` — streaming core.
2. PDF object layer: lexer, xref, object streams, filters, encryption, page tree.
3. PDF fonts + content-stream interpreter + renderer.
4. PDF text layer, search, selection, RTL.
5. PDF writer + editing operations.
6. PDF viewer/editor UI.
7. EPUB engine.
8. EPUB reader UI.
9. Native OCR + print.
10. l10n, exports, remove syncfusion.
11. Verification.

Every user-visible string gets a key in `lib/l10n/intl_en.arb` and `lib/l10n/intl_fa.arb`,
keyed by the camelCase of the English value.
