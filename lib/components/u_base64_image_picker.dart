import "package:u/utilities.dart";

/// Picks one image and reports it as a base64 string ([onChanged] gets null when it's cleared).
/// Shows the current image, or an "add photo" box when there is none.
class UBase64ImagePicker extends StatefulWidget {
  const UBase64ImagePicker({required this.label, required this.initial, required this.onChanged, super.key});

  final String label;
  final String? initial;
  final ValueChanged<String?> onChanged;

  @override
  State<UBase64ImagePicker> createState() => _UBase64ImagePickerState();
}

class _UBase64ImagePickerState extends State<UBase64ImagePicker> {
  String? _value;

  @override
  void initState() {
    _value = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? value = _value;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UTextBodySmall(widget.label, color: scheme.onSurfaceVariant, margin: const EdgeInsets.only(bottom: 4)),
        Stack(
          children: <Widget>[
            UContainer(
              onTap: () => UFile.showFilePicker(
                allowedExtensions: const <String>["jpg", "jpeg", "png", "gif", "webp", "svg"],
                action: (List<UFileData> files) {
                  if (files.isEmpty || files.first.bytes == null) return;
                  final String encoded = files.first.bytes!.toBase64();
                  setState(() => _value = encoded);
                  widget.onChanged(encoded);
                },
              ),
              height: 96,
              width: double.infinity,
              radius: 12,
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              // A stored value may carry a "data:image/...;base64," prefix.
              child: value.isNotNullOrEmpty()
                  ? UImage("", fileData: UFileData(bytes: (value!.contains(",") ? value.split(",").last : value).toBytesFromBase64()), borderRadius: 12)
                  : Icon(Icons.add_photo_alternate_outlined, size: 32, color: scheme.onSurfaceVariant),
            ),
            if (value.isNotNullOrEmpty())
              Positioned(
                top: 4,
                right: 4,
                child: UContainer(
                  onTap: () {
                    setState(() => _value = null);
                    widget.onChanged(null);
                  },
                  color: scheme.error,
                  shape: BoxShape.circle,
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: scheme.onError),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
