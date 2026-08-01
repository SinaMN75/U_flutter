part of "u_process.dart";

/// Signature capture pad. Renders a drawable canvas plus save / clear buttons
/// and returns the drawing as a PNG [FileData].
class USignaturePad extends StatelessWidget {
  USignaturePad({
    required this.onSave,
    super.key,
    this.saveButtonText,
    this.clearButtonText,
    this.emptyMessage,
    this.onDraw,
  });

  final GlobalKey<SfSignaturePadState> signatureGlobalKey = GlobalKey<SfSignaturePadState>();
  final Function(FileData) onSave;
  final Function(FileData)? onDraw;
  final String? saveButtonText;
  final String? clearButtonText;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Card(
        // Capture the drawing as it's completed so the step's own submit button is the only one needed.
        child: SfSignaturePad(
          key: signatureGlobalKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          strokeColor: Theme.of(context).colorScheme.onSurface,
          minimumStrokeWidth: 1,
          maximumStrokeWidth: 4,
          onDrawEnd: _captureSilently,
        ),
      ),
      const SizedBox(height: 10),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: UButton(
          type: UButtonType.text,
          title: clearButtonText,
          onTap: () => signatureGlobalKey.currentState!.clear(),
        ),
      ),
    ],
  );

  Future<void> _captureSilently() async {
    final SfSignaturePadState? state = signatureGlobalKey.currentState;
    if (state == null || state.toPathList().isEmpty) return;

    final ui.Image data = await state.toImage(pixelRatio: 3);
    final ByteData? bytes = await data.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;

    onSave(FileData(bytes: bytes.buffer.asUint8List(), extension: "png"));
  }

  Future<void> handleSaveButtonPressed({required final String message}) async {
    final SfSignaturePadState? state = signatureGlobalKey.currentState;
    if (state == null) return;

    if (state.toPathList().isEmpty) {
      UToast.error(message: message);
      return;
    }

    final ui.Image data = await state.toImage(pixelRatio: 3);
    final ByteData? bytes = await data.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;

    final Uint8List byte = bytes.buffer.asUint8List();
    onSave(FileData(bytes: byte, extension: "png"));
  }

  Future<bool> hasSignature() async {
    final SfSignaturePadState? state = signatureGlobalKey.currentState;
    if (state == null) return false;

    final List<ui.Path> paths = state.toPathList();
    return paths.isNotEmpty;
  }
}
