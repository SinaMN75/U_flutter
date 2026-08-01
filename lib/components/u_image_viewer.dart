import "package:u/utilities.dart";

class UImageViewer extends StatelessWidget {
  const UImageViewer({
    required this.fileData,
    super.key,
    this.heroTag,
    this.minScale = 0.8,
    this.maxScale = 4.0,
    this.backgroundColor = Colors.black,
  });

  final FileData fileData;
  final String? heroTag;
  final double minScale;
  final double maxScale;
  final Color backgroundColor;

  ImageProvider _getImageProvider() {
    if (fileData.bytes != null) {
      return MemoryImage(fileData.bytes!);
    } else if (fileData.url != null) {
      return NetworkImage(fileData.url!);
    } else if (fileData.path != null) {
      return FileImage(File(fileData.path!));
    } else {
      return const AssetImage("assets/placeholder.png");
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    body: Container(
      color: backgroundColor,
      child: Stack(
        children: <Widget>[
          InteractiveViewer(
            minScale: minScale,
            maxScale: maxScale,
            child: Center(
              child: Hero(
                tag: heroTag ?? fileData.id ?? "image_hero",
                child: Image(
                  image: _getImageProvider(),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.broken_image, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Failed to load image",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class BetterImageViewer extends StatefulWidget {
  const BetterImageViewer({
    required this.fileData,
    super.key,
    this.heroTag,
    this.minScale = 0.8,
    this.maxScale = 4.0,
    this.backgroundColor = Colors.black,
  });

  final FileData fileData;
  final String? heroTag;
  final double minScale;
  final double maxScale;
  final Color backgroundColor;

  @override
  State<BetterImageViewer> createState() => _BetterImageViewerState();
}

class _BetterImageViewerState extends State<BetterImageViewer> {
  ImageProvider? _imageProvider;
  Size? _imageSize;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      ImageProvider provider;

      if (widget.fileData.bytes != null) {
        provider = MemoryImage(widget.fileData.bytes!);
      } else if (widget.fileData.url != null) {
        provider = NetworkImage(widget.fileData.url!);
      } else if (widget.fileData.path != null) {
        provider = FileImage(File(widget.fileData.path!));
      } else {
        throw Exception("No image source available");
      }

      final Completer<Size> completer = Completer<Size>();
      final ImageStream stream = provider.resolve(const ImageConfiguration());

      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, _) {
            if (!completer.isCompleted) {
              completer.complete(
                Size(
                  info.image.width.toDouble(),
                  info.image.height.toDouble(),
                ),
              );
            }
          },
          onError: (Object error, _) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
        ),
      );

      final Size size = await completer.future;

      if (mounted) {
        setState(() {
          _imageProvider = provider;
          _imageSize = size;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.backgroundColor,
    body: Stack(
      children: <Widget>[
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text("Error: $_error", style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                      _loadImage();
                    });
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          )
        else if (_imageProvider != null && _imageSize != null)
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = constraints.maxWidth;
              final double screenHeight = constraints.maxHeight;
              final double imageAspect = _imageSize!.width / _imageSize!.height;
              final double screenAspect = screenWidth / screenHeight;

              double scale;
              if (imageAspect > screenAspect) {
                scale = screenWidth / _imageSize!.width;
              } else {
                scale = screenHeight / _imageSize!.height;
              }

              return InteractiveViewer(
                minScale: scale * 0.8,
                maxScale: widget.maxScale,
                scaleFactor: scale,
                child: SizedBox(
                  width: _imageSize!.width,
                  height: _imageSize!.height,
                  child: Hero(
                    tag: widget.heroTag ?? widget.fileData.id ?? "image_hero",
                    child: Image(
                      image: _imageProvider!,
                      fit: BoxFit.contain,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const Center(child: Text("Failed to load image")),
                    ),
                  ),
                ),
              );
            },
          ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
          ),
        ),
      ],
    ),
  );
}

class ImageGalleryViewer extends StatefulWidget {
  const ImageGalleryViewer({
    required this.files,
    super.key,
    this.initialIndex = 0,
    this.backgroundColor = Colors.black,
    this.minScale = 0.8,
    this.maxScale = 4.0,
  });

  final List<FileData> files;
  final int initialIndex;
  final Color backgroundColor;
  final double minScale;
  final double maxScale;

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.backgroundColor,
    body: Stack(
      children: <Widget>[
        PageView.builder(
          controller: _pageController,
          onPageChanged: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemCount: widget.files.length,
          itemBuilder: (BuildContext context, int index) => BetterImageViewer(
            fileData: widget.files[index],
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            backgroundColor: widget.backgroundColor,
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_currentIndex + 1} / ${widget.files.length}",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}
