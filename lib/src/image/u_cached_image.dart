import "dart:ui" as ui;

import "package:u/utilities.dart";

/// Network image cached on disk (used by UImageNetwork).
class CachedNetworkImage extends StatelessWidget {
  const CachedNetworkImage({
    required this.imageUrl,
    super.key,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit,
  });

  /// Image address.
  final String imageUrl;

  /// Shown while loading.
  final Widget? placeholder;

  /// Shown when loading fails.
  final Widget? errorWidget;

  /// Width in logical pixels (null = size to content).
  final double? width;

  /// Height in logical pixels (null = size to content).
  final double? height;

  /// How the content fits its box (BoxFit).
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) => Image(
    image: UResizeImage.resizeIfNeeded(
      UNetworkImage(imageUrl),
      width: width,
      height: height,
      fit: fit,
      devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
    ),
    width: width,
    height: height,
    fit: fit,
    gaplessPlayback: true,
    frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) =>
        wasSynchronouslyLoaded || frame != null ? child : (placeholder ?? const Center(child: CircularProgressIndicator())),
    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => errorWidget ?? const Icon(Icons.error),
  );
}

/// Image from a URL, kept in the disk cache and shared through Flutter's image cache; widgets showing the same URL download it once.
class UNetworkImage extends ImageProvider<UNetworkImage> {
  const UNetworkImage(this.url);

  /// Image address.
  final String url;

  static final Map<String, Future<Uint8List>> _inFlight = <String, Future<Uint8List>>{};

  /// The image bytes from the disk cache, or downloaded (and cached) when missing.
  static Future<Uint8List> fetch(String url) => _inFlight[url] ??= _fetch(url).whenComplete(() => _inFlight.remove(url));

  static Future<Uint8List> _fetch(String url) async {
    final String key = "img_$url";
    final Uint8List? cached = await UFileStorage.getBytes(key, bucket: UStorageBucket.cache);
    if (cached != null && cached.isNotEmpty) return cached;
    final Response response = await get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) throw HttpException("Image request failed (${response.statusCode})", uri: Uri.tryParse(url));
    final Uint8List bytes = response.bodyBytes;
    unawaited(UFileStorage.setBytes(key, bytes, bucket: UStorageBucket.cache, mimeType: response.headers["content-type"]).catchError((Object _) {}));
    return bytes;
  }

  @override
  Future<UNetworkImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<UNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(UNetworkImage key, ImageDecoderCallback decode) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: 1,
    debugLabel: url,
    informationCollector: () => <DiagnosticsNode>[DiagnosticsProperty<ImageProvider>("Image provider", this)],
  );

  Future<ui.Codec> _load(UNetworkImage key, ImageDecoderCallback decode) async {
    try {
      return await decode(await ui.ImmutableBuffer.fromUint8List(await fetch(url)));
    } catch (_) {
      // Let a later build retry instead of caching the failure.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) => other is UNetworkImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => "UNetworkImage($url)";
}

/// Decodes [provider] at the size it is shown on screen, keeping its aspect ratio for [fit] and never above the source size.
class UResizeImage extends ImageProvider<UResizeImageKey> {
  const UResizeImage(this.provider, {this.width, this.height, this.fit = BoxFit.scaleDown}) : assert(width != null || height != null);

  /// The image to decode.
  final ImageProvider<Object> provider;

  /// Box width in physical pixels.
  final int? width;

  /// Box height in physical pixels.
  final int? height;

  /// How the image is fitted into the box.
  final BoxFit fit;

  /// [provider] resized to a [width] × [height] logical box, or [provider] itself when no size is known.
  static ImageProvider<Object> resizeIfNeeded(
    ImageProvider<Object> provider, {
    required double devicePixelRatio,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    final int? w = width == null || !width.isFinite || width <= 0 ? null : (width * devicePixelRatio).round();
    final int? h = height == null || !height.isFinite || height <= 0 ? null : (height * devicePixelRatio).round();
    if (w == null && h == null) return provider;
    return UResizeImage(provider, width: w, height: h, fit: fit ?? BoxFit.scaleDown);
  }

  ui.TargetImageSize _targetSize(int intrinsicWidth, int intrinsicHeight) {
    if (intrinsicWidth <= 0 || intrinsicHeight <= 0) return const ui.TargetImageSize();
    if (fit == BoxFit.fill && width != null && height != null) {
      return ui.TargetImageSize(width: min(width!, intrinsicWidth), height: min(height!, intrinsicHeight));
    }
    final double? sx = width == null ? null : width! / intrinsicWidth;
    final double? sy = height == null ? null : height! / intrinsicHeight;
    final double scale = sx == null || sy == null
        ? (sx ?? sy!)
        : switch (fit) {
            BoxFit.cover || BoxFit.fill => max(sx, sy),
            BoxFit.fitWidth => sx,
            BoxFit.fitHeight => sy,
            BoxFit.none => 1,
            BoxFit.contain || BoxFit.scaleDown => min(sx, sy),
          };
    if (scale >= 1) return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
    return ui.TargetImageSize(width: max(1, (intrinsicWidth * scale).round()), height: max(1, (intrinsicHeight * scale).round()));
  }

  @override
  Future<UResizeImageKey> obtainKey(ImageConfiguration configuration) {
    Completer<UResizeImageKey>? completer;
    SynchronousFuture<UResizeImageKey>? result;
    provider.obtainKey(configuration).then((Object key) {
      final UResizeImageKey resized = UResizeImageKey._(key, width, height, fit);
      if (completer == null) {
        result = SynchronousFuture<UResizeImageKey>(resized);
      } else {
        completer.complete(resized);
      }
    });
    if (result != null) return result!;
    completer = Completer<UResizeImageKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(UResizeImageKey key, ImageDecoderCallback decode) {
    Future<ui.Codec> decodeResized(ui.ImmutableBuffer buffer, {ui.TargetImageSizeCallback? getTargetSize}) => decode(buffer, getTargetSize: _targetSize);
    final ImageStreamCompleter completer = provider.loadImage(key._providerKey, decodeResized);
    completer.addEphemeralErrorListener((Object exception, StackTrace? stackTrace) => scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key)));
    return completer;
  }

  @override
  bool operator ==(Object other) => other is UResizeImage && other.provider == provider && other.width == width && other.height == height && other.fit == fit;

  @override
  int get hashCode => Object.hash(provider, width, height, fit);
}

/// Image-cache key of a [UResizeImage].
@immutable
class UResizeImageKey {
  const UResizeImageKey._(this._providerKey, this._width, this._height, this._fit);

  final Object _providerKey;
  final int? _width;
  final int? _height;
  final BoxFit _fit;

  @override
  bool operator ==(Object other) => other is UResizeImageKey && other._providerKey == _providerKey && other._width == _width && other._height == _height && other._fit == _fit;

  @override
  int get hashCode => Object.hash(_providerKey, _width, _height, _fit);
}
