import "package:u/components/cached_image.dart";
import "package:u/utilities.dart";

class UImage extends StatelessWidget {
  const UImage(
    this.source, {
    super.key,
    this.fileData,
    this.color,
    this.width,
    this.height,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.borderRadius = 1,
    this.border,
    this.package,
  });

  final String? package;
  final String source;
  final FileData? fileData;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? placeholder;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: border,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: Builder(
      builder: (BuildContext context) {
        if (fileData != null) {
          if (fileData?.bytes != null) {
            return UImageMemory(
              fileData!.bytes!,
              width: width,
              height: height,
              borderRadius: borderRadius,
              color: color,
              fit: fit,
              placeholder: placeholder,
            );
          } else {
            return UImageFile(
              File(fileData!.path!),
              width: width,
              height: height,
              borderRadius: borderRadius,
              color: color,
              fit: fit,
            );
          }
        } else if (source.length <= 5) {
          if (placeholder == null) {
            return SizedBox(width: width, height: height);
          } else {
            return UImageAsset(
              placeholder!,
              width: width,
              height: height,
              borderRadius: borderRadius,
              placeholder: placeholder,
              color: color,
              fit: fit,
              package: package,
            );
          }
        } else {
          if (source.endsWith(".json")) {
            return source.startsWith("http")
                ? Lottie.network(source, width: width, height: height, fit: fit, repeat: true)
                : Lottie.asset(source, width: width, height: height, fit: fit, repeat: true);
          } else if (source.startsWith("http")) {
            return UImageNetwork(
              source,
              width: width,
              height: height,
              fit: fit,
              borderRadius: borderRadius,
              color: color,
              placeholder: placeholder,
            );
          } else {
            return UImageAsset(
              source,
              width: width,
              height: height,
              fit: fit,
              borderRadius: borderRadius,
              placeholder: placeholder,
              color: color,
              package: package,
            );
          }
        }
      },
    ),
  );
}

class UIconPrimary extends StatelessWidget {
  const UIconPrimary(
    this.source, {
    super.key,
    this.color,
    this.width,
    this.height,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.borderRadius = 1,
    this.package,
  });

  final String? package;
  final String source;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? placeholder;

  @override
  Widget build(BuildContext context) => UImage(
    source,
    color: color ?? Theme.of(navigatorKey.currentContext!).colorScheme.primary,
    width: width,
    height: height,
    fit: fit,
    borderRadius: borderRadius,
    placeholder: placeholder,
    package: package,
  );
}

class UImageAsset extends StatelessWidget {
  const UImageAsset(
    this.path, {
    this.color,
    this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius = 1,
    this.package,
    super.key,
  });

  final String? package;
  final String path;
  final String? placeholder;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Clip clipBehavior;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => path.endsWith("svg")
      ? SvgPicture.asset(
          path,
          width: width,
          height: height,
          fit: fit,
          colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
          package: package,
          placeholderBuilder: (BuildContext context) => placeholder == null
              ? SizedBox(width: width, height: height)
              : UImageAsset(
                  placeholder!,
                  color: color,
                  width: width,
                  height: height,
                  fit: fit,
                  clipBehavior: clipBehavior,
                  borderRadius: borderRadius,
                  package: package,
                ),
        ).container(radius: borderRadius)
      : Image.asset(
          path,
          color: color,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: width == null ? null : (width! * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0)).round(),
          cacheHeight: height == null ? null : (height! * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0)).round(),
          package: package,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder == null
              ? SizedBox(width: width, height: height)
              : UImageAsset(
                  placeholder!,
                  color: color,
                  width: width,
                  height: height,
                  fit: fit,
                  clipBehavior: clipBehavior,
                  borderRadius: borderRadius,
                  package: package,
                ),
        );
}

class UImageNetwork extends StatelessWidget {
  const UImageNetwork(
    this.url, {
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius = 1,
    this.placeholder,
    this.package,
    super.key,
  });

  final String? package;
  final String url;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Clip clipBehavior;
  final double borderRadius;
  final String? placeholder;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (BuildContext context) => url.length <= 10
        ? placeholder == null
              ? SizedBox(width: width, height: height)
              : UImageAsset(
                  placeholder!,
                  width: width,
                  height: height,
                  color: color,
                  fit: fit,
                  clipBehavior: clipBehavior,
                  borderRadius: borderRadius,
                  package: package,
                )
        : url.substring(url.length - 3) == "svg"
        ? SvgPicture.network(
            url,
            width: width,
            height: height,
            fit: fit,
            placeholderBuilder: placeholder == null
                ? null
                : (_) => UImageAsset(
                    placeholder!,
                    width: width,
                    height: height,
                    fit: fit,
                    clipBehavior: clipBehavior,
                    borderRadius: borderRadius,
                    package: package,
                  ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            errorWidget: placeholder == null
                ? null
                : UImage(
                    placeholder!,
                    color: color,
                    width: width,
                    height: height,
                    fit: fit,
                    package: package,
                  ),
            placeholder: placeholder == null
                ? null
                : UImage(
                    placeholder!,
                    color: color,
                    width: width,
                    height: height,
                    fit: fit,
                    package: package,
                  ),
          ),
  ).container(radius: borderRadius);
}

class UImageFile extends StatelessWidget {
  const UImageFile(
    this.file, {
    this.color,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 1,
    super.key,
  });

  final File file;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    return Image.file(
      file,
      color: color,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width == null ? null : (width! * dpr).round(),
      cacheHeight: height == null ? null : (height! * dpr).round(),
    ).container(radius: borderRadius);
  }
}

class UImageMemory extends StatelessWidget {
  const UImageMemory(
    this.file, {
    this.color,
    this.width,
    this.height,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.borderRadius = 1,
    super.key,
  });

  final Uint8List file;
  final Color? color;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final double dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    return Image.memory(
      file,
      color: color,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width == null ? null : (width! * dpr).round(),
      cacheHeight: height == null ? null : (height! * dpr).round(),
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => placeholder == null
          ? SizedBox(width: width, height: height)
          : UImageAsset(
              placeholder!,
              color: color,
              width: width,
              height: height,
              fit: fit,
              borderRadius: borderRadius,
            ),
    ).container(radius: borderRadius);
  }
}
