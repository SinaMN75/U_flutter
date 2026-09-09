import "package:u/utilities.dart";

class UEqualizerBand {
  const UEqualizerBand({required this.index, required this.centerFrequencyHz, required this.gainDb, required this.minDb, required this.maxDb});

  final int index;
  final int centerFrequencyHz;
  final double gainDb;
  final double minDb;
  final double maxDb;

  String get label => centerFrequencyHz >= 1000 ? "${(centerFrequencyHz / 1000).toStringAsFixed(centerFrequencyHz % 1000 == 0 ? 0 : 1)}k" : "$centerFrequencyHz";

  factory UEqualizerBand.fromMap(Map<Object?, Object?> map) => UEqualizerBand(
    index: (map["index"] as int?) ?? 0,
    centerFrequencyHz: (map["centerFrequencyHz"] as int?) ?? 0,
    gainDb: (map["gainDb"] as num?)?.toDouble() ?? 0,
    minDb: (map["minDb"] as num?)?.toDouble() ?? -15,
    maxDb: (map["maxDb"] as num?)?.toDouble() ?? 15,
  );

  UEqualizerBand copyWith({double? gainDb}) =>
      UEqualizerBand(index: index, centerFrequencyHz: centerFrequencyHz, gainDb: gainDb ?? this.gainDb, minDb: minDb, maxDb: maxDb);
}

class UEqualizerState {
  const UEqualizerState({this.available = false, this.enabled = false, this.bands = const <UEqualizerBand>[], this.presets = const <String>[], this.preset, this.bassBoost = 0, this.virtualizer = 0, this.loudness = 0});

  final bool available;
  final bool enabled;
  final List<UEqualizerBand> bands;
  final List<String> presets;
  final String? preset;
  final double bassBoost;
  final double virtualizer;
  final double loudness;

  factory UEqualizerState.fromMap(Map<Object?, Object?> map) => UEqualizerState(
    available: map["available"] == true,
    enabled: map["enabled"] == true,
    bands: ((map["bands"] as List<Object?>?) ?? const <Object?>[]).whereType<Map<Object?, Object?>>().map(UEqualizerBand.fromMap).toList(growable: false),
    presets: ((map["presets"] as List<Object?>?) ?? const <Object?>[]).whereType<String>().toList(growable: false),
    preset: map["preset"] as String?,
    bassBoost: (map["bassBoost"] as num?)?.toDouble() ?? 0,
    virtualizer: (map["virtualizer"] as num?)?.toDouble() ?? 0,
    loudness: (map["loudness"] as num?)?.toDouble() ?? 0,
  );

  UEqualizerState copyWith({bool? enabled, List<UEqualizerBand>? bands, String? preset, double? bassBoost, double? virtualizer, double? loudness}) => UEqualizerState(
    available: available,
    enabled: enabled ?? this.enabled,
    bands: bands ?? this.bands,
    presets: presets,
    preset: preset ?? this.preset,
    bassBoost: bassBoost ?? this.bassBoost,
    virtualizer: virtualizer ?? this.virtualizer,
    loudness: loudness ?? this.loudness,
  );
}

class UEqualizer {
  UEqualizer(this.controller);

  final UMediaController controller;

  Future<UEqualizerState> read() async {
    final int? id = controller.playerId;
    if (id == null) return const UEqualizerState();
    try {
      final Map<Object?, Object?>? map = await UMediaChannel.call<Map<Object?, Object?>>(id, "getEqualizer");
      return map == null ? const UEqualizerState() : UEqualizerState.fromMap(map);
    } on PlatformException {
      return const UEqualizerState();
    } on MissingPluginException {
      return const UEqualizerState();
    }
  }

  Future<void> setEnabled(bool enabled) => _call("setEqualizerEnabled", <String, Object?>{"enabled": enabled});

  Future<void> setBand(int index, double gainDb) => _call("setEqualizerBand", <String, Object?>{"index": index, "gainDb": gainDb});

  Future<void> setPreset(String preset) => _call("setEqualizerPreset", <String, Object?>{"preset": preset});

  Future<void> setBassBoost(double strength) => _call("setBassBoost", <String, Object?>{"strength": strength});

  Future<void> setVirtualizer(double strength) => _call("setVirtualizer", <String, Object?>{"strength": strength});

  Future<void> setLoudness(double gainDb) => _call("setLoudness", <String, Object?>{"gainDb": gainDb});

  Future<void> _call(String method, Map<String, Object?> arguments) async {
    final int? id = controller.playerId;
    if (id == null) return;
    try {
      await UMediaChannel.call<void>(id, method, arguments);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

class UEqualizerSheet extends StatefulWidget {
  const UEqualizerSheet({required this.controller, super.key});

  final UMediaController controller;

  @override
  State<UEqualizerSheet> createState() => _UEqualizerSheetState();
}

class _UEqualizerSheetState extends State<UEqualizerSheet> {
  late final UEqualizer _equalizer = UEqualizer(widget.controller);
  UEqualizerState _state = const UEqualizerState();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final UEqualizerState state = await _equalizer.read();
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (_loading) return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    if (!_state.available) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: UTextBodyMedium(U.s.equalizerUnavailable, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return UColumn(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        URow(
          children: <Widget>[
            Expanded(child: UTextTitleMedium(U.s.equalizer, fontWeight: FontWeight.w700)),
            Switch(
              value: _state.enabled,
              onChanged: (bool value) {
                unawaited(_equalizer.setEnabled(value));
                setState(() => _state = _state.copyWith(enabled: value));
              },
            ),
          ],
        ),
        if (_state.presets.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _state.presets
                  .map(
                    (String preset) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(preset),
                        selected: _state.preset == preset,
                        onSelected: (bool _) {
                          unawaited(_equalizer.setPreset(preset));
                          unawaited(_load());
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        SizedBox(
          height: 200,
          child: URow(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _state.bands
                .map(
                  (UEqualizerBand band) => UColumn(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: band.gainDb.clamp(band.minDb, band.maxDb),
                            min: band.minDb,
                            max: band.maxDb,
                            onChanged: (double value) {
                              setState(() {
                                _state = _state.copyWith(
                                  bands: _state.bands.map((UEqualizerBand b) => b.index == band.index ? b.copyWith(gainDb: value) : b).toList(growable: false),
                                );
                              });
                              unawaited(_equalizer.setBand(band.index, value));
                            },
                          ),
                        ),
                      ),
                      UTextLabelSmall(band.label, color: scheme.onSurfaceVariant),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
        _effectSlider(U.s.bassBoost, _state.bassBoost, (double value) {
          setState(() => _state = _state.copyWith(bassBoost: value));
          unawaited(_equalizer.setBassBoost(value));
        }),
        _effectSlider(U.s.virtualizer, _state.virtualizer, (double value) {
          setState(() => _state = _state.copyWith(virtualizer: value));
          unawaited(_equalizer.setVirtualizer(value));
        }),
        _effectSlider(U.s.loudnessNormalization, _state.loudness, (double value) {
          setState(() => _state = _state.copyWith(loudness: value));
          unawaited(_equalizer.setLoudness(value));
        }),
      ],
    );
  }

  Widget _effectSlider(String label, double value, ValueChanged<double> onChanged) => UColumn(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UTextLabelLarge(label),
      Slider(value: value.clamp(0, 1), onChanged: onChanged),
    ],
  );
}
