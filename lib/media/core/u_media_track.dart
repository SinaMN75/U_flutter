import "package:u/utilities.dart";

class UBufferedRange {
  const UBufferedRange(this.start, this.end);

  final Duration start;
  final Duration end;

  Duration get length => end - start;
}

class UMediaTrack {
  const UMediaTrack({
    required this.id,
    required this.type,
    this.label,
    this.language,
    this.codec,
    this.bitrate,
    this.width,
    this.height,
    this.frameRate,
    this.channels,
    this.sampleRate,
    this.isDefault = false,
    this.isForced = false,
    this.isSelected = false,
    this.isAuto = false,
  });

  final String id;
  final UMediaTrackType type;
  final String? label;
  final String? language;
  final String? codec;
  final int? bitrate;
  final int? width;
  final int? height;
  final double? frameRate;
  final int? channels;
  final int? sampleRate;
  final bool isDefault;
  final bool isForced;
  final bool isSelected;
  final bool isAuto;

  String get qualityLabel {
    if (height == null || height == 0) return "";
    return "${height}p";
  }

  String get bitrateLabel {
    final int? value = bitrate;
    if (value == null || value <= 0) return "";
    return value >= 1000000 ? "${(value / 1000000).toStringAsFixed(1)} Mbps" : "${(value / 1000).round()} kbps";
  }

  String get channelLabel {
    switch (channels) {
      case 1:
        return "Mono";
      case 2:
        return "Stereo";
      case 6:
        return "5.1";
      case 8:
        return "7.1";
      default:
        return channels == null ? "" : "$channels ch";
    }
  }

  factory UMediaTrack.fromMap(Map<Object?, Object?> map) => UMediaTrack(
    id: (map["id"] as String?) ?? "",
    type: UMediaTrackType.values.firstWhere((UMediaTrackType t) => t.name == map["type"], orElse: () => UMediaTrackType.video),
    label: map["label"] as String?,
    language: map["language"] as String?,
    codec: map["codec"] as String?,
    bitrate: map["bitrate"] as int?,
    width: map["width"] as int?,
    height: map["height"] as int?,
    frameRate: (map["frameRate"] as num?)?.toDouble(),
    channels: map["channels"] as int?,
    sampleRate: map["sampleRate"] as int?,
    isDefault: map["isDefault"] == true,
    isForced: map["isForced"] == true,
    isSelected: map["isSelected"] == true,
    isAuto: map["isAuto"] == true,
  );

  UMediaTrack copyWith({bool? isSelected}) => UMediaTrack(
    id: id,
    type: type,
    label: label,
    language: language,
    codec: codec,
    bitrate: bitrate,
    width: width,
    height: height,
    frameRate: frameRate,
    channels: channels,
    sampleRate: sampleRate,
    isDefault: isDefault,
    isForced: isForced,
    isSelected: isSelected ?? this.isSelected,
    isAuto: isAuto,
  );
}
