part of "u_process.dart";

/// Camera image field for a process step. Captures a photo, stores it as base64
/// on the matching [processStepSend] field, and shows any admin rejection note.
class UProcessImagePickerField extends StatefulWidget {
  const UProcessImagePickerField({
    required this.field,
    required this.processStepSend,
    super.key,
  });

  final UProcessField field;
  final UProcessStepSend processStepSend;

  @override
  State<UProcessImagePickerField> createState() => _UProcessImagePickerFieldState();
}

class _UProcessImagePickerFieldState extends State<UProcessImagePickerField> {
  FileData? _fileData;

  @override
  void initState() {
    if (widget.field.value != null) _fileData = FileData(bytes: widget.field.value!.toBytesFromBase64());
    super.initState();
  }

  Future<void> _pick() async {
    await UFile.showImagePicker(
      source: UImageSource.camera,
      isSelfie: widget.field.fileConfig?.isSelfieCamera ?? false,
      action: (List<FileData> files) {
        if (files.isEmpty) return;
        final FileData file = files.first;
        setState(() => _fileData = file);
        widget.processStepSend.fields.firstWhere((UProcessField f) => f.key == widget.field.key).value = file.bytes?.toBase64();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UContainer(
          margin: const EdgeInsets.symmetric(vertical: 4),
          border: Border.all(color: scheme.outlineVariant, width: 1.5),
          radius: 16,
          height: 200,
          color: scheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: _fileData != null
              ? UImage("", fileData: _fileData, borderRadius: 16)
              : UIconTextVertical(
                  leading: Icon(Icons.add_a_photo_rounded, size: 48, color: scheme.onSurfaceVariant),
                  trailing: UTextBodyMedium(widget.field.label, color: scheme.onSurfaceVariant),
                  spaceBetween: 12,
                ),
        ).onTap(_pick),
        if (widget.field.rejectionReason != null)
          UIconTextHorizontal(
            leading: Icon(Icons.error_outline, color: scheme.error),
            trailing: UTextBodyMedium("${S.current.adminMessage}: ${widget.field.rejectionReason}", color: scheme.error),
          ).pOnly(bottom: 12),
      ],
    );
  }
}
