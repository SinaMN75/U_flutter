import "package:u/utilities.dart";

double _dialogWidth(BuildContext context, double max) {
  final double available = MediaQuery.sizeOf(context).width - 48;
  return available < max ? available : max;
}

/// A dialog around a [Form]: Submit validates it, runs [onSubmit] with a loading button,
/// and closes the dialog when [onSubmit] returns true.
class UFormDialog extends StatefulWidget {
  const UFormDialog({required this.title, required this.onSubmit, required this.children, super.key, this.maxWidth = 480});

  final String title;
  final Future<bool> Function() onSubmit;
  final List<Widget> Function(BuildContext context, StateSetter setState) children;
  final double maxWidth;

  static Future<void> show({
    required String title,
    required Future<bool> Function() onSubmit,
    required List<Widget> Function(BuildContext context, StateSetter setState) children,
    double maxWidth = 480,
  }) => UNavigator.dialog<void>(UFormDialog(title: title, onSubmit: onSubmit, maxWidth: maxWidth, children: children));

  @override
  State<UFormDialog> createState() => _UFormDialogState();
}

class _UFormDialogState extends State<UFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final bool ok = await widget.onSubmit();
    if (!mounted) return;
    if (ok) return UNavigator.back();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: _dialogWidth(context, widget.maxWidth),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ...widget.children(context, setState),
              const SizedBox(height: 20),
              UButtonSubmitCancel(isLoading: _saving, onSubmit: _submit),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A filter dialog: "Filter" closes it and runs [onApply], "Clear filters" closes it and runs [onClear].
class UFilterDialog extends StatefulWidget {
  const UFilterDialog({required this.title, required this.onApply, required this.onClear, required this.children, super.key});

  final String title;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final List<Widget> Function(StateSetter setState) children;

  static Future<void> show({
    required String title,
    required VoidCallback onApply,
    required VoidCallback onClear,
    required List<Widget> Function(StateSetter setState) children,
  }) => UNavigator.dialog<void>(UFilterDialog(title: title, onApply: onApply, onClear: onClear, children: children));

  @override
  State<UFilterDialog> createState() => _UFilterDialogState();
}

class _UFilterDialogState extends State<UFilterDialog> {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: _dialogWidth(context, 420),
      child: SingleChildScrollView(
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ...widget.children(setState),
            const SizedBox(height: 20),
            UButtonSubmitCancel(
              submitTitle: U.s.filter,
              cancelTitle: U.s.clearFilters,
              onSubmit: () {
                UNavigator.back();
                widget.onApply();
              },
              onCancel: () {
                UNavigator.back();
                widget.onClear();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Two form fields side by side, stacked on narrow (phone-width) screens.
class UFieldPair extends StatelessWidget {
  const UFieldPair(this.first, this.second, {super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width < 720
      ? UColumn(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          margin: const EdgeInsets.symmetric(vertical: 6),
          children: <Widget>[first, second],
        )
      : URow(
          crossAxisAlignment: CrossAxisAlignment.start,
          margin: const EdgeInsets.symmetric(vertical: 6),
          children: <Widget>[first.expanded(), const SizedBox(width: 10), second.expanded()],
        );
}
