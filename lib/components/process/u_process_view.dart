part of "u_process.dart";

/// Full-screen, self-contained multi-step process flow. Fully generic: give it
/// a [processId] and it works with no wrapper. [onCompleted] is optional — when
/// omitted the screen simply closes on completion; pass it only when a specific
/// process needs custom post-completion routing. Optionally pass a [style] to
/// match the host app's brand.
class UProcessView extends StatefulWidget {
  const UProcessView({
    required this.processId,
    this.onCompleted,
    this.style = const UProcessStyle(),
    super.key,
  });

  final String processId;
  final VoidCallback? onCompleted;
  final UProcessStyle style;

  /// One-liner to push any process: `UProcessView.open("kyc")`. Avoids needing a
  /// dedicated page per process.
  static Future<void> open(
    String processId, {
    VoidCallback? onCompleted,
    UProcessStyle style = const UProcessStyle(),
  }) => UNavigator.push(UProcessView(processId: processId, onCompleted: onCompleted, style: style));

  @override
  State<UProcessView> createState() => _UProcessViewState();
}

class _UProcessViewState extends State<UProcessView> {
  late final UProcessController c = UProcessController(onCompleted: widget.onCompleted);

  @override
  void initState() {
    super.initState();
    c.init(processId: widget.processId);
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    if (c.state.isLoading()) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (c.state.isError())
      return UScaffold(
        appBar: AppBar(),
        body: UIconTextVertical(
          leading: UTextBodyMedium(U.s.errorLoadingData),
          trailing: UButton(title: U.s.tryAgain, onTap: c.read),
        ),
      );

    if (c.state.isLoaded()) {
      final UProcessStepGet step = c.processStep.value!;
      final bool hasFields = (step.fields ?? <UProcessField>[]).isNotEmpty;
      final bool hasMessageBox = step.messageBox != null;

      return UScaffold(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        appBar: AppBar(title: Text(step.title)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: hasFields || hasMessageBox
            ? UButton(
                width: MediaQuery.sizeOf(context).width,
                title: hasFields ? U.s.submit : U.s.confirm,
                onTap: hasFields ? c.send : c.dismiss,
              ).pSymmetric(horizontal: 20)
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            UProcessStepsIndicator(steps: step.steps, style: widget.style),
            SingleChildScrollView(
              child: UProcessFields(processStepGet: step, processStepSend: c.processStepSend, style: widget.style),
            ).expanded(),
            if (hasFields) const SizedBox(height: 80),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  });
}
