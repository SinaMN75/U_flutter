part of "../data.dart";

class UDbAdminTablesParams {
  UDbAdminTablesParams({this.schema = "public"});

  final String schema;

  Map<String, dynamic> toMap() => <String, dynamic>{"schema": schema};
}

class UDbAdminSchemaParams {
  UDbAdminSchemaParams({required this.table, this.schema = "public"});

  final String table;
  final String schema;

  Map<String, dynamic> toMap() => <String, dynamic>{"table": table, "schema": schema};
}

class UDbAdminRowsParams {
  UDbAdminRowsParams({
    required this.table,
    this.schema = "public",
    this.pageSize = 100,
    this.pageNumber = 1,
    this.orderByColumn,
    this.descending = false,
  });

  final String table;
  final String schema;
  final int pageSize;
  final int pageNumber;
  final String? orderByColumn;
  final bool descending;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "pageSize": pageSize,
    "pageNumber": pageNumber,
    "orderByColumn": orderByColumn,
    "descending": descending,
  };
}

class UDbAdminQueryParams {
  UDbAdminQueryParams({required this.sql, this.maxRows = 500});

  final String sql;
  final int maxRows;

  Map<String, dynamic> toMap() => <String, dynamic>{"sql": sql, "maxRows": maxRows};
}

class UDbAdminUpdateRowParams {
  UDbAdminUpdateRowParams({
    required this.table,
    required this.primaryKeyColumn,
    required this.primaryKeyValue,
    required this.values,
    this.schema = "public",
  });

  final String table;
  final String schema;
  final String primaryKeyColumn;
  final String primaryKeyValue;
  final Map<String, dynamic> values;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "primaryKeyColumn": primaryKeyColumn,
    "primaryKeyValue": primaryKeyValue,
    "values": values,
  };
}

class UDbAdminInsertRowParams {
  UDbAdminInsertRowParams({required this.table, required this.values, this.schema = "public"});

  final String table;
  final String schema;
  final Map<String, dynamic> values;

  Map<String, dynamic> toMap() => <String, dynamic>{"table": table, "schema": schema, "values": values};
}

class UDbAdminDeleteRowParams {
  UDbAdminDeleteRowParams({
    required this.table,
    required this.primaryKeyColumn,
    required this.primaryKeyValue,
    this.schema = "public",
  });

  final String table;
  final String schema;
  final String primaryKeyColumn;
  final String primaryKeyValue;

  Map<String, dynamic> toMap() => <String, dynamic>{
    "table": table,
    "schema": schema,
    "primaryKeyColumn": primaryKeyColumn,
    "primaryKeyValue": primaryKeyValue,
  };
}
