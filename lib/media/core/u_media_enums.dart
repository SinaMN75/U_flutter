enum UMediaState { idle, loading, buffering, ready, playing, paused, completed, error }

enum UMediaKind { video, audio }

enum URepeatMode { off, one, all }

enum UMediaTrackType { video, audio, subtitle }

enum UMediaSourceKind { network, file, asset, bytes, content, stream }

enum UStreamProtocol { progressive, hls, dash, smoothStreaming, rtsp, rtmp, srt, webrtc }

enum UMediaErrorCode { network, timeout, unsupportedFormat, decoder, drm, notFound, permission, aborted, cancelled, outOfMemory, unknown }

enum UHwAccel { auto, forced, disabled }

enum USubtitleFormat { srt, vtt, ass, ssa, sub, ttml, lrc, pgs, cea608, cea708 }

enum UMediaFit { contain, cover, fill, fitWidth, fitHeight, none, ratio16x9, ratio4x3, ratio21x9, ratio1x1, original }

enum UAudioFocusPolicy { exclusive, duck, mixWithOthers }

enum UDrmScheme { widevine, fairplay, playready, clearkey }

enum UEqualizerPreset { flat, pop, rock, jazz, classical, dance, bass, treble, vocal, custom }

enum UDownloadState { queued, running, paused, completed, failed, removed }

enum UPipState { unavailable, available, active }

enum UMediaLogLevel { none, error, warning, info, verbose }
