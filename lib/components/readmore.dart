import "package:u/utilities.dart";

/// Cut by characters (length) or by lines.
enum UTrimMode {
  length,
  line,
}

/// Long text that shows "Read more / Show less" and supports links. `UReadMoreText(longText, trimLines: 3)`
class UReadMoreText extends StatefulWidget {
  const UReadMoreText(
    this.data, {
    super.key,
    this.preDataText,
    this.postDataText,
    this.preDataTextStyle,
    this.postDataTextStyle,
    this.trimExpandedText = "show less",
    this.trimCollapsedText = "read more",
    this.colorClickableText,
    this.trimLength = 240,
    this.trimLines = 2,
    this.trimMode = UTrimMode.length,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.textScaleFactor,
    this.semanticsLabel,
    this.moreStyle,
    this.lessStyle,
    this.delimiter = "$_kEllipsis ",
    this.delimiterStyle,
    this.callback,
    this.onLinkPressed,
    this.linkTextStyle,
  });

  /// Characters shown when trimming by length.
  final int trimLength;

  /// Lines shown when trimming by lines.
  final int trimLines;

  /// Trim by length or lines.
  final UTrimMode trimMode;

  /// Style of "Read more".
  final TextStyle? moreStyle;

  /// Style of "Show less".
  final TextStyle? lessStyle;

  /// Text before the content (e.g. a username).
  final String? preDataText;

  /// Text after the content.
  final String? postDataText;

  /// Style of preDataText.
  final TextStyle? preDataTextStyle;

  /// Style of postDataText.
  final TextStyle? postDataTextStyle;

  /// Called with true when collapsed, false when expanded.
  final Function(bool val)? callback;

  /// Called with a tapped URL (links are detected).
  final ValueChanged<String>? onLinkPressed;

  /// Link style.
  final TextStyle? linkTextStyle;

  /// Text before "Read more", e.g. "… ".
  final String delimiter;

  /// The data to show.
  final String data;

  /// "Show less" text.
  final String trimExpandedText;

  /// "Read more" text.
  final String trimCollapsedText;

  /// Color of read more/less.
  final Color? colorClickableText;

  /// Text style (defaults to the theme).
  final TextStyle? style;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Text direction (RTL/LTR); defaults to the app's.
  final TextDirection? textDirection;

  /// Locale for measuring text.
  final Locale? locale;

  /// Text scale for measuring.
  final double? textScaleFactor;

  /// Label read by screen readers.
  final String? semanticsLabel;

  /// Style of the delimiter.
  final TextStyle? delimiterStyle;

  @override
  UReadMoreTextState createState() => UReadMoreTextState();
}

const String _kEllipsis = "\u2026";

const String _kLineSeparator = "\u2028";

/// State of UReadMoreText.
class UReadMoreTextState extends State<UReadMoreText> {
  bool _readMore = true;

  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  static final RegExp _urlExp = RegExp(r"(?:(?:https?|ftp)://)?[\w/\-?=%.]+\.[\w/\-?=%.]+");

  TapGestureRecognizer _tap(GestureTapCallback onTap) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(recognizer);
    return recognizer;
  }

  void _disposeRecognizers() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _onTapLink() {
    setState(() {
      _readMore = !_readMore;
      widget.callback?.call(_readMore);
    });
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveTextStyle = widget.style;
    if (widget.style?.inherit ?? false) {
      effectiveTextStyle = defaultTextStyle.style.merge(widget.style);
    }

    final TextAlign textAlign = widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    final TextDirection textDirection = widget.textDirection ?? Directionality.of(context);
    final TextOverflow overflow = defaultTextStyle.overflow;
    final Locale? locale = widget.locale ?? Localizations.maybeLocaleOf(context);

    final Color colorClickableText = widget.colorClickableText ?? Theme.of(context).colorScheme.secondary;
    final TextStyle? defaultLessStyle = widget.lessStyle ?? effectiveTextStyle?.copyWith(color: colorClickableText);
    final TextStyle? defaultMoreStyle = widget.moreStyle ?? effectiveTextStyle?.copyWith(color: colorClickableText);
    final TextStyle? defaultDelimiterStyle = widget.delimiterStyle ?? effectiveTextStyle;

    final TextSpan link = TextSpan(
      text: _readMore ? widget.trimCollapsedText : widget.trimExpandedText,
      style: _readMore ? defaultMoreStyle : defaultLessStyle,
      recognizer: _tap(_onTapLink),
    );

    final TextSpan delimiter = TextSpan(
      text: _readMore
          ? widget.trimCollapsedText.isNotEmpty
                ? widget.delimiter
                : ""
          : "",
      style: defaultDelimiterStyle,
      recognizer: _tap(_onTapLink),
    );

    Widget result = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(constraints.hasBoundedWidth);
        final double maxWidth = constraints.maxWidth;

        TextSpan? preTextSpan;
        TextSpan? postTextSpan;
        if (widget.preDataText != null) {
          preTextSpan = TextSpan(
            text: "${widget.preDataText!} ",
            style: widget.preDataTextStyle ?? effectiveTextStyle,
          );
        }
        if (widget.postDataText != null) {
          postTextSpan = TextSpan(
            text: " ${widget.postDataText!}",
            style: widget.postDataTextStyle ?? effectiveTextStyle,
          );
        }
        final TextSpan text = TextSpan(
          children: <InlineSpan>[
            ?preTextSpan,
            TextSpan(text: widget.data, style: effectiveTextStyle),
            ?postTextSpan,
          ],
        );
        final TextPainter textPainter = TextPainter(
          text: link,
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: widget.trimLines,
          ellipsis: overflow == TextOverflow.ellipsis ? widget.delimiter : null,
          locale: locale,
        );
        textPainter.layout(maxWidth: maxWidth);
        final Size linkSize = textPainter.size;
        textPainter.text = delimiter;
        textPainter.layout(maxWidth: maxWidth);
        final Size delimiterSize = textPainter.size;
        textPainter.text = text;
        textPainter.layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final Size textSize = textPainter.size;
        bool linkLongerThanLine = false;
        int endIndex;

        if (linkSize.width < maxWidth) {
          final double readMoreSize = linkSize.width + delimiterSize.width;
          final TextPosition pos = textPainter.getPositionForOffset(
            Offset(
              textDirection == TextDirection.rtl ? readMoreSize : textSize.width - readMoreSize,
              textSize.height,
            ),
          );
          endIndex = textPainter.getOffsetBefore(pos.offset) ?? 0;
        } else {
          final TextPosition pos = textPainter.getPositionForOffset(
            textSize.bottomLeft(Offset.zero),
          );
          endIndex = pos.offset;
          linkLongerThanLine = true;
        }

        TextSpan textSpan;
        switch (widget.trimMode) {
          case UTrimMode.length:
            if (widget.trimLength < widget.data.length) {
              textSpan = _buildData(
                data: _readMore ? widget.data.substring(0, widget.trimLength) : widget.data,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: <TextSpan>[delimiter, link],
              );
            } else {
              textSpan = _buildData(
                data: widget.data,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: <TextSpan>[],
              );
            }
            break;
          case UTrimMode.line:
            if (textPainter.didExceedMaxLines) {
              textSpan = _buildData(
                data: _readMore ? widget.data.substring(0, endIndex) + (linkLongerThanLine ? _kLineSeparator : "") : widget.data,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: <TextSpan>[delimiter, link],
              );
            } else {
              textSpan = _buildData(
                data: widget.data,
                textStyle: effectiveTextStyle,
                linkTextStyle: effectiveTextStyle?.copyWith(
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
                onPressed: widget.onLinkPressed,
                children: <TextSpan>[],
              );
            }
            break;
        }

        return Text.rich(
          TextSpan(
            children: <InlineSpan>[
              ?preTextSpan,
              textSpan,
              ?postTextSpan,
            ],
          ),
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: true,
          overflow: TextOverflow.clip,
        );
      },
    );
    if (widget.semanticsLabel != null) {
      result = Semantics(
        textDirection: widget.textDirection,
        label: widget.semanticsLabel,
        child: ExcludeSemantics(child: result),
      );
    }
    return result;
  }

  TextSpan _buildData({
    required String data,
    required List<TextSpan> children,
    TextStyle? textStyle,
    TextStyle? linkTextStyle,
    ValueChanged<String>? onPressed,
  }) {
    final List<TextSpan> contents = <TextSpan>[];

    while (_urlExp.hasMatch(data)) {
      final RegExpMatch? match = _urlExp.firstMatch(data);

      final String firstTextPart = data.substring(0, match!.start);
      final String linkTextPart = data.substring(match.start, match.end);

      contents.add(TextSpan(text: firstTextPart));
      contents.add(
        TextSpan(
          text: linkTextPart,
          style: linkTextStyle,
          recognizer: _tap(() => onPressed?.call(linkTextPart.trim())),
        ),
      );
      data = data.substring(match.end, data.length);
    }
    contents.add(TextSpan(text: data));
    return TextSpan(children: contents..addAll(children), style: textStyle);
  }
}
