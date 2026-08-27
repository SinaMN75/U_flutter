part of "u_process.dart";

/// Horizontal stepper showing each step's verification status.
class UProcessStepsIndicator extends StatelessWidget {
  const UProcessStepsIndicator({
    required this.steps,
    this.style = const UProcessStyle(),
    super.key,
  });

  final List<UProcessStepStatus> steps;
  final UProcessStyle style;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Row(
      children: List<Widget>.generate(steps.length, (int i) {
        final UProcessStepStatus step = steps[i];
        final bool isLast = i == steps.length - 1;

        return Row(
          children: <Widget>[
            UIconTextVertical(
              leading: _StepDot(status: step.status, style: style),
              trailing: UTextLabelSmall(
                step.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: _labelColor(context, step.status),
                fontWeight: step.status == TagProcessStepStatus.current ? FontWeight.bold : FontWeight.normal,
                expanded: 3,
              ),
            ),
            if (!isLast)
              UContainer(
                height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                color: _lineColor(context, step.status),
                expanded: 1,
              ),
          ],
        ).expanded();
      }),
    ).pAll(8);
  }

  Color _labelColor(BuildContext context, TagProcessStepStatus s) {
    switch (s) {
      case TagProcessStepStatus.verified:
        return style.verified(context);
      case TagProcessStepStatus.current:
        return style.current(context);
      case TagProcessStepStatus.awaitingVerification:
        return style.awaiting(context);
      case TagProcessStepStatus.notStarted:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Color _lineColor(BuildContext context, TagProcessStepStatus s) => s == TagProcessStepStatus.verified ? style.verified(context) : Theme.of(context).colorScheme.outlineVariant;
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.status, required this.style});

  final TagProcessStepStatus status;
  final UProcessStyle style;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    switch (status) {
      case TagProcessStepStatus.verified:
        return CircleAvatar(
          radius: 14,
          backgroundColor: style.verified(context),
          child: Icon(Icons.check, color: style.onAccent(context), size: 16),
        );
      case TagProcessStepStatus.current:
        return CircleAvatar(
          radius: 14,
          backgroundColor: style.current(context),
          child: Icon(Icons.edit, color: scheme.onPrimary, size: 16),
        );
      case TagProcessStepStatus.awaitingVerification:
        return CircleAvatar(
          radius: 14,
          backgroundColor: style.awaiting(context),
          child: Icon(Icons.hourglass_top, color: style.onAccent(context), size: 16),
        );
      case TagProcessStepStatus.notStarted:
        return CircleAvatar(
          radius: 14,
          backgroundColor: scheme.outlineVariant,
        );
    }
  }
}
