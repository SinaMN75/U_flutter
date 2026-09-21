part of "u_admin.dart";

/// Owns the [TextEditingController]s (and [FocusNode]s) a dialog or page creates,
/// and tears them down exactly once, when the widget that shows them is disposed.
///
/// Admin dialogs build a dozen controllers per open. Created bare they are never
/// disposed, so every reopen leaks the whole set. Create them through a bag and
/// hand the dialog's root widget to [scope], which disposes the bag from its own
/// `State.dispose()` — after the closing route has finished its exit transition,
/// which is what makes this safe where a bare `dispose()` after `await` is not.
///
/// ```dart
/// final UAdminFields f = UAdminFields();
/// final TextEditingController title = f.text(p?.title);
/// await UNavigator.dialog(f.scope(StatefulBuilder(builder: ...)));
/// ```
///
/// A bag held by a [State] instead of a dialog is disposed from that state:
///
/// ```dart
/// final UAdminFields f = UAdminFields();
/// @override
/// void dispose() {
///   f.dispose();
///   super.dispose();
/// }
/// ```
class UAdminFields {
  final List<TextEditingController> _controllers = <TextEditingController>[];
  final List<FocusNode> _focusNodes = <FocusNode>[];
  bool _disposed = false;

  /// A [TextEditingController] seeded with [text], owned by this bag.
  TextEditingController text([String? text]) {
    final TextEditingController controller = TextEditingController(text: text);
    _controllers.add(controller);
    return controller;
  }

  /// A [FocusNode] owned by this bag.
  FocusNode focus() {
    final FocusNode node = FocusNode();
    _focusNodes.add(node);
    return node;
  }

  /// Wraps [child] so this bag is disposed when [child] leaves the tree.
  Widget scope(Widget child) => _UAdminFieldsScope(fields: this, child: child);

  /// Disposes everything the bag owns. Safe to call more than once.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final TextEditingController controller in _controllers) {
      controller.dispose();
    }
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }
}

class _UAdminFieldsScope extends StatefulWidget {
  const _UAdminFieldsScope({required this.fields, required this.child});

  final UAdminFields fields;
  final Widget child;

  @override
  State<_UAdminFieldsScope> createState() => _UAdminFieldsScopeState();
}

class _UAdminFieldsScopeState extends State<_UAdminFieldsScope> {
  @override
  void dispose() {
    widget.fields.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
