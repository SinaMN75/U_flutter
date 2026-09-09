import "package:u/utilities.dart";

class UFloatingMiniPlayer extends StatefulWidget {
  const UFloatingMiniPlayer({
    required this.controller,
    super.key,
    this.width = 190,
    this.margin = 12,
    this.borderRadius = 12,
    this.onExpand,
    this.onClose,
  });

  final UMediaController controller;
  final double width;
  final double margin;
  final double borderRadius;
  final VoidCallback? onExpand;
  final VoidCallback? onClose;

  @override
  State<UFloatingMiniPlayer> createState() => _UFloatingMiniPlayerState();
}

class _UFloatingMiniPlayerState extends State<UFloatingMiniPlayer> {
  Offset _position = Offset.zero;
  bool _initialised = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final UMediaValue value = widget.controller.value;
      final double height = widget.width / (value.hasVideo ? value.aspectRatio : 16 / 9);
      if (!_initialised) {
        _position = Offset(constraints.maxWidth - widget.width - widget.margin, constraints.maxHeight - height - widget.margin);
        _initialised = true;
      }

      return Stack(
        children: <Widget>[
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onPanUpdate: (DragUpdateDetails details) => setState(() => _position += details.delta),
              onPanEnd: (DragEndDetails _) => setState(() {
                final bool right = _position.dx + widget.width / 2 > constraints.maxWidth / 2;
                _position = Offset(
                  right ? constraints.maxWidth - widget.width - widget.margin : widget.margin,
                  _position.dy.clamp(widget.margin, constraints.maxHeight - height - widget.margin),
                );
              }),
              onTap: widget.onExpand,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFF000000),
                child: SizedBox(
                  width: widget.width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      UVideoView(controller: widget.controller),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close_rounded, color: Color(0xFFFFFFFF), size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      Align(
                        child: ValueListenableBuilder<UMediaValue>(
                          valueListenable: widget.controller,
                          builder: (BuildContext context, UMediaValue state, Widget? child) => IconButton(
                            onPressed: () => unawaited(widget.controller.playPause()),
                            icon: Icon(state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFFFFFFFF), size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class UMiniPlayerBar extends StatelessWidget {
  const UMiniPlayerBar({required this.controller, super.key, this.onTap, this.onClose, this.height = 64, this.showProgress = true});

  final UMediaController controller;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final double height;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<UMediaValue>(
      valueListenable: controller,
      builder: (BuildContext context, UMediaValue value, Widget? child) {
        final UMediaMetadata? metadata = value.metadata ?? controller.currentSource?.metadata;
        if (controller.currentSource == null) return const SizedBox.shrink();

        return Material(
          color: scheme.surfaceContainerHigh,
          child: InkWell(
            onTap: onTap,
            child: UColumn(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showProgress)
                  LinearProgressIndicator(
                    value: value.progress,
                    minHeight: 2,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                SizedBox(
                  height: height,
                  child: URow(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    spacing: 10,
                    children: <Widget>[
                      UArtwork(artwork: metadata?.artwork, size: height - 16),
                      Expanded(
                        child: UColumn(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            UTextBodyMedium(metadata?.displayTitle.isNotEmpty == true ? metadata!.displayTitle : U.s.unknownTitle, fontWeight: FontWeight.w600, maxLines: 1),
                            if (metadata?.displaySubtitle.isNotEmpty == true) UTextLabelSmall(metadata!.displaySubtitle, color: scheme.onSurfaceVariant, maxLines: 1),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: U.s.previous,
                        onPressed: controller.hasPrevious ? () => unawaited(controller.previous()) : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      IconButton(
                        tooltip: value.isPlaying ? U.s.pause : U.s.play,
                        onPressed: () => unawaited(controller.playPause()),
                        icon: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                      ),
                      IconButton(
                        tooltip: U.s.next,
                        onPressed: controller.hasNext ? () => unawaited(controller.next()) : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                      if (onClose != null)
                        IconButton(tooltip: U.s.close, onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
