import "package:flutter/material.dart";

/// Shared base for every `UText*` variant. Holds all customizable styling
/// (everything except `fontSize`, which is fixed by the theme text style each
/// variant resolves via [_baseStyle]) and centralizes the Text/SelectableText
/// build logic so the behavior stays identical across all variants.
abstract class _UText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final TextBaseline? textBaseline;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final StrutStyle? strutStyle;
  final TextScaler? textScaler;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final String? semanticsLabel;
  final List<Shadow>? shadows;
  final List<FontFeature>? fontFeatures;
  final List<FontVariation>? fontVariations;
  final Paint? foreground;
  final Paint? background;
  final Color? selectionColor;
  final TextDirection? textDirection;
  final TextLeadingDistribution? leadingDistribution;
  final bool selectable;

  const _UText(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.textBaseline,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.strutStyle,
    this.textScaler,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.semanticsLabel,
    this.shadows,
    this.fontFeatures,
    this.fontVariations,
    this.foreground,
    this.background,
    this.selectionColor,
    this.textDirection,
    this.leadingDistribution,
    this.selectable = false,
  });

  /// The theme text style (and therefore the fixed font size) for this variant.
  TextStyle _baseStyle(BuildContext context);

  @override
  Widget build(BuildContext context) {
    // Merge the caller's overrides onto the variant's theme style once.
    final TextStyle style = _baseStyle(context).copyWith(
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      textBaseline: textBaseline,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      foreground: foreground,
      background: background,
      leadingDistribution: leadingDistribution ?? TextLeadingDistribution.proportional,
    );

    if (selectable) {
      return SelectableText(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        textDirection: textDirection,
        strutStyle: strutStyle,
        textScaler: textScaler,
        textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
        textHeightBehavior: textHeightBehavior,
        semanticsLabel: semanticsLabel,
        // Respect the caller's overflow instead of forcing ellipsis.
        style: style.copyWith(overflow: overflow ?? TextOverflow.ellipsis),
      );
    }

    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.ellipsis,
      maxLines: maxLines,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
      textDirection: textDirection,
      strutStyle: strutStyle,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
      style: style,
    );
  }
}

class UTextDisplayLarge extends _UText {
  const UTextDisplayLarge(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.displayLarge!;
}

class UTextDisplayMedium extends _UText {
  const UTextDisplayMedium(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.displayMedium!;
}

class UTextDisplaySmall extends _UText {
  const UTextDisplaySmall(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.displaySmall!;
}

class UTextHeadlineLarge extends _UText {
  const UTextHeadlineLarge(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.headlineLarge!;
}

class UTextHeadlineMedium extends _UText {
  const UTextHeadlineMedium(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.headlineMedium!;
}

class UTextHeadlineSmall extends _UText {
  const UTextHeadlineSmall(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.headlineSmall!;
}

class UTextTitleLarge extends _UText {
  const UTextTitleLarge(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.titleLarge!;
}

class UTextTitleMedium extends _UText {
  const UTextTitleMedium(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.titleMedium!;
}

class UTextTitleSmall extends _UText {
  const UTextTitleSmall(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.titleSmall!;
}

class UTextBodyLarge extends _UText {
  const UTextBodyLarge(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.bodyLarge!;
}

class UTextBodyMedium extends _UText {
  const UTextBodyMedium(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.bodyMedium!;
}

class UTextBodySmall extends _UText {
  const UTextBodySmall(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.bodySmall!;
}

class UTextLabelLarge extends _UText {
  const UTextLabelLarge(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.labelLarge!;
}

class UTextLabelMedium extends _UText {
  const UTextLabelMedium(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.labelMedium!;
}

class UTextLabelSmall extends _UText {
  const UTextLabelSmall(
    super.text, {
    super.key,
    super.color,
    super.fontWeight,
    super.fontStyle,
    super.fontFamily,
    super.letterSpacing,
    super.wordSpacing,
    super.height,
    super.decoration,
    super.decorationColor,
    super.decorationStyle,
    super.decorationThickness,
    super.textBaseline,
    super.textAlign,
    super.overflow,
    super.maxLines,
    super.softWrap,
    super.strutStyle,
    super.textScaler,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.semanticsLabel,
    super.shadows,
    super.fontFeatures,
    super.fontVariations,
    super.foreground,
    super.background,
    super.selectionColor,
    super.textDirection,
    super.leadingDistribution,
    super.selectable = false,
  });

  @override
  TextStyle _baseStyle(BuildContext context) => Theme.of(context).textTheme.labelSmall!;
}

class UAnimatedCounter extends StatelessWidget {
  const UAnimatedCounter({
    required this.value,
    required this.builder,
    super.key,
    this.duration = const Duration(milliseconds: 1500),
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: value),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (BuildContext context, double v, Widget? child) => builder(context, v),
  );
}
