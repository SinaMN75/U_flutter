import "package:path/path.dart" as path;
import "package:u/utilities.dart";

class UFilePicker extends StatefulWidget {
  const UFilePicker({
    required this.onFilesChanged,
    super.key,
    this.initialFiles = const <FileData>[],
    this.allowMultipleSelection = true,
    this.selectFileTitle = "Select Files",
    this.imageTypes = const <String>["jpg", "jpeg", "png", "gif", "bmp", "webp"],
    this.videoTypes = const <String>["mp4", "mov", "avi", "mkv", "webm"],
    this.documentTypes = const <String>["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt"],
    this.fileType = FileType.custom,
  });

  final List<FileData> initialFiles;
  final ValueChanged<List<FileData>> onFilesChanged;
  final bool allowMultipleSelection;
  final String selectFileTitle;
  final List<String> imageTypes;
  final List<String> videoTypes;
  final List<String> documentTypes;
  final FileType fileType;

  @override
  State<UFilePicker> createState() => _UFilePickerState();
}

class _UFilePickerState extends State<UFilePicker> {
  late List<FileData> _selectedFiles;

  @override
  void initState() {
    super.initState();
    _selectedFiles = List<FileData>.from(widget.initialFiles);
  }

  Future<void> _pickFiles() async {
    await UFile.showFilePicker(
      action: (List<FileData> newFiles) {
        if (newFiles.isEmpty) return;
        if (!mounted) return;
        setState(() {
          if (widget.allowMultipleSelection)
            _selectedFiles.addAll(newFiles);
          else
            _selectedFiles = newFiles;
          _notifyParent();
        });
      },
      allowMultiple: widget.allowMultipleSelection,
      fileType: widget.fileType,
      allowedExtensions: <String>[...widget.imageTypes, ...widget.videoTypes, ...widget.documentTypes],
    );
  }

  void _removeFile(FileData file) => setState(() {
    _selectedFiles.remove(file);
    _notifyParent();
  });

  void _notifyParent() => widget.onFilesChanged(List<FileData>.from(_selectedFiles));

  List<FileData> _getFilesByType(String type) {
    switch (type) {
      case "image":
        return _selectedFiles.where((FileData file) => widget.imageTypes.contains(file.extension?.toLowerCase())).toList();
      case "video":
        return _selectedFiles.where((FileData file) => widget.videoTypes.contains(file.extension?.toLowerCase())).toList();
      case "document":
        return _selectedFiles.where((FileData file) => widget.documentTypes.contains(file.extension?.toLowerCase())).toList();
      default:
        return <FileData>[];
    }
  }

  Widget _buildFileList(String title, String type, IconData icon) {
    final List<FileData> files = _getFilesByType(type);
    if (files.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                "$title (${files.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: files
                  .map(
                    (FileData file) => ListTile(
                      leading: Icon(_getFileIcon(file.extension)),
                      title: Text(
                        _getFileName(file),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _formatFileSize(file.bytes?.length ?? 0),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeFile(file),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getFileName(FileData file) {
    if (file.path != null) return path.basename(file.path!);
    if (file.url != null) return path.basename(file.url!);
    return "Unknown file";
  }

  IconData _getFileIcon(String? extension) {
    if (extension == null) return Icons.insert_drive_file;

    final String ext = extension.toLowerCase();
    if (widget.imageTypes.contains(ext)) {
      return Icons.image;
    } else if (widget.videoTypes.contains(ext)) {
      return Icons.videocam;
    } else if (ext == "pdf") {
      return Icons.picture_as_pdf;
    } else if (<String>["doc", "docx"].contains(ext)) {
      return Icons.article;
    } else if (<String>["xls", "xlsx"].contains(ext)) {
      return Icons.table_chart;
    } else if (<String>["ppt", "pptx"].contains(ext)) {
      return Icons.slideshow;
    } else if (ext == "txt") {
      return Icons.text_snippet;
    }
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const List<String> suffixes = <String>["B", "KB", "MB", "GB", "TB"];
    final int i = (log(bytes) / log(1024)).floor();
    return "${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      ElevatedButton(
        onPressed: _pickFiles,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.attach_file),
            const SizedBox(width: 8),
            Text(widget.selectFileTitle),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (_selectedFiles.isNotEmpty) ...<Widget>[
        _buildFileList("Images", "image", Icons.photo_library),
        _buildFileList("Videos", "video", Icons.video_library),
        _buildFileList("Documents", "document", Icons.library_books),
      ],
    ],
  );
}
