import "package:u/utilities.dart";

const List<double> uSpeedPresets = <double>[0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 3, 4];

class UVideoStatsOverlay extends StatelessWidget {
  const UVideoStatsOverlay({required this.controller, super.key});

  final UMediaController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final UMediaTrack? video = value.selectedTrack(UMediaTrackType.video);
      final UMediaTrack? audio = value.selectedTrack(UMediaTrackType.audio);
      final Duration buffer = value.bufferedPosition - value.position;
      return UContainer(
        color: const Color(0xB3000000),
        radius: 8,
        padding: const EdgeInsets.all(10),
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _line(U.s.resolution, value.hasVideo ? "${value.width}x${value.height}" : "-"),
            _line(U.s.codec, video?.codec ?? "-"),
            _line(U.s.bitrate, video?.bitrateLabel ?? "-"),
            _line(U.s.frameRate, video?.frameRate == null ? "-" : "${video!.frameRate!.toStringAsFixed(2)} fps"),
            _line(U.s.audioTrack, audio == null ? "-" : "${audio.codec ?? ""} ${audio.channelLabel}".trim()),
            _line(U.s.bufferHealth, "${(buffer.inMilliseconds / 1000).clamp(0, 999).toStringAsFixed(1)}s"),
            _line(U.s.playbackSpeed, "${value.speed}x"),
            _line(U.s.state, value.state.name),
          ],
        ),
      );
    },
  );

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: URow(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(width: 110, child: UTextLabelSmall(label, color: const Color(0x99FFFFFF))),
        UTextLabelSmall(value, color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
      ],
    ),
  );
}

class UMediaTrackSheet extends StatelessWidget {
  const UMediaTrackSheet({required this.controller, required this.type, super.key, this.allowOff = false});

  final UMediaController controller;
  final UMediaTrackType type;
  final bool allowOff;

  String get _title {
    switch (type) {
      case UMediaTrackType.video:
        return U.s.quality;
      case UMediaTrackType.audio:
        return U.s.audioTrack;
      case UMediaTrackType.subtitle:
        return U.s.subtitles;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final List<UMediaTrack> tracks = value.tracksOf(type);
      return UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: UTextTitleMedium(_title, fontWeight: FontWeight.w700)),
          if (type == UMediaTrackType.video)
            ListTile(
              leading: const Icon(Icons.hd_rounded),
              title: UTextBodyMedium(U.s.auto),
              trailing: value.selectedTrack(type) == null ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                unawaited(controller.setAutoQuality());
                Navigator.of(context).pop();
              },
            ),
          if (allowOff)
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: UTextBodyMedium(U.s.off),
              trailing: controller.subtitles == null ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                controller.clearSubtitles();
                Navigator.of(context).pop();
              },
            ),
          if (tracks.isEmpty && !allowOff)
            Padding(
              padding: const EdgeInsets.all(20),
              child: UTextBodySmall(U.s.noTracksAvailable, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ...tracks.map(
            (UMediaTrack track) => ListTile(
              leading: Icon(_iconFor(track)),
              title: UTextBodyMedium(_labelFor(track)),
              subtitle: _subtitleFor(track) == null ? null : UTextLabelSmall(_subtitleFor(track)!),
              trailing: track.isSelected ? const Icon(Icons.check_rounded) : null,
              onTap: () {
                unawaited(controller.selectTrack(track));
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      );
    },
  );

  IconData _iconFor(UMediaTrack track) {
    switch (track.type) {
      case UMediaTrackType.video:
        return Icons.high_quality_rounded;
      case UMediaTrackType.audio:
        return Icons.graphic_eq_rounded;
      case UMediaTrackType.subtitle:
        return Icons.subtitles_rounded;
    }
  }

  String _labelFor(UMediaTrack track) {
    if (track.label != null && track.label!.isNotEmpty) return track.label!;
    if (track.type == UMediaTrackType.video) return track.qualityLabel.isEmpty ? track.id : track.qualityLabel;
    return track.language ?? track.id;
  }

  String? _subtitleFor(UMediaTrack track) {
    final List<String> parts = <String>[
      if (track.language != null && track.label != null) track.language!,
      if (track.bitrateLabel.isNotEmpty) track.bitrateLabel,
      if (track.channelLabel.isNotEmpty) track.channelLabel,
      if (track.codec != null) track.codec!,
    ];
    return parts.isEmpty ? null : parts.join(" · ");
  }
}

class UMediaQueueSheet extends StatelessWidget {
  const UMediaQueueSheet({required this.controller, super.key});

  final UMediaController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<UMediaValue>(
    valueListenable: controller,
    builder: (BuildContext context, UMediaValue value, Widget? child) {
      final List<UMediaSource> queue = controller.queue;
      return UColumn(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: URow(
              children: <Widget>[
                Expanded(child: UTextTitleMedium("${U.s.queue} (${queue.length})", fontWeight: FontWeight.w700)),
                IconButton(
                  tooltip: U.s.shuffle,
                  onPressed: () => unawaited(controller.toggleShuffle()),
                  icon: Icon(Icons.shuffle_rounded, color: value.shuffle ? Theme.of(context).colorScheme.primary : null),
                ),
                IconButton(
                  tooltip: _repeatLabel(value.repeat),
                  onPressed: () => unawaited(controller.setRepeat(_nextRepeat(value.repeat))),
                  icon: Icon(
                    value.repeat == URepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    color: value.repeat == URepeatMode.off ? null : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: queue.length,
              onReorder: (int from, int to) => unawaited(controller.moveInQueue(from, to > from ? to - 1 : to)),
              itemBuilder: (BuildContext context, int index) {
                final UMediaSource item = queue[index];
                final bool current = index == value.currentIndex;
                return ListTile(
                  key: ValueKey<String>("${item.id}-$index"),
                  leading: UArtwork(artwork: item.metadata?.artwork, size: 44),
                  title: UTextBodyMedium(item.metadata?.displayTitle.isNotEmpty == true ? item.metadata!.displayTitle : item.id, maxLines: 1),
                  subtitle: item.metadata?.displaySubtitle.isNotEmpty == true ? UTextLabelSmall(item.metadata!.displaySubtitle, maxLines: 1) : null,
                  selected: current,
                  trailing: IconButton(
                    tooltip: U.s.removeFromQueue,
                    onPressed: () => unawaited(controller.removeAt(index)),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                  onTap: () => unawaited(controller.jumpTo(index)),
                );
              },
            ),
          ),
        ],
      );
    },
  );

  String _repeatLabel(URepeatMode mode) {
    switch (mode) {
      case URepeatMode.off:
        return U.s.repeatOff;
      case URepeatMode.one:
        return U.s.repeatOne;
      case URepeatMode.all:
        return U.s.repeatAll;
    }
  }

  URepeatMode _nextRepeat(URepeatMode mode) {
    switch (mode) {
      case URepeatMode.off:
        return URepeatMode.all;
      case URepeatMode.all:
        return URepeatMode.one;
      case URepeatMode.one:
        return URepeatMode.off;
    }
  }
}

class UVideoSettingsSheet extends StatefulWidget {
  const UVideoSettingsSheet({required this.controller, required this.settings, super.key});

  final UMediaController controller;
  final UVideoSettings settings;

  @override
  State<UVideoSettingsSheet> createState() => _UVideoSettingsSheetState();
}

class _UVideoSettingsSheetState extends State<UVideoSettingsSheet> {
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.settings,
    builder: (BuildContext context, Widget? child) => DefaultTabController(
      length: 4,
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TabBar(
            isScrollable: true,
            tabs: <Widget>[
              Tab(text: U.s.playback),
              Tab(text: U.s.subtitles),
              Tab(text: U.s.videoFilters),
              Tab(text: U.s.advanced),
            ],
          ),
          SizedBox(
            height: 340,
            child: TabBarView(
              children: <Widget>[_playbackTab(context), _subtitleTab(context), _filterTab(context), _advancedTab(context)],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _playbackTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      _sectionLabel(U.s.playbackSpeed),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: uSpeedPresets
            .map(
              (double speed) => ChoiceChip(
                label: Text("${speed}x"),
                selected: widget.controller.value.speed == speed,
                onSelected: (bool _) => unawaited(widget.controller.setSpeed(speed)),
              ),
            )
            .toList(growable: false),
      ).pSymmetric(horizontal: 16),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.high_quality_rounded),
        title: UTextBodyMedium(U.s.quality),
        onTap: () => UNavigator.bottomSheet(UMediaTrackSheet(controller: widget.controller, type: UMediaTrackType.video)),
      ),
      ListTile(
        leading: const Icon(Icons.graphic_eq_rounded),
        title: UTextBodyMedium(U.s.audioTrack),
        onTap: () => UNavigator.bottomSheet(UMediaTrackSheet(controller: widget.controller, type: UMediaTrackType.audio)),
      ),
      _sectionLabel(U.s.aspectRatio),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: UMediaFit.values
            .map(
              (UMediaFit fit) => ChoiceChip(
                label: Text(_fitLabel(fit)),
                selected: widget.settings.fit == fit,
                onSelected: (bool _) => widget.settings.fit = fit,
              ),
            )
            .toList(growable: false),
      ).pSymmetric(horizontal: 16),
    ],
  );

  Widget _subtitleTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      ListTile(
        leading: const Icon(Icons.subtitles_rounded),
        title: UTextBodyMedium(U.s.subtitleTrack),
        onTap: () => UNavigator.bottomSheet(UMediaTrackSheet(controller: widget.controller, type: UMediaTrackType.subtitle, allowOff: true)),
      ),
      ListTile(
        leading: const Icon(Icons.folder_open_rounded),
        title: UTextBodyMedium(U.s.loadSubtitleFile),
        onTap: () => unawaited(_pickSubtitle()),
      ),
      _slider(U.s.subtitleSize, widget.settings.subtitleScale, 0.5, 3, (double v) => widget.settings.subtitleScale = v),
      _slider(
        U.s.subtitleDelay,
        widget.settings.subtitleDelay.inMilliseconds / 1000,
        -10,
        10,
        (double v) => widget.settings.setSubtitleDelay(widget.controller, Duration(milliseconds: (v * 1000).round())),
        suffix: "s",
      ),
    ],
  );

  Widget _filterTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      _slider(U.s.brightness, widget.settings.brightness, -1, 1, (double v) => widget.settings.brightness = v),
      _slider(U.s.contrast, widget.settings.contrast, 0, 3, (double v) => widget.settings.contrast = v),
      _slider(U.s.saturation, widget.settings.saturation, 0, 3, (double v) => widget.settings.saturation = v),
      _slider(U.s.hue, widget.settings.hue, -180, 180, (double v) => widget.settings.hue = v),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: UButton(type: UButtonType.outlined, title: U.s.resetFilters, onTap: widget.settings.resetFilters),
      ),
    ],
  );

  Widget _advancedTab(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: <Widget>[
      SwitchListTile(
        secondary: const Icon(Icons.analytics_rounded),
        title: UTextBodyMedium(U.s.statistics),
        value: widget.settings.showStats,
        onChanged: (bool value) => widget.settings.showStats = value,
      ),
      ListTile(
        leading: const Icon(Icons.rotate_90_degrees_cw_rounded),
        title: UTextBodyMedium(U.s.rotate),
        onTap: widget.settings.rotateQuarter,
      ),
      SwitchListTile(
        secondary: const Icon(Icons.flip_rounded),
        title: UTextBodyMedium(U.s.mirror),
        value: widget.settings.mirrored,
        onChanged: (bool value) => widget.settings.mirrored = value,
      ),
      ListTile(
        leading: const Icon(Icons.repeat_on_rounded),
        title: UTextBodyMedium(U.s.abRepeat),
        subtitle: UTextLabelSmall(
          widget.settings.hasAbRepeat
              ? "${uFormatDuration(widget.settings.repeatStart!)} — ${uFormatDuration(widget.settings.repeatEnd!)}"
              : (widget.settings.repeatStart == null ? U.s.setPointA : U.s.setPointB),
        ),
        trailing: widget.settings.repeatStart == null
            ? null
            : IconButton(onPressed: widget.settings.clearRepeat, icon: const Icon(Icons.close_rounded)),
        onTap: () {
          if (widget.settings.repeatStart == null) {
            widget.settings.markRepeatStart(widget.controller.value.position);
          } else if (widget.settings.repeatEnd == null) {
            widget.settings.markRepeatEnd(widget.controller.value.position);
          } else {
            widget.settings.clearRepeat();
          }
        },
      ),
      ListTile(
        leading: const Icon(Icons.bedtime_rounded),
        title: UTextBodyMedium(U.s.sleepTimer),
        subtitle: widget.settings.sleepAt == null ? null : UTextLabelSmall(uFormatDuration(widget.settings.sleepAt!.difference(DateTime.now()))),
        onTap: () => _sleepTimerDialog(context),
      ),
      ListTile(
        leading: const Icon(Icons.camera_alt_rounded),
        title: UTextBodyMedium(U.s.screenshot),
        onTap: () => unawaited(_takeScreenshot()),
      ),
    ],
  );

  Future<void> _pickSubtitle() async {
    final FileData? picked = await UFile.pickFile(fileType: FileType.custom, allowedExtensions: <String>["srt", "vtt", "ass", "ssa", "sub", "lrc"]);
    final String? path = picked?.path;
    if (path == null) return;
    await widget.controller.loadSubtitle(UExternalSubtitle(uri: path, label: picked?.name));
  }

  Future<void> _takeScreenshot() async {
    final Uint8List? bytes = await widget.controller.screenshot();
    if (bytes == null) {
      UToast.error(message: U.s.thisFieldIsInvalid);
      return;
    }
    UToast.success(message: U.s.screenshotSaved);
  }

  void _sleepTimerDialog(BuildContext context) {
    UNavigator.bottomSheet(
      UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final int minutes in <int>[5, 10, 15, 30, 45, 60, 90])
            ListTile(
              title: UTextBodyMedium("$minutes ${U.s.minutes}"),
              onTap: () {
                widget.settings.startSleepTimer(Duration(minutes: minutes), () => unawaited(widget.controller.pause()));
                Navigator.of(context).pop();
              },
            ),
          if (widget.settings.sleepAt != null)
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: UTextBodyMedium(U.s.cancel),
              onTap: () {
                widget.settings.cancelSleepTimer();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: UTextLabelLarge(text, fontWeight: FontWeight.w700),
  );

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String suffix = ""}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: UColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          children: <Widget>[
            Expanded(child: UTextLabelLarge(label)),
            UTextLabelSmall("${value.toStringAsFixed(2)}$suffix"),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    ),
  );

  String _fitLabel(UMediaFit fit) {
    switch (fit) {
      case UMediaFit.contain:
        return U.s.fit;
      case UMediaFit.cover:
        return U.s.cover;
      case UMediaFit.fill:
        return U.s.stretch;
      case UMediaFit.fitWidth:
        return U.s.fitWidth;
      case UMediaFit.fitHeight:
        return U.s.fitHeight;
      case UMediaFit.none:
      case UMediaFit.original:
        return U.s.original;
      case UMediaFit.ratio16x9:
        return "16:9";
      case UMediaFit.ratio4x3:
        return "4:3";
      case UMediaFit.ratio21x9:
        return "21:9";
      case UMediaFit.ratio1x1:
        return "1:1";
    }
  }
}
