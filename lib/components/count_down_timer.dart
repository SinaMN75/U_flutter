import "package:u/utilities.dart";

class USendAgainCountDown extends StatefulWidget {
  const USendAgainCountDown({
    required this.counter,
    required this.onSendAgainTap,
    required this.buttonTitle,
    required this.counterDescription,
    super.key,
  });

  final int counter;
  final VoidCallback onSendAgainTap;
  final String buttonTitle;
  final String counterDescription;

  @override
  State<USendAgainCountDown> createState() => _USendAgainCountDownState();
}

class _USendAgainCountDownState extends State<USendAgainCountDown> {
  int counter = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void didUpdateWidget(covariant USendAgainCountDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.counter != oldWidget.counter) startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => counter <= 0
      ? TextButton(
          onPressed: widget.onSendAgainTap,
          child: UTextLabelLarge(widget.buttonTitle, color: Theme.of(context).colorScheme.primary),
        )
      : TextButton(
          onPressed: null,
          child: UTextLabelLarge("$counter ${widget.counterDescription}", color: Theme.of(context).colorScheme.primary),
        );

  void startTimer() {
    timer?.cancel();
    counter = widget.counter;
    // A counter that starts at 0 (or below) must not spin up a timer at
    // all: the previous version decremented past zero forever, since its
    // stop condition (`counter == 0`) can only ever be true BEFORE the
    // first tick, never after.
    if (counter <= 0) return;
    timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => counter--);
      if (counter <= 0) timer.cancel();
    });
  }
}
