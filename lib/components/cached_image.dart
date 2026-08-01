import "package:u/utilities.dart";

class CachedNetworkImage extends StatefulWidget {
  const CachedNetworkImage({
    required this.imageUrl,
    super.key,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.fit,
  });

  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  _CachedNetworkImageState createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage> {
  late Future<Uint8List?> _imageDataFuture;

  @override
  void initState() {
    super.initState();
    _imageDataFuture = _loadImage();
  }

  Future<Uint8List?> _loadImage() async {
    final String? cachedBase64 = ULocalStorage.getString(widget.imageUrl);
    if (cachedBase64 != null) {
      return base64.decode(cachedBase64);
    }
    try {
      final Response response = await get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        ULocalStorage.set(widget.imageUrl, base64.encode(bytes));
        return bytes;
      }
    } catch (e) {
      e.printError();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _imageDataFuture,
    builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return widget.placeholder ?? const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError || snapshot.data == null) {
        return widget.errorWidget ?? const Icon(Icons.error);
      } else {
        return Image.memory(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        );
      }
    },
  );
}
