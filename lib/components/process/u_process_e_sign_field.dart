part of "u_process.dart";

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
        saveButtonText: saveButtonText ?? U.s.saveSignature,
        clearButtonText: clearButtonText ?? U.s.clear,
        emptyMessage: emptyMessage ?? U.s.pleaseAddYourSignatureFirst,
      ),
    ],
  );
}
