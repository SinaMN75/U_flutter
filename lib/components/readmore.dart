import "package:u/utilities.dart";

enum TrimMode {
  length,
  line,
}

class ReadMoreText extends StatefulWidget {
  const ReadMoreText(
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
    this.trimMode = TrimMode.length,
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

  final int trimLength;
  final int trimLines;
  final TrimMode trimMode;
  final TextStyle? moreStyle;
  final TextStyle? lessStyle;
  final String? preDataText;
  final String? postDataText;
  final TextStyle? preDataTextStyle;
  final TextStyle? postDataTextStyle;
  final Function(bool val)? callback;

  final ValueChanged<String>? onLinkPressed;

  final TextStyle? linkTextStyle;

  final String delimiter;
  final String data;
  final String trimExpandedText;
  final String trimCollapsedText;
  final Color? colorClickableText;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final double? textScaleFactor;
  final String? semanticsLabel;
  final TextStyle? delimiterStyle;

  @override
  ReadMoreTextState createState() => ReadMoreTextState();
}

const String _kEllipsis = "\u2026";

const String _kLineSeparator = "\u2028";

class ReadMoreTextState extends State<ReadMoreText> {
  bool _readMore = true;

  void _onTapLink() {
    setState(() {
      _readMore = !_readMore;
      widget.callback?.call(_readMore);
    });
  }

  @override
  Widget build(BuildContext context) {
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
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
    );

    final TextSpan delimiter = TextSpan(
      text: _readMore
          ? widget.trimCollapsedText.isNotEmpty
                ? widget.delimiter
                : ""
          : "",
      style: defaultDelimiterStyle,
      recognizer: TapGestureRecognizer()..onTap = _onTapLink,
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
            if (preTextSpan != null) preTextSpan,
            TextSpan(text: widget.data, style: effectiveTextStyle),
            if (postTextSpan != null) postTextSpan,
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
          case TrimMode.length:
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
          case TrimMode.line:
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
              if (preTextSpan != null) preTextSpan,
              textSpan,
              if (postTextSpan != null) postTextSpan,
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
    final RegExp exp = RegExp(r"(?:(?:https?|ftp)://)?[\w/\-?=%.]+\.[\w/\-?=%.]+");

    final List<TextSpan> contents = <TextSpan>[];

    while (exp.hasMatch(data)) {
      final RegExpMatch? match = exp.firstMatch(data);

      final String firstTextPart = data.substring(0, match!.start);
      final String linkTextPart = data.substring(match.start, match.end);

      contents.add(TextSpan(text: firstTextPart));
      contents.add(
        TextSpan(
          text: linkTextPart,
          style: linkTextStyle,
          recognizer: TapGestureRecognizer()..onTap = () => onPressed?.call(linkTextPart.trim()),
        ),
      );
      data = data.substring(match.end, data.length);
    }
    contents.add(TextSpan(text: data));
    return TextSpan(children: contents..addAll(children), style: textStyle);
  }
}
