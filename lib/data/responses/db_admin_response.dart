part of "../data.dart";

class UDbAdminTableResponse {
  final String schema;
  final String name;
  final int estimatedRows;
  final int columnCount;
  final String? size;

  UDbAdminTableResponse({
    required this.schema,
    required this.name,
    required this.estimatedRows,
    required this.columnCount,
    this.size,
  });

  factory UDbAdminTableResponse.fromJson(String str) => UDbAdminTableResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminTableResponse.fromMap(Map<String, dynamic> json) => UDbAdminTableResponse(
    schema: json["schema"] ?? "public",
    name: json["name"] ?? "",
    estimatedRows: (json["estimatedRows"] ?? 0) as int,
    columnCount: (json["columnCount"] ?? 0) as int,
    size: json["size"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "schema": schema,
    "name": name,
    "estimatedRows": estimatedRows,
    "columnCount": columnCount,
    "size": size,
  };
}

class UDbAdminColumnResponse {
  final String name;
  final String dataType;
  final bool isNullable;
  final bool isPrimaryKey;
  final int ordinalPosition;
  final String? defaultValue;

  UDbAdminColumnResponse({
    required this.name,
    required this.dataType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.ordinalPosition,
    this.defaultValue,
  });

  factory UDbAdminColumnResponse.fromJson(String str) => UDbAdminColumnResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminColumnResponse.fromMap(Map<String, dynamic> json) => UDbAdminColumnResponse(
    name: json["name"] ?? "",
    dataType: json["dataType"] ?? "",
    isNullable: json["isNullable"] ?? false,
    isPrimaryKey: json["isPrimaryKey"] ?? false,
    ordinalPosition: (json["ordinalPosition"] ?? 0) as int,
    defaultValue: json["default"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "name": name,
    "dataType": dataType,
    "isNullable": isNullable,
    "isPrimaryKey": isPrimaryKey,
    "ordinalPosition": ordinalPosition,
    "default": defaultValue,
  };
}

class UDbAdminIndexResponse {
  final String name;
  final String definition;
  final bool isUnique;
  final bool isPrimary;

  UDbAdminIndexResponse({
    required this.name,
    required this.definition,
    required this.isUnique,
    required this.isPrimary,
  });

  factory UDbAdminIndexResponse.fromJson(String str) => UDbAdminIndexResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminIndexResponse.fromMap(Map<String, dynamic> json) => UDbAdminIndexResponse(
    name: json["name"] ?? "",
    definition: json["definition"] ?? "",
    isUnique: json["isUnique"] ?? false,
    isPrimary: json["isPrimary"] ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "name": name,
    "definition": definition,
    "isUnique": isUnique,
    "isPrimary": isPrimary,
  };
}

class UDbAdminForeignKeyResponse {
  final String column;
  final String referencesTable;
  final String referencesColumn;
  final String constraintName;

  UDbAdminForeignKeyResponse({
    required this.column,
    required this.referencesTable,
    required this.referencesColumn,
    required this.constraintName,
  });

  factory UDbAdminForeignKeyResponse.fromJson(String str) => UDbAdminForeignKeyResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminForeignKeyResponse.fromMap(Map<String, dynamic> json) => UDbAdminForeignKeyResponse(
    column: json["column"] ?? "",
    referencesTable: json["referencesTable"] ?? "",
    referencesColumn: json["referencesColumn"] ?? "",
    constraintName: json["constraintName"] ?? "",
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "column": column,
    "referencesTable": referencesTable,
    "referencesColumn": referencesColumn,
    "constraintName": constraintName,
  };
}

class UDbAdminTableSchemaResponse {
  final String schema;
  final String table;
  final List<UDbAdminColumnResponse> columns;
  final List<UDbAdminIndexResponse> indexes;
  final List<UDbAdminForeignKeyResponse> foreignKeys;
  final List<String> primaryKeys;

  UDbAdminTableSchemaResponse({
    required this.schema,
    required this.table,
    required this.columns,
    required this.indexes,
    required this.foreignKeys,
    required this.primaryKeys,
  });

  factory UDbAdminTableSchemaResponse.fromJson(String str) => UDbAdminTableSchemaResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminTableSchemaResponse.fromMap(Map<String, dynamic> json) => UDbAdminTableSchemaResponse(
    schema: json["schema"] ?? "public",
    table: json["table"] ?? "",
    columns: List<UDbAdminColumnResponse>.from((json["columns"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UDbAdminColumnResponse.fromMap(x))),
    indexes: List<UDbAdminIndexResponse>.from((json["indexes"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UDbAdminIndexResponse.fromMap(x))),
    foreignKeys: List<UDbAdminForeignKeyResponse>.from((json["foreignKeys"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UDbAdminForeignKeyResponse.fromMap(x))),
    primaryKeys: List<String>.from((json["primaryKeys"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "schema": schema,
    "table": table,
    "columns": List<dynamic>.from(columns.map((UDbAdminColumnResponse x) => x.toMap())),
    "indexes": List<dynamic>.from(indexes.map((UDbAdminIndexResponse x) => x.toMap())),
    "foreignKeys": List<dynamic>.from(foreignKeys.map((UDbAdminForeignKeyResponse x) => x.toMap())),
    "primaryKeys": List<dynamic>.from(primaryKeys.map((String x) => x)),
  };
}

class UDbAdminQueryResultResponse {
  final List<String> columns;
  final List<String?> columnTypes;
  final List<Map<String,String?>> rows;
  final int rowCount;
  final int executionMs;
  final bool truncated;
  final int? affectedRows;
  final String? primaryKeyColumn;

  UDbAdminQueryResultResponse({
    required this.columns,
    required this.columnTypes,
    required this.rows,
    required this.rowCount,
    required this.executionMs,
    required this.truncated,
    this.affectedRows,
    this.primaryKeyColumn,
  });

  factory UDbAdminQueryResultResponse.fromJson(String str) => UDbAdminQueryResultResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminQueryResultResponse.fromMap(Map<String, dynamic> json) => UDbAdminQueryResultResponse(
    columns: List<String>.from((json["columns"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())),
    columnTypes: List<String?>.from((json["columnTypes"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x?.toString())),
    rows: List<Map<String, String?>>.from((json["rows"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => (x as Map<String, dynamic>).map((String k, dynamic v) => MapEntry<String, String?>(k, v?.toString())))),
    rowCount: (json["rowCount"] ?? 0) as int,
    executionMs: (json["executionMs"] ?? 0) as int,
    truncated: json["truncated"] ?? false,
    affectedRows: json["affectedRows"],
    primaryKeyColumn: json["primaryKeyColumn"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "columns": List<dynamic>.from(columns.map((String x) => x)),
    "columnTypes": columnTypes,
    "rows": rows,
    "rowCount": rowCount,
    "executionMs": executionMs,
    "truncated": truncated,
    "affectedRows": affectedRows,
    "primaryKeyColumn": primaryKeyColumn,
  };
}
