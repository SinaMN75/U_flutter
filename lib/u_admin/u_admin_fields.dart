part of "u_admin.dart";

/// Owns the [TextEditingController]s (and [FocusNode]s) a controller creates, and disposes them all at once.
/// Every [UBaseController] has one as `fields`: declare `late final TextEditingController title = fields.text();`
/// and it is disposed with the controller.
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
