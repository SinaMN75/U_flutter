import "package:u/utilities.dart";

abstract final class UVideoColorMatrix {
  static List<double> identity() => <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

  static List<double> build({double brightness = 0, double contrast = 1, double saturation = 1, double hue = 0}) {
    List<double> matrix = identity();
    if (hue != 0) matrix = multiply(_hue(hue), matrix);
    if (saturation != 1) matrix = multiply(_saturation(saturation), matrix);
    if (contrast != 1) matrix = multiply(_contrast(contrast), matrix);
    if (brightness != 0) matrix = multiply(_brightness(brightness), matrix);
    return matrix;
  }

  static List<double> _brightness(double value) {
    final double offset = value * 255;
    return <double>[1, 0, 0, 0, offset, 0, 1, 0, 0, offset, 0, 0, 1, 0, offset, 0, 0, 0, 1, 0];
  }

  static List<double> _contrast(double value) {
    final double translate = (1 - value) * 127.5;
    return <double>[value, 0, 0, 0, translate, 0, value, 0, 0, translate, 0, 0, value, 0, translate, 0, 0, 0, 1, 0];
  }

  static List<double> _saturation(double value) {
    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;
    final double inverse = 1 - value;
    final double r = lumR * inverse;
    final double g = lumG * inverse;
    final double b = lumB * inverse;
    return <double>[r + value, g, b, 0, 0, r, g + value, b, 0, 0, r, g, b + value, 0, 0, 0, 0, 0, 1, 0];
  }

  static List<double> _hue(double degrees) {
    final double radians = degrees * pi / 180;
    final double cosine = cos(radians);
    final double sine = sin(radians);
    return <double>[
      0.213 + cosine * 0.787 - sine * 0.213, 0.715 - cosine * 0.715 - sine * 0.715, 0.072 - cosine * 0.072 + sine * 0.928, 0, 0,
      0.213 - cosine * 0.213 + sine * 0.143, 0.715 + cosine * 0.285 + sine * 0.140, 0.072 - cosine * 0.072 - sine * 0.283, 0, 0,
      0.213 - cosine * 0.213 - sine * 0.787, 0.715 - cosine * 0.715 + sine * 0.715, 0.072 + cosine * 0.928 + sine * 0.072, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static List<double> multiply(List<double> a, List<double> b) {
    final List<double> result = List<double>.filled(20, 0);
    for (int row = 0; row < 4; row++) {
      for (int column = 0; column < 5; column++) {
        double sum = 0;
        for (int k = 0; k < 4; k++) {
          sum += a[row * 5 + k] * b[k * 5 + column];
        }
        if (column == 4) sum += a[row * 5 + 4];
        result[row * 5 + column] = sum;
      }
    }
    return result;
  }
}

class UVideoFilterLayer extends StatelessWidget {
  const UVideoFilterLayer({required this.settings, required this.child, super.key});

  final UVideoSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: settings,
    builder: (BuildContext context, Widget? built) {
      if (!settings.hasFilters) return built ?? child;
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(
          UVideoColorMatrix.build(
            brightness: settings.brightness,
            contrast: settings.contrast,
            saturation: settings.saturation,
            hue: settings.hue,
          ),
        ),
        child: built ?? child,
      );
    },
    child: child,
  );
}
