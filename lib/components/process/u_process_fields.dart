part of "u_process.dart";

/// Renders the body of a single process step: an optional message / message-box
/// followed by the step's fields, each mapped to its matching input widget.
class UProcessFields extends StatelessWidget {
  const UProcessFields({
    required this.processStepGet,
    required this.processStepSend,
    this.style = const UProcessStyle(),
    super.key,
  });

  final UProcessStepGet processStepGet;
  final UProcessStepSend processStepSend;
  final UProcessStyle style;

  @override
  Widget build(BuildContext context) {
    final List<UProcessField> fields = processStepGet.fields ?? <UProcessField>[];

    return Column(
      children: <Widget>[
        if ((processStepGet.message ?? "").trim().isNotEmpty) Text(processStepGet.message!).pAll(16),
        if (processStepGet.messageBox != null) _messageBox(messageBox: processStepGet.messageBox!),
        ...fields.map(_field),
      ],
    );
  }

  Widget _field(UProcessField i) {
    if (i.type == TagFieldType.text) return UProcessTextField(field: i, processStepSend: processStepSend);
    // Null-safe file-config checks so a malformed field can't crash the step.
    if (i.type == TagFieldType.file && i.fileConfig?.type == TagFileFieldType.video && (i.fileConfig?.isSelfieCamera ?? false)) {
      return UProcessVisualAuthField(field: i, processStepSend: processStepSend, style: style);
    }
    if (i.type == TagFieldType.eSignature) {
      return UProcessESignField(
        title: i.label,
        initialBase64: i.value,
        onSubmit: (String value) => processStepSend.fields.firstWhere((UProcessField f) => f.key == i.key).value = value,
      );
    }
    if (i.type == TagFieldType.file && i.fileConfig?.type == TagFileFieldType.image) return UProcessImagePickerField(field: i, processStepSend: processStepSend);
    return const SizedBox();
  }

  Widget _messageBox({required UMessageBox messageBox}) => Card(
    child: Column(
      children: <Widget>[
        if (messageBox.svgIcon != null) SvgPicture.string(messageBox.svgIcon!).pSymmetric(vertical: 12),
        UTextTitleLarge(messageBox.title, fontWeight: FontWeight.bold).pSymmetric(vertical: 12),
        UTextBodyMedium(messageBox.description, maxLines: 4, textAlign: TextAlign.center).pSymmetric(vertical: 12),
      ],
    ).pAll(24),
  );
}
