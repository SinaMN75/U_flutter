part of "../data.dart";

class UDbAdminTablesParams {
  final String schema;

  UDbAdminTablesParams({
    this.schema = "public",
  });

  factory UDbAdminTablesParams.fromJson(String str) => UDbAdminTablesParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminTablesParams.fromMap(Map<String, dynamic> json) => UDbAdminTablesParams(
    schema: json["schema"] ?? "public",
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "schema": schema,
  };
}

class UDbAdminTableSchemaParams {
  final String table;
  final String schema;

  UDbAdminTableSchemaParams({
    required this.table,
    this.schema = "public",
  });

  factory UDbAdminTableSchemaParams.fromJson(String str) => UDbAdminTableSchemaParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminTableSchemaParams.fromMap(Map<String, dynamic> json) => UDbAdminTableSchemaParams(
    table: json["table"],
    schema: json["schema"] ?? "public",
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
  };
}

class UDbAdminRowsParams {
  final String table;
  final String schema;
  final int pageSize;
  final int pageNumber;
  final String? orderByColumn;
  final bool descending;
  final String? where;
  final bool withCount;

  UDbAdminRowsParams({
    required this.table,
    this.schema = "public",
    this.pageSize = 100,
    this.pageNumber = 1,
    this.orderByColumn,
    this.descending = false,
    this.where,
    this.withCount = true,
  });

  factory UDbAdminRowsParams.fromJson(String str) => UDbAdminRowsParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminRowsParams.fromMap(Map<String, dynamic> json) => UDbAdminRowsParams(
    table: json["table"],
    schema: json["schema"] ?? "public",
    pageSize: json["pageSize"] ?? 100,
    pageNumber: json["pageNumber"] ?? 1,
    orderByColumn: json["orderByColumn"],
    descending: json["descending"] ?? false,
    where: json["where"],
    withCount: json["withCount"] ?? true,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "orderByColumn": orderByColumn,
    "descending": descending,
    "where": where,
    "withCount": withCount,
  };
}

class UDbAdminQueryParams {
  final String sql;
  final int maxRows;

  UDbAdminQueryParams({
    required this.sql,
    this.maxRows = 500,
  });

  factory UDbAdminQueryParams.fromJson(String str) => UDbAdminQueryParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminQueryParams.fromMap(Map<String, dynamic> json) => UDbAdminQueryParams(
    sql: json["sql"],
    maxRows: json["maxRows"] ?? 500,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "sql": sql,
    "maxRows": maxRows,
  };
}

class UDbAdminUpdateRowParams {
  final String table;
  final String schema;
  final String primaryKeyColumn;
  final String primaryKeyValue;
  final Map<String, dynamic> values;

  UDbAdminUpdateRowParams({
    required this.table,
    required this.primaryKeyColumn,
    required this.primaryKeyValue,
    required this.values,
    this.schema = "public",
  });

  factory UDbAdminUpdateRowParams.fromJson(String str) => UDbAdminUpdateRowParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminUpdateRowParams.fromMap(Map<String, dynamic> json) => UDbAdminUpdateRowParams(
    table: json["table"],
    schema: json["schema"] ?? "public",
    primaryKeyColumn: json["primaryKeyColumn"],
    primaryKeyValue: json["primaryKeyValue"],
    values: Map<String, dynamic>.from(json["values"] ?? <String, dynamic>{}),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "primaryKeyColumn": primaryKeyColumn,
    "primaryKeyValue": primaryKeyValue,
    "values": values,
  };
}

class UDbAdminInsertRowParams {
  final String table;
  final String schema;
  final Map<String, dynamic> values;

  UDbAdminInsertRowParams({
    required this.table,
    required this.values,
    this.schema = "public",
  });

  factory UDbAdminInsertRowParams.fromJson(String str) => UDbAdminInsertRowParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminInsertRowParams.fromMap(Map<String, dynamic> json) => UDbAdminInsertRowParams(
    table: json["table"],
    schema: json["schema"] ?? "public",
    values: Map<String, dynamic>.from(json["values"] ?? <String, dynamic>{}),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "values": values,
  };
}

class UDbAdminDeleteRowParams {
  final String table;
  final String schema;
  final String primaryKeyColumn;
  final String primaryKeyValue;

  UDbAdminDeleteRowParams({
    required this.table,
    required this.primaryKeyColumn,
    required this.primaryKeyValue,
    this.schema = "public",
  });

  factory UDbAdminDeleteRowParams.fromJson(String str) => UDbAdminDeleteRowParams.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UDbAdminDeleteRowParams.fromMap(Map<String, dynamic> json) => UDbAdminDeleteRowParams(
    table: json["table"],
    schema: json["schema"] ?? "public",
    primaryKeyColumn: json["primaryKeyColumn"],
    primaryKeyValue: json["primaryKeyValue"],
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "primaryKeyColumn": primaryKeyColumn,
    "primaryKeyValue": primaryKeyValue,
  };
}
