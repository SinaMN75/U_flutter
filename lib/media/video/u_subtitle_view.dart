import "package:u/utilities.dart";

class USubtitleStyleConfig {
  const USubtitleStyleConfig({
    this.fontSize = 18,
    this.color = const Color(0xFFFFFFFF),
    this.outlineColor = const Color(0xFF000000),
    this.outlineWidth = 2.5,
    this.backgroundColor = const Color(0x00000000),
    this.fontWeight = FontWeight.w600,
    this.fontFamily,
    this.rtlFontFamily = "Vazir",
    this.bottomPadding = 24,
    this.horizontalPadding = 24,
    this.lineHeight = 1.3,
    this.shadow = true,
    this.honorAssStyling = true,
    this.maxLines = 4,
  });

  final double fontSize;
  final Color color;
  final Color outlineColor;
  final double outlineWidth;
  final Color backgroundColor;
  final FontWeight fontWeight;
  final String? fontFamily;
  final String? rtlFontFamily;
  final double bottomPadding;
  final double horizontalPadding;
  final double lineHeight;
  final bool shadow;
  final bool honorAssStyling;
  final int maxLines;

  USubtitleStyleConfig copyWith({double? fontSize, Color? color, double? outlineWidth, double? bottomPadding, Color? backgroundColor}) => USubtitleStyleConfig(
    fontSize: fontSize ?? this.fontSize,
    color: color ?? this.color,
    outlineColor: outlineColor,
    outlineWidth: outlineWidth ?? this.outlineWidth,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    fontWeight: fontWeight,
    fontFamily: fontFamily,
    rtlFontFamily: rtlFontFamily,
    bottomPadding: bottomPadding ?? this.bottomPadding,
    horizontalPadding: horizontalPadding,
    lineHeight: lineHeight,
    shadow: shadow,
    honorAssStyling: honorAssStyling,
    maxLines: maxLines,
  );
}

class USubtitleView extends StatelessWidget {
  const USubtitleView({required this.controller, super.key, this.style = const USubtitleStyleConfig(), this.scale = 1});

  final UMediaController controller;
  final USubtitleStyleConfig style;
  final double scale;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<USubtitleCue>>(
    valueListenable: controller.activeCues,
    builder: (BuildContext context, List<USubtitleCue> cues, Widget? child) {
      if (cues.isEmpty) return const SizedBox.shrink();
      return IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: cues.map(_positioned).toList(growable: false),
        ),
      );
    },
  );

  Widget _positioned(USubtitleCue cue) {
    final Alignment alignment = _alignmentOf(cue.alignment);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: style.horizontalPadding,
          right: style.horizontalPadding,
          bottom: alignment.y > 0 ? style.bottomPadding : 0,
          top: alignment.y < 0 ? style.bottomPadding : 0,
        ),
        child: _cueBody(cue),
      ),
    );
  }

  Alignment _alignmentOf(int code) {
    switch (code) {
      case 1:
        return Alignment.bottomLeft;
      case 3:
        return Alignment.bottomRight;
      case 4:
        return Alignment.centerLeft;
      case 5:
        return Alignment.center;
      case 6:
        return Alignment.centerRight;
      case 7:
        return Alignment.topLeft;
      case 8:
        return Alignment.topCenter;
      case 9:
        return Alignment.topRight;
      default:
        return Alignment.bottomCenter;
    }
  }

  Widget _cueBody(USubtitleCue cue) {
    final bool rtl = cue.isRtl;
    final double size = style.fontSize * scale;
    final TextAlign align = cue.alignment == 1 || cue.alignment == 4 || cue.alignment == 7
        ? TextAlign.start
        : (cue.alignment == 3 || cue.alignment == 6 || cue.alignment == 9 ? TextAlign.end : TextAlign.center);

    final Widget text = Stack(
      children: <Widget>[
        if (style.outlineWidth > 0) _richText(cue, size, align, rtl, _strokeStyle(size, rtl), true),
        _richText(cue, size, align, rtl, _baseStyle(size, rtl), false),
      ],
    );

    if (style.backgroundColor.a == 0) return Directionality(textDirection: rtl ? TextDirection.rtl : TextDirection.ltr, child: text);

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: DecoratedBox(
        decoration: BoxDecoration(color: style.backgroundColor, borderRadius: BorderRadius.circular(6)),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: text),
      ),
    );
  }

  TextStyle _baseStyle(double size, bool rtl) => TextStyle(
    fontSize: size,
    fontWeight: style.fontWeight,
    color: style.color,
    height: style.lineHeight,
    fontFamily: rtl ? style.rtlFontFamily : style.fontFamily,
    package: rtl && style.rtlFontFamily == "Vazir" ? "u" : null,
    shadows: style.shadow
        ? <Shadow>[Shadow(color: style.outlineColor.withValues(alpha: 0.6), blurRadius: 4 * scale, offset: Offset(0, 1 * scale))]
        : null,
  );

  TextStyle _strokeStyle(double size, bool rtl) => TextStyle(
    fontSize: size,
    fontWeight: style.fontWeight,
    height: style.lineHeight,
    fontFamily: rtl ? style.rtlFontFamily : style.fontFamily,
    package: rtl && style.rtlFontFamily == "Vazir" ? "u" : null,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.outlineWidth * scale
      ..strokeJoin = StrokeJoin.round
      ..color = style.outlineColor,
  );

  Widget _richText(USubtitleCue cue, double size, TextAlign align, bool rtl, TextStyle base, bool isStroke) => Text.rich(
    TextSpan(
      children: cue.spans
          .map(
            (USubtitleSpan span) => TextSpan(
              text: span.text,
              style: !style.honorAssStyling
                  ? null
                  : base.copyWith(
                      fontWeight: span.bold ? FontWeight.w800 : null,
                      fontStyle: span.italic ? FontStyle.italic : null,
                      decoration: span.underline
                          ? TextDecoration.underline
                          : (span.strikethrough ? TextDecoration.lineThrough : null),
                      color: isStroke ? null : span.color,
                      fontSize: span.fontScale == null ? null : size * span.fontScale!,
                    ),
            ),
          )
          .toList(growable: false),
    ),
    style: base,
    textAlign: align,
    maxLines: style.maxLines,
    overflow: TextOverflow.ellipsis,
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
  );
}
