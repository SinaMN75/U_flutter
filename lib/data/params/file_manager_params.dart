part of "../data.dart";

class UFileManagerBrowseParams {
  UFileManagerBrowseParams({this.path = ""});

  final String path;

  Map<String, dynamic> toMap() => <String, dynamic>{"path": path};

  factory UFileManagerBrowseParams.fromMap(Map<String, dynamic> json) => UFileManagerBrowseParams(
    path: json["path"],
  );

  String toJson() => json.encode(toMap());

  factory UFileManagerBrowseParams.fromJson(String str) => UFileManagerBrowseParams.fromMap(json.decode(str));
}

class UFileManagerCreateFolderParams {
  UFileManagerCreateFolderParams({required this.name, this.path = ""});

  final String path;
  final String name;

  Map<String, dynamic> toMap() => <String, dynamic>{"path": path, "name": name};

  factory UFileManagerCreateFolderParams.fromMap(Map<String, dynamic> json) => UFileManagerCreateFolderParams(
    path: json["path"],
    name: json["name"],
  );

  String toJson() => json.encode(toMap());

  factory UFileManagerCreateFolderParams.fromJson(String str) => UFileManagerCreateFolderParams.fromMap(json.decode(str));
}

class UFileManagerRenameParams {
  UFileManagerRenameParams({required this.path, required this.newName});

  final String path;
  final String newName;

  Map<String, dynamic> toMap() => <String, dynamic>{"path": path, "newName": newName};

  factory UFileManagerRenameParams.fromMap(Map<String, dynamic> json) => UFileManagerRenameParams(
    path: json["path"],
    newName: json["newName"],
  );

  String toJson() => json.encode(toMap());

  factory UFileManagerRenameParams.fromJson(String str) => UFileManagerRenameParams.fromMap(json.decode(str));
}

class UFileManagerMoveParams {
  UFileManagerMoveParams({required this.path, this.destination = ""});

  final String path;
  final String destination;

  Map<String, dynamic> toMap() => <String, dynamic>{"path": path, "destination": destination};

  factory UFileManagerMoveParams.fromMap(Map<String, dynamic> json) => UFileManagerMoveParams(
    path: json["path"],
    destination: json["destination"],
  );

  String toJson() => json.encode(toMap());

  factory UFileManagerMoveParams.fromJson(String str) => UFileManagerMoveParams.fromMap(json.decode(str));
}

class UFileManagerDeleteParams {
  UFileManagerDeleteParams({required this.path});

  final String path;

  Map<String, dynamic> toMap() => <String, dynamic>{"path": path};

  factory UFileManagerDeleteParams.fromMap(Map<String, dynamic> json) => UFileManagerDeleteParams(
    path: json["path"],
  );

  String toJson() => json.encode(toMap());

  factory UFileManagerDeleteParams.fromJson(String str) => UFileManagerDeleteParams.fromMap(json.decode(str));
}

class UFileManagerUploadParams {
  UFileManagerUploadParams({required this.file, this.path = ""});

  final FileData file;
  final String path;

  Map<String, dynamic> toMap() => <String, dynamic>{"path": path};

  String toJson() => json.encode(toMap());
}
