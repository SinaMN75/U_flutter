part of "u_process.dart";

/// E-signature field for a process step. Wraps [USignaturePad] and forwards the
/// captured signature (base64 PNG) to [onSubmit].
class UProcessESignField extends StatelessWidget {
  const UProcessESignField({
    required this.onSubmit,
    super.key,
    this.title,
    this.saveButtonText,
    this.clearButtonText,
    this.emptyMessage,
    this.initialFile,
    this.initialBase64,
  });

  final ValueChanged<String> onSubmit;
  final String? title;
  final String? saveButtonText;
  final String? clearButtonText;
  final String? emptyMessage;
  final FileData? initialFile;
  final String? initialBase64;

  void _handleSubmit(FileData signature) {
    final String? base64 = signature.bytes?.toBase64();
    if (base64 == null) return;
    onSubmit(base64);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      USignaturePad(
        onSave: _handleSubmit,
        saveButtonText: saveButtonText ?? S.current.saveSignature,
        clearButtonText: clearButtonText ?? S.current.clear,
        emptyMessage: emptyMessage ?? S.current.signFirst,
      ),
    ],
  );
}
