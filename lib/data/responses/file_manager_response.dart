part of "../data.dart";

class UFileManagerEntryResponse {
  UFileManagerEntryResponse({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
    this.extension,
    this.url,
  });

  factory UFileManagerEntryResponse.fromMap(Map<String, dynamic> json) => UFileManagerEntryResponse(
    name: json["name"] ?? "",
    path: json["path"] ?? "",
    isDirectory: json["isDirectory"] ?? false,
    size: json["size"] ?? 0,
    modifiedAt: DateTime.tryParse(json["modifiedAt"]?.toString() ?? "") ?? DateTime.now(),
    extension: json["extension"],
    url: json["url"],
  );

  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedAt;
  final String? extension;
  final String? url;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "name": name,
    "path": path,
    "isDirectory": isDirectory,
    "size": size,
    "modifiedAt": modifiedAt.toIso8601String(),
    "extension": extension,
    "url": url,
  };

  String toJson() => json.encode(toMap());

  factory UFileManagerEntryResponse.fromJson(String str) => UFileManagerEntryResponse.fromMap(json.decode(str));
}

class UFileManagerListResponse {
  UFileManagerListResponse({
    required this.path,
    required this.directories,
    required this.files,
    required this.totalSize,
  });

  factory UFileManagerListResponse.fromMap(Map<String, dynamic> json) => UFileManagerListResponse(
    path: json["path"] ?? "",
    directories: List<UFileManagerEntryResponse>.from((json["directories"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UFileManagerEntryResponse.fromMap(x))),
    files: List<UFileManagerEntryResponse>.from((json["files"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UFileManagerEntryResponse.fromMap(x))),
    totalSize: json["totalSize"] ?? 0,
  );

  final String path;
  final List<UFileManagerEntryResponse> directories;
  final List<UFileManagerEntryResponse> files;
  final int totalSize;

  List<UFileManagerEntryResponse> get all => <UFileManagerEntryResponse>[...directories, ...files];

  Map<String, dynamic> toMap() => <String, dynamic>{
    "path": path,
    "directories": List<dynamic>.from(directories.map((UFileManagerEntryResponse x) => x.toMap())),
    "files": List<dynamic>.from(files.map((UFileManagerEntryResponse x) => x.toMap())),
    "totalSize": totalSize,
  };

  String toJson() => json.encode(toMap());

  factory UFileManagerListResponse.fromJson(String str) => UFileManagerListResponse.fromMap(json.decode(str));
}
