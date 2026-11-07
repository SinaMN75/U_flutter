---
title: Markdown sample / نمونه‌ی مارک‌داون
author: u
---
# Markdown reader

Everything the **PDF** and *EPUB* readers do works here too: select text to ==highlight==, ~~strike~~, underline or add a note, bookmark a position, draw with ✎, search, and switch fonts and themes.

Links: [Flutter](https://flutter.dev), <https://dart.dev>, [jump to the table](#tables) and a footnote[^1].

## Lists

- Plain item with `inline code`
- [x] Finished task
- [ ] Open task
  1. Nested numbered
  2. Second
     - deeper bullet

## Quote

> A quote can hold **formatting**
> > and be nested.

## Tables

| Feature | PDF | Markdown |
|:--------|:---:|---------:|
| Highlights | ✓ | ✓ |
| Editing | annotations | full source |
| Export | PDF | MD · HTML · TXT |

## Code

```dart
// Open any Markdown source
final UMarkdownReader reader = UMarkdownReader(asset: "assets/docs/sample.md");
int answer = 42;
```

---

## فارسی

این یک **متن فارسی** است که از راست به چپ نمایش داده می‌شود. می‌توانید روی آن *هایلایت* بگذارید یا یادداشت بنویسید.

1. مورد اول
2. مورد دوم

[^1]: Footnotes jump here and are listed at the end.
