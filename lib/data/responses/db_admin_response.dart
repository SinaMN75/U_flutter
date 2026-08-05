part of "../data.dart";

class UDbTableResponse {
  UDbTableResponse({
    required this.schema,
    required this.name,
    required this.estimatedRows,
    required this.columnCount,
    this.size,
  });

  factory UDbTableResponse.fromMap(Map<String, dynamic> json) => UDbTableResponse(
    schema: json["schema"] ?? "public",
    name: json["name"] ?? "",
    estimatedRows: (json["estimatedRows"] ?? 0) as int,
    columnCount: (json["columnCount"] ?? 0) as int,
    size: json["size"],
  );

  final String schema;
  final String name;
  final int estimatedRows;
  final int columnCount;
  final String? size;
}

class UDbColumnResponse {
  UDbColumnResponse({
    required this.name,
    required this.dataType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.ordinalPosition,
    this.defaultValue,
  });

  factory UDbColumnResponse.fromMap(Map<String, dynamic> json) => UDbColumnResponse(
    name: json["name"] ?? "",
    dataType: json["dataType"] ?? "",
    isNullable: json["isNullable"] ?? false,
    isPrimaryKey: json["isPrimaryKey"] ?? false,
    ordinalPosition: (json["ordinalPosition"] ?? 0) as int,
    defaultValue: json["default"],
  );

  final String name;
  final String dataType;
  final bool isNullable;
  final bool isPrimaryKey;
  final int ordinalPosition;
  final String? defaultValue;
}

class UDbIndexResponse {
  UDbIndexResponse({required this.name, required this.definition, required this.isUnique, required this.isPrimary});

  factory UDbIndexResponse.fromMap(Map<String, dynamic> json) => UDbIndexResponse(
    name: json["name"] ?? "",
    definition: json["definition"] ?? "",
    isUnique: json["isUnique"] ?? false,
    isPrimary: json["isPrimary"] ?? false,
  );

  final String name;
  final String definition;
  final bool isUnique;
  final bool isPrimary;
}

class UDbForeignKeyResponse {
  UDbForeignKeyResponse({
    required this.column,
    required this.referencesTable,
    required this.referencesColumn,
    required this.constraintName,
  });

  factory UDbForeignKeyResponse.fromMap(Map<String, dynamic> json) => UDbForeignKeyResponse(
    column: json["column"] ?? "",
    referencesTable: json["referencesTable"] ?? "",
    referencesColumn: json["referencesColumn"] ?? "",
    constraintName: json["constraintName"] ?? "",
  );

  final String column;
  final String referencesTable;
  final String referencesColumn;
  final String constraintName;
}

class UDbTableSchemaResponse {
  UDbTableSchemaResponse({
    required this.schema,
    required this.table,
    required this.columns,
    required this.indexes,
    required this.foreignKeys,
    required this.primaryKeys,
  });

  factory UDbTableSchemaResponse.fromMap(Map<String, dynamic> json) => UDbTableSchemaResponse(
    schema: json["schema"] ?? "public",
    table: json["table"] ?? "",
    columns: List<UDbColumnResponse>.from((json["columns"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UDbColumnResponse.fromMap(x))),
    indexes: List<UDbIndexResponse>.from((json["indexes"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UDbIndexResponse.fromMap(x))),
    foreignKeys: List<UDbForeignKeyResponse>.from((json["foreignKeys"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => UDbForeignKeyResponse.fromMap(x))),
    primaryKeys: List<String>.from((json["primaryKeys"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())),
  );

  final String schema;
  final String table;
  final List<UDbColumnResponse> columns;
  final List<UDbIndexResponse> indexes;
  final List<UDbForeignKeyResponse> foreignKeys;
  final List<String> primaryKeys;
}

class UDbQueryResultResponse {
  UDbQueryResultResponse({
    required this.columns,
    required this.columnTypes,
    required this.rows,
    required this.rowCount,
    required this.executionMs,
    required this.truncated,
    this.affectedRows,
    this.primaryKeyColumn,
  });

  factory UDbQueryResultResponse.fromMap(Map<String, dynamic> json) => UDbQueryResultResponse(
    columns: List<String>.from((json["columns"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x.toString())),
    columnTypes: List<String?>.from((json["columnTypes"] as List<dynamic>? ?? <dynamic>[]).map((dynamic x) => x?.toString())),
    rows: List<Map<String, String?>>.from(
      (json["rows"] as List<dynamic>? ?? <dynamic>[]).map(
        (dynamic x) => (x as Map<String, dynamic>).map((String k, dynamic v) => MapEntry<String, String?>(k, v?.toString())),
      ),
    ),
    rowCount: (json["rowCount"] ?? 0) as int,
    executionMs: (json["executionMs"] ?? 0) as int,
    truncated: json["truncated"] ?? false,
    affectedRows: json["affectedRows"],
    primaryKeyColumn: json["primaryKeyColumn"],
  );

  final List<String> columns;
  final List<String?> columnTypes;
  final List<Map<String, String?>> rows;
  final int rowCount;
  final int executionMs;
  final bool truncated;
  final int? affectedRows;
  final String? primaryKeyColumn;
}
