import "package:u/utilities.dart";

class ScrollingText extends StatefulWidget {
  const ScrollingText({
    required this.text,
    super.key,
    this.textStyle,
    this.maxLengthForScrolling = 10,
    this.color,
    this.height,
    this.width,
    this.textAlign,
    this.scrollAxis = Axis.horizontal,
    this.ratioOfBlankToScreen = 0.25,
  });

  final String text;
  final TextStyle? textStyle;
  final int maxLengthForScrolling;
  final Axis scrollAxis;
  final TextAlign? textAlign;
  final Color? color;
  final double? height;
  final double? width;
  final double ratioOfBlankToScreen;

  @override
  State<StatefulWidget> createState() => ScrollingTextState();
}

class ScrollingTextState extends State<ScrollingText> with SingleTickerProviderStateMixin {
  late ScrollController scrollController;
  double? screenWidth;
  double? screenHeight;
  double position = 0;
  Timer? timer;
  final double _moveDistance = 3;
  final int _timerRest = 100;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((final Duration callback) {
      startTimer();
    });
  }

  void startTimer() {
    if (_key.currentContext != null) {
      final double widgetWidth = _key.currentContext!.findRenderObject()!.paintBounds.size.width;
      final double widgetHeight = _key.currentContext!.findRenderObject()!.paintBounds.size.height;

      timer = Timer.periodic(Duration(milliseconds: _timerRest), (final Timer timer) {
        final double maxScrollExtent = scrollController.position.maxScrollExtent;
        final double pixels = scrollController.position.pixels;
        if (pixels + _moveDistance >= maxScrollExtent) {
          if (widget.scrollAxis == Axis.horizontal) {
            position = (maxScrollExtent - screenWidth! * widget.ratioOfBlankToScreen + widgetWidth) / 2 - widgetWidth + pixels - maxScrollExtent;
          } else {
            position = (maxScrollExtent - screenHeight! * widget.ratioOfBlankToScreen + widgetHeight) / 2 - widgetHeight + pixels - maxScrollExtent;
          }
          scrollController.jumpTo(position);
        }
        position += _moveDistance;
        scrollController.animateTo(
          position,
          duration: Duration(milliseconds: _timerRest),
          curve: Curves.linear,
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(navigatorKey.currentContext!).size.width;
    screenHeight = MediaQuery.of(navigatorKey.currentContext!).size.height;
  }

  Widget getBothEndsChild() {
    if (widget.scrollAxis == Axis.vertical) {
      final String newString = widget.text.split("").join("\n");
      return Center(
        child: Text(
          newString,
          style: widget.textStyle,
          textAlign: widget.textAlign ?? TextAlign.center,
        ),
      );
    }
    return Center(
      child: Text(widget.text, style: widget.textStyle, textAlign: widget.textAlign ?? TextAlign.center),
    );
  }

  Widget getCenterChild() {
    if (widget.scrollAxis == Axis.horizontal) {
      return Container(width: screenWidth! * widget.ratioOfBlankToScreen);
    } else {
      return Container(height: screenHeight! * widget.ratioOfBlankToScreen);
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (timer != null) {
      timer!.cancel();
    }
  }

  @override
  Widget build(final BuildContext context) => Container(
    height: widget.height ?? 30,
    width: widget.width,
    color: widget.color,
    child: widget.text.length > widget.maxLengthForScrolling
        ? ListView(
            key: _key,
            scrollDirection: widget.scrollAxis,
            controller: scrollController,
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              getBothEndsChild(),
              getCenterChild(),
              getBothEndsChild(),
            ],
          )
        : Text(
            widget.text,
            style: widget.textStyle,
            textAlign: widget.textAlign ?? TextAlign.start,
          ),
  );
}
