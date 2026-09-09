import "package:u/utilities.dart";

class UVideoSettings extends ChangeNotifier {
  UVideoSettings({this._fit = UMediaFit.contain, this._subtitleStyle = const USubtitleStyleConfig()});

  UMediaFit _fit;
  double _zoom = 1;
  int _rotation = 0;
  bool _mirrored = false;
  double _screenBrightness = 1;
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;
  double _hue = 0;
  bool _showStats = false;
  USubtitleStyleConfig _subtitleStyle;
  double _subtitleScale = 1;
  Duration _subtitleDelay = Duration.zero;
  Duration? _repeatStart;
  Duration? _repeatEnd;
  Timer? _sleepTimer;
  DateTime? _sleepAt;

  UMediaFit get fit => _fit;

  double get zoom => _zoom;

  int get rotation => _rotation;

  bool get mirrored => _mirrored;

  double get screenBrightness => _screenBrightness;

  double get brightness => _brightness;

  double get contrast => _contrast;

  double get saturation => _saturation;

  double get hue => _hue;

  bool get showStats => _showStats;

  USubtitleStyleConfig get subtitleStyle => _subtitleStyle;

  double get subtitleScale => _subtitleScale;

  Duration get subtitleDelay => _subtitleDelay;

  Duration? get repeatStart => _repeatStart;

  Duration? get repeatEnd => _repeatEnd;

  DateTime? get sleepAt => _sleepAt;

  bool get hasFilters => _brightness != 0 || _contrast != 1 || _saturation != 1 || _hue != 0;

  bool get hasAbRepeat => _repeatStart != null && _repeatEnd != null;

  set fit(UMediaFit value) {
    _fit = value;
    notifyListeners();
  }

  set zoom(double value) {
    _zoom = value.clamp(1, 4).toDouble();
    notifyListeners();
  }

  set rotation(int value) {
    _rotation = value % 360;
    notifyListeners();
  }

  set mirrored(bool value) {
    _mirrored = value;
    notifyListeners();
  }

  set screenBrightness(double value) {
    _screenBrightness = value.clamp(0.05, 1).toDouble();
    notifyListeners();
  }

  set brightness(double value) {
    _brightness = value.clamp(-1, 1).toDouble();
    notifyListeners();
  }

  set contrast(double value) {
    _contrast = value.clamp(0, 3).toDouble();
    notifyListeners();
  }

  set saturation(double value) {
    _saturation = value.clamp(0, 3).toDouble();
    notifyListeners();
  }

  set hue(double value) {
    _hue = value.clamp(-180, 180).toDouble();
    notifyListeners();
  }

  set showStats(bool value) {
    _showStats = value;
    notifyListeners();
  }

  set subtitleStyle(USubtitleStyleConfig value) {
    _subtitleStyle = value;
    notifyListeners();
  }

  set subtitleScale(double value) {
    _subtitleScale = value.clamp(0.5, 3).toDouble();
    notifyListeners();
  }

  void setSubtitleDelay(UMediaController controller, Duration value) {
    _subtitleDelay = value;
    controller.setSubtitleDelay(value);
    notifyListeners();
  }

  void cycleFit() {
    const List<UMediaFit> order = <UMediaFit>[UMediaFit.contain, UMediaFit.cover, UMediaFit.fill, UMediaFit.ratio16x9, UMediaFit.ratio4x3, UMediaFit.original];
    final int index = order.indexOf(_fit);
    fit = order[(index + 1) % order.length];
  }

  void rotateQuarter() => rotation = _rotation + 90;

  void resetFilters() {
    _brightness = 0;
    _contrast = 1;
    _saturation = 1;
    _hue = 0;
    notifyListeners();
  }

  void resetView() {
    _zoom = 1;
    _rotation = 0;
    _mirrored = false;
    _fit = UMediaFit.contain;
    notifyListeners();
  }

  void markRepeatStart(Duration position) {
    _repeatStart = position;
    _repeatEnd = null;
    notifyListeners();
  }

  void markRepeatEnd(Duration position) {
    if (_repeatStart == null || position <= _repeatStart!) return;
    _repeatEnd = position;
    notifyListeners();
  }

  void clearRepeat() {
    _repeatStart = null;
    _repeatEnd = null;
    notifyListeners();
  }

  void startSleepTimer(Duration duration, VoidCallback onElapsed) {
    _sleepTimer?.cancel();
    _sleepAt = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      _sleepAt = null;
      onElapsed();
      notifyListeners();
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}
