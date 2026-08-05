import "package:u/utilities.dart";

// SystemAdmin-only PgAdmin-style console: browse every table, page/sort/edit/insert/delete rows,
// inspect structure (columns, indexes, foreign keys) and run arbitrary SQL with prebuilt helpers.
// All power lives on the backend DbAdmin endpoints; this widget is pure UI over UServices.dbAdmin.
class UAdminDbAdminPage extends StatefulWidget {
  const UAdminDbAdminPage({super.key});

  @override
  State<UAdminDbAdminPage> createState() => _UAdminDbAdminPageState();
}

class _UAdminDbAdminPageState extends State<UAdminDbAdminPage> {
  static const int _pageSize = 50;

  List<UDbTableResponse> _tables = <UDbTableResponse>[];
  bool _loadingTables = true;
  String _tableSearch = "";

  UDbTableResponse? _selected;
  int _tab = 0; // 0 = data, 1 = structure, 2 = query

  UDbQueryResultResponse? _rows;
  bool _loadingRows = false;
  int _page = 1;
  int _pageCount = 1;
  int _totalCount = 0;
  String? _orderBy;
  bool _descending = false;

  UDbTableSchemaResponse? _schema;
  bool _loadingSchema = false;

  final TextEditingController _sqlController = TextEditingController();
  UDbQueryResultResponse? _queryResult;
  String? _queryError;
  bool _queryRunning = false;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    setState(() => _loadingTables = true);
    await UServices.dbAdmin.tables(
      p: UDbAdminTablesParams(),
      onOk: (final UResponse<List<UDbTableResponse>> r) => setState(() {
        _tables = r.result ?? <UDbTableResponse>[];
        _loadingTables = false;
      }),
      onError: (final UEmptyResponse e) {
        setState(() => _loadingTables = false);
        UToast.error(message: e.message);
      },
      onException: (final String e) {
        setState(() => _loadingTables = false);
        UToast.error(message: e);
      },
    );
  }

  void _selectTable(final UDbTableResponse t) {
    setState(() {
      _selected = t;
      _tab = 0;
      _page = 1;
      _orderBy = null;
      _descending = false;
      _rows = null;
      _schema = null;
    });
    _loadRows();
    _loadSchema();
  }

  Future<void> _loadRows() async {
    if (_selected == null) return;
    setState(() => _loadingRows = true);
    await UServices.dbAdmin.rows(
      p: UDbAdminRowsParams(
        table: _selected!.name,
        schema: _selected!.schema,
        pageSize: _pageSize,
        pageNumber: _page,
        orderByColumn: _orderBy,
        descending: _descending,
      ),
      onOk: (final UResponse<UDbQueryResultResponse> r) => setState(() {
        _rows = r.result;
        _totalCount = r.totalCount;
        _pageCount = r.pageCount < 1 ? 1 : r.pageCount;
        _loadingRows = false;
      }),
      onError: (final UEmptyResponse e) {
        setState(() => _loadingRows = false);
        UToast.error(message: e.message);
      },
      onException: (final String e) {
        setState(() => _loadingRows = false);
        UToast.error(message: e);
      },
    );
  }

  Future<void> _loadSchema() async {
    if (_selected == null) return;
    setState(() => _loadingSchema = true);
    await UServices.dbAdmin.schema(
      p: UDbAdminSchemaParams(table: _selected!.name, schema: _selected!.schema),
      onOk: (final UResponse<UDbTableSchemaResponse> r) => setState(() {
        _schema = r.result;
        _loadingSchema = false;
      }),
      onError: (final UEmptyResponse e) {
        setState(() => _loadingSchema = false);
        UToast.error(message: e.message);
      },
      onException: (final String e) {
        setState(() => _loadingSchema = false);
        UToast.error(message: e);
      },
    );
  }

  void _sortBy(final String column) {
    setState(() {
      if (_orderBy == column) {
        _descending = !_descending;
      } else {
        _orderBy = column;
        _descending = false;
      }
      _page = 1;
    });
    _loadRows();
  }

  Future<void> _runQuery() async {
    final String sql = _sqlController.text.trim();
    if (sql.isEmpty) return;
    setState(() {
      _queryRunning = true;
      _queryError = null;
    });
    await UServices.dbAdmin.query(
      p: UDbAdminQueryParams(sql: sql),
      onOk: (final UResponse<UDbQueryResultResponse> r) => setState(() {
        _queryResult = r.result;
        _queryError = null;
        _queryRunning = false;
      }),
      onError: (final UEmptyResponse e) => setState(() {
        _queryResult = null;
        _queryError = e.message;
        _queryRunning = false;
      }),
      onException: (final String e) => setState(() {
        _queryResult = null;
        _queryError = e;
        _queryRunning = false;
      }),
    );
  }

  Future<void> _deleteRow(final Map<String, String?> row) async {
    final String? pk = _rows?.primaryKeyColumn;
    if (_selected == null || pk == null || row[pk] == null) return;
    if (!await UNavigator.confirmAsync(title: "Delete", message: "Delete this row? This cannot be undone.", destructive: true, icon: Icons.delete_outline_rounded)) return;

    ULoading.show();
    await UServices.dbAdmin.deleteRow(
      p: UDbAdminDeleteRowParams(table: _selected!.name, schema: _selected!.schema, primaryKeyColumn: pk, primaryKeyValue: row[pk]!),
      onOk: (final UEmptyResponse r) {
        ULoading.dismiss();
        UToast.success(message: r.message);
        _loadRows();
      },
      onError: (final UEmptyResponse e) {
        ULoading.dismiss();
        UToast.error(message: e.message);
      },
      onException: (final String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  Future<void> _openRowEditor({final Map<String, String?>? original}) async {
    if (_selected == null || _schema == null) return;
    final bool isInsert = original == null;
    final String? pk = _rows?.primaryKeyColumn ?? (_schema!.primaryKeys.isNotEmpty ? _schema!.primaryKeys.first : null);

    final Map<String, TextEditingController> controllers = <String, TextEditingController>{};
    final Map<String, bool> nulls = <String, bool>{};
    for (final UDbColumnResponse c in _schema!.columns) {
      final String? value = original?[c.name];
      controllers[c.name] = TextEditingController(text: value ?? "");
      nulls[c.name] = !isInsert && value == null;
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool? saved = await UNavigator.dialog<bool>(
      StatefulBuilder(
        builder: (final BuildContext ctx, final StateSetter setLocal) => AlertDialog(
          title: UTextTitleMedium(isInsert ? "Insert Row" : "Edit Row", fontWeight: FontWeight.bold),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: UColumn(
                spacing: 14,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _schema!.columns.map((final UDbColumnResponse c) {
                  final bool readOnly = !isInsert && c.name == pk;
                  return URow(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      UTextField(
                        controller: controllers[c.name],
                        labelText: "${c.name}  (${c.dataType})${c.isPrimaryKey ? "  •PK" : ""}",
                        readOnly: readOnly || nulls[c.name]!,
                      ).expanded(),
                      if (c.isNullable && !readOnly)
                        Tooltip(
                          message: "Null",
                          child: FilterChip(
                            label: UTextLabelSmall("Null", color: nulls[c.name]! ? cs.onPrimary : cs.onSurface),
                            selected: nulls[c.name]!,
                            onSelected: (final bool v) => setLocal(() => nulls[c.name] = v),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: <Widget>[
            UButton(title: "Cancel", type: UButtonType.text, onTap: () => UNavigator.back(false)),
            UButton(title: "Save", onTap: () => UNavigator.back(true)),
          ],
        ),
      ),
    );

    if (saved != true) {
      for (final TextEditingController c in controllers.values) {
        c.dispose();
      }
      return;
    }

    final Map<String, dynamic> values = <String, dynamic>{};
    for (final UDbColumnResponse c in _schema!.columns) {
      if (!isInsert && c.name == pk) continue;
      if (nulls[c.name]!) {
        if (isInsert || original[c.name] != null) values[c.name] = null;
        continue;
      }
      final String text = controllers[c.name]!.text;
      if (isInsert) {
        if (text.isNotEmpty) values[c.name] = text;
      } else if (original[c.name] != text) {
        values[c.name] = text;
      }
    }
    for (final TextEditingController c in controllers.values) {
      c.dispose();
    }

    if (values.isEmpty) return;

    ULoading.show();
    if (isInsert) {
      await UServices.dbAdmin.insertRow(
        p: UDbAdminInsertRowParams(table: _selected!.name, schema: _selected!.schema, values: values),
        onOk: (final UResponse<UDbQueryResultResponse> r) {
          ULoading.dismiss();
          UToast.success(message: r.message);
          _loadRows();
        },
        onError: (final UEmptyResponse e) {
          ULoading.dismiss();
          UToast.error(message: e.message);
        },
        onException: (final String e) {
          ULoading.dismiss();
          UToast.error(message: e);
        },
      );
    } else {
      if (pk == null || original[pk] == null) {
        ULoading.dismiss();
        return;
      }
      await UServices.dbAdmin.updateRow(
        p: UDbAdminUpdateRowParams(table: _selected!.name, schema: _selected!.schema, primaryKeyColumn: pk, primaryKeyValue: original[pk]!, values: values),
        onOk: (final UResponse<UDbQueryResultResponse> r) {
          ULoading.dismiss();
          UToast.success(message: r.message);
          _loadRows();
        },
        onError: (final UEmptyResponse e) {
          ULoading.dismiss();
          UToast.error(message: e.message);
        },
        onException: (final String e) {
          ULoading.dismiss();
          UToast.error(message: e);
        },
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // This console is English-only and always left-to-right, regardless of the app locale/direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: UScaffold(
        body: URow(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _sidebar(cs),
            VerticalDivider(width: 1, color: cs.outlineVariant),
            _main(cs).expanded(),
          ],
        ),
      ),
    );
  }

  // ===== Sidebar =====

  Widget _sidebar(final ColorScheme cs) {
    final List<UDbTableResponse> filtered = _tableSearch.isEmpty
        ? _tables
        : _tables.where((final UDbTableResponse t) => t.name.toLowerCase().contains(_tableSearch.toLowerCase())).toList();
    return SizedBox(
      width: 280,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          URow(
            children: <Widget>[
              Icon(Icons.storage_rounded, color: cs.primary),
              const UTextTitleMedium("Database Console", fontWeight: FontWeight.bold).expanded(),
              IconButton(tooltip: "Refresh", onPressed: _loadTables, icon: Icon(Icons.refresh_rounded, size: 20, color: cs.primary)),
            ],
          ).pOnly(left: 16, right: 8, top: 12, bottom: 4),
          UTextField(
            hintText: "Search tables",
            prefix: Icon(Icons.search_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
            isDense: true,
            onChanged: (final String v) => setState(() => _tableSearch = v),
          ).pSymmetric(horizontal: 12, vertical: 6),
          const Divider(height: 1),
          if (_loadingTables)
            const UProgressCircular().pAll(24)
          else if (filtered.isEmpty)
            UTextBodySmall("No data", color: cs.onSurface.withValues(alpha: 0.5)).pAll(24)
          else
            ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (final BuildContext ctx, final int i) {
                final UDbTableResponse t = filtered[i];
                final bool active = _selected?.name == t.name;
                return URow(
                  children: <Widget>[
                    Icon(Icons.table_chart_outlined, size: 16, color: active ? cs.onPrimary : cs.primary),
                    UColumn(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        UTextBodyMedium(t.name, color: active ? cs.onPrimary : cs.onSurface, fontWeight: active ? FontWeight.w600 : FontWeight.normal, maxLines: 1),
                        UTextLabelSmall("${t.estimatedRows} ${"Rows"} · ${t.columnCount} ${"Columns"}", color: (active ? cs.onPrimary : cs.onSurface).withValues(alpha: 0.6)),
                      ],
                    ).expanded(),
                  ],
                ).pSymmetric(horizontal: 14, vertical: 10).container(backgroundColor: active ? cs.primary : null, radius: 10).pSymmetric(horizontal: 6, vertical: 2).onTap(() => _selectTable(t));
              },
            ).expanded(),
        ],
      ),
    );
  }

  // ===== Main =====

  Widget _main(final ColorScheme cs) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _mainHeader(cs),
      const Divider(height: 1),
      URow(children: <Widget>[
        _tabChip(cs, 0, "Data", Icons.grid_on_rounded),
        _tabChip(cs, 1, "Structure", Icons.schema_rounded),
        _tabChip(cs, 2, "Query", Icons.terminal_rounded),
      ]).pSymmetric(horizontal: 16, vertical: 10),
      const Divider(height: 1),
      IndexedStack(
        index: _tab,
        children: <Widget>[_dataTab(cs), _structureTab(cs), _queryTab(cs)],
      ).expanded(),
    ],
  );

  Widget _mainHeader(final ColorScheme cs) => URow(
    spacing: 10,
    children: <Widget>[
      Icon(Icons.data_object_rounded, color: cs.primary),
      UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UTextTitleMedium(_selected?.name ?? "Database Console", fontWeight: FontWeight.bold, maxLines: 1),
          if (_selected != null) UTextLabelSmall("${_selected!.schema} · $_totalCount ${"Rows"}${_selected!.size != null ? " · ${_selected!.size}" : ""}", color: cs.onSurface.withValues(alpha: 0.6)),
        ],
      ).expanded(),
      if (_selected != null && _tab == 0) ...<Widget>[
        UButton(title: "Insert Row", type: UButtonType.outlined, icon: const Icon(Icons.add_rounded, size: 18), onTap: _openRowEditor),
        IconButton(tooltip: "Refresh", onPressed: _loadRows, icon: Icon(Icons.refresh_rounded, color: cs.primary)),
      ],
    ],
  ).pSymmetric(horizontal: 16, vertical: 12);

  Widget _tabChip(final ColorScheme cs, final int index, final String label, final IconData icon) {
    final bool active = _tab == index;
    return URow(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: <Widget>[
        Icon(icon, size: 16, color: active ? cs.onPrimary : cs.primary),
        UTextLabelLarge(label, color: active ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w600),
      ],
    ).pSymmetric(horizontal: 14, vertical: 8).container(backgroundColor: active ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.5), radius: 10).onTap(() => setState(() => _tab = index));
  }

  // ===== Data tab =====

  Widget _dataTab(final ColorScheme cs) {
    if (_selected == null) return _placeholder(cs, Icons.touch_app_outlined, "Select a table to view its data");
    if (_loadingRows && _rows == null) return const UProgressCircular().pAll(40);
    final UDbQueryResultResponse? data = _rows;
    if (data == null || data.columns.isEmpty) return _placeholder(cs, Icons.inbox_outlined, "No data");

    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _resultGrid(cs, data, editable: true).expanded(),
        const Divider(height: 1),
        _pagination(cs),
      ],
    );
  }

  Widget _pagination(final ColorScheme cs) => URow(
    spacing: 12,
    mainAxisAlignment: MainAxisAlignment.end,
    children: <Widget>[
      if (_rows?.truncated ?? false) UTextLabelSmall("Results truncated", color: cs.error),
      UTextBodySmall("$_page / $_pageCount", color: cs.onSurface.withValues(alpha: 0.7)),
      IconButton(
        onPressed: _page > 1
            ? () {
                setState(() => _page -= 1);
                _loadRows();
              }
            : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      IconButton(
        onPressed: _page < _pageCount
            ? () {
                setState(() => _page += 1);
                _loadRows();
              }
            : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  ).pSymmetric(horizontal: 16, vertical: 6);

  // ===== Structure tab =====

  Widget _structureTab(final ColorScheme cs) {
    if (_selected == null) return _placeholder(cs, Icons.touch_app_outlined, "Select a table to view its data");
    if (_loadingSchema && _schema == null) return const UProgressCircular().pAll(40);
    final UDbTableSchemaResponse? s = _schema;
    if (s == null) return _placeholder(cs, Icons.inbox_outlined, "No data");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: UColumn(
        spacing: 18,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _structureCard(cs, "Columns", Icons.view_column_outlined, s.columns.map((final UDbColumnResponse c) => URow(
              spacing: 10,
              children: <Widget>[
                if (c.isPrimaryKey) Icon(Icons.key_rounded, size: 15, color: cs.tertiary) else const SizedBox(width: 15),
                UTextBodyMedium(c.name, fontWeight: FontWeight.w600).expanded(flex: 3),
                UTextBodySmall(c.dataType, color: cs.primary).expanded(flex: 2),
                UTextLabelSmall(c.isNullable ? "Nullable" : "NOT NULL", color: cs.onSurface.withValues(alpha: 0.6)).expanded(flex: 2),
                UTextLabelSmall(c.defaultValue ?? "", color: cs.onSurface.withValues(alpha: 0.5), maxLines: 1).expanded(flex: 3),
              ],
            ).pSymmetric(vertical: 6)).toList()),
          if (s.indexes.isNotEmpty)
            _structureCard(cs, "Indexes", Icons.bolt_rounded, s.indexes.map((final UDbIndexResponse idx) => UColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  URow(children: <Widget>[
                    if (idx.isPrimary) Icon(Icons.key_rounded, size: 14, color: cs.tertiary) else if (idx.isUnique) Icon(Icons.star_rounded, size: 14, color: cs.primary),
                    UTextBodyMedium(idx.name, fontWeight: FontWeight.w600),
                  ]),
                  UTextLabelSmall(idx.definition, color: cs.onSurface.withValues(alpha: 0.55)),
                ],
              ).pSymmetric(vertical: 6)).toList()),
          if (s.foreignKeys.isNotEmpty)
            _structureCard(cs, "Foreign Keys", Icons.link_rounded, s.foreignKeys.map((final UDbForeignKeyResponse fk) => URow(
                children: <Widget>[
                  UTextBodyMedium(fk.column, fontWeight: FontWeight.w600),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: cs.onSurface.withValues(alpha: 0.5)),
                  UTextBodySmall("${fk.referencesTable}.${fk.referencesColumn}", color: cs.primary),
                ],
              ).pSymmetric(vertical: 6)).toList()),
        ],
      ),
    );
  }

  Widget _structureCard(final ColorScheme cs, final String title, final IconData icon, final List<Widget> children) => UCard(
    child: UColumn(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(children: <Widget>[Icon(icon, color: cs.primary, size: 20), UTextTitleSmall(title, fontWeight: FontWeight.bold)]),
        const Divider(height: 12),
        ...children,
      ],
    ).pAll(18),
  );

  // ===== Query tab =====

  Widget _queryTab(final ColorScheme cs) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: UColumn(
      spacing: 14,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _prebuilt.map((final _Prebuilt q) => URow(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: <Widget>[Icon(q.icon, size: 14, color: cs.primary), UTextLabelSmall(q.title, fontWeight: FontWeight.w600)],
            ).pSymmetric(horizontal: 12, vertical: 8).container(backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5), radius: 20, borderColor: cs.outlineVariant).onTap(() {
              _sqlController.text = q.sql(_selected?.name ?? "table_name", _selected?.schema ?? "public");
              setState(() {});
            })).toList(),
        ),
        UCard(
          child: UColumn(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              URow(children: <Widget>[
                Icon(Icons.terminal_rounded, color: cs.primary, size: 20),
                const UTextTitleSmall("SQL Editor", fontWeight: FontWeight.bold).expanded(),
                UButton(title: "Run", icon: const Icon(Icons.play_arrow_rounded, size: 18), isLoading: _queryRunning, onTap: _runQuery),
              ]),
              TextField(
                controller: _sqlController,
                maxLines: 8,
                minLines: 6,
                style: const TextStyle(fontFamily: "monospace", fontSize: 13),
                decoration: InputDecoration(
                  hintText: "SELECT * FROM ...",
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
                ),
              ),
            ],
          ).pAll(16),
        ),
        if (_queryError != null)
          URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
              UTextBodySmall(_queryError!, color: cs.error).expanded(),
            ],
          ).pAll(14).container(backgroundColor: cs.errorContainer.withValues(alpha: 0.4), radius: 10),
        if (_queryResult != null) _queryResultView(cs, _queryResult!),
      ],
    ),
  );

  Widget _queryResultView(final ColorScheme cs, final UDbQueryResultResponse r) {
    final String meta = r.columns.isEmpty
        ? "${r.affectedRows ?? 0} ${"affected"} · ${r.executionMs} ms"
        : "${r.rowCount} ${"Rows"} · ${r.executionMs} ms${r.truncated ? " · ${"Results truncated"}" : ""}";
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        UTextLabelSmall(meta, color: cs.onSurface.withValues(alpha: 0.6)),
        if (r.columns.isNotEmpty)
          ConstrainedBox(constraints: const BoxConstraints(maxHeight: 460), child: _resultGrid(cs, r, editable: false)),
      ],
    );
  }

  // ===== Shared result grid =====

  Widget _resultGrid(final ColorScheme cs, final UDbQueryResultResponse data, {required final bool editable}) {
    final bool canMutate = editable && (data.primaryKeyColumn != null);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll<Color>(cs.surfaceContainerHighest.withValues(alpha: 0.4)),
          columnSpacing: 26,
          columns: <DataColumn>[
            if (canMutate) const DataColumn(label: SizedBox(width: 8)),
            ...data.columns.mapIndexed((final int i, final String col) {
              final bool sorted = editable && _orderBy == col;
              return DataColumn(
                label: URow(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: <Widget>[
                    UTextLabelMedium(col, fontWeight: FontWeight.bold),
                    if (i < data.columnTypes.length && data.columnTypes[i] != null) UTextLabelSmall(data.columnTypes[i]!, color: cs.onSurface.withValues(alpha: 0.45)),
                    if (sorted) Icon(_descending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 13, color: cs.primary),
                  ],
                ),
                onSort: editable ? (final int columnIndex, final bool ascending) => _sortBy(col) : null,
              );
            }),
          ],
          rows: data.rows.map((final Map<String, String?> row) => DataRow(
              cells: <DataCell>[
                if (canMutate)
                  DataCell(URow(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(tooltip: "Edit", iconSize: 17, visualDensity: VisualDensity.compact, onPressed: () => _openRowEditor(original: row), icon: Icon(Icons.edit_outlined, color: cs.primary)),
                      IconButton(tooltip: "Delete", iconSize: 17, visualDensity: VisualDensity.compact, onPressed: () => _deleteRow(row), icon: Icon(Icons.delete_outline_rounded, color: cs.error)),
                    ],
                  )),
                ...data.columns.map((final String col) {
                  final String? value = row[col];
                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: value == null
                          ? UTextBodySmall("NULL", color: cs.onSurface.withValues(alpha: 0.35))
                          : UTextBodySmall(value, maxLines: 1),
                    ),
                    onTap: value == null ? null : () => UClipboard.set(value),
                  );
                }),
              ],
            )).toList(),
        ),
      ),
    );
  }

  Widget _placeholder(final ColorScheme cs, final IconData icon, final String message) => UColumn(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 12,
    children: <Widget>[
      Icon(icon, size: 46, color: cs.onSurface.withValues(alpha: 0.25)),
      UTextBodyMedium(message, color: cs.onSurface.withValues(alpha: 0.5)),
    ],
  ).pAll(40);

  // Prebuilt query catalog. `{s}`/`{t}` are replaced with the selected schema/table (or placeholders).
  List<_Prebuilt> get _prebuilt => <_Prebuilt>[
    _Prebuilt("Rows", Icons.numbers_rounded, (final String t, final String s) => "SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC;"),
    _Prebuilt("Sizes", Icons.sd_storage_outlined, (final String t, final String s) => "SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS size FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;"),
    _Prebuilt("Recent", Icons.history_rounded, (final String t, final String s) => 'SELECT * FROM "$s"."$t" ORDER BY "CreatedAt" DESC LIMIT 50;'),
    _Prebuilt("DB size", Icons.data_usage_rounded, (final String t, final String s) => "SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;"),
    _Prebuilt("Connections", Icons.cable_rounded, (final String t, final String s) => "SELECT state, count(*) FROM pg_stat_activity GROUP BY state ORDER BY count DESC;"),
    _Prebuilt("Long queries", Icons.timelapse_rounded, (final String t, final String s) => "SELECT pid, now() - query_start AS duration, state, query FROM pg_stat_activity WHERE state <> 'idle' AND query_start IS NOT NULL ORDER BY duration DESC LIMIT 20;"),
    _Prebuilt("Cache hit", Icons.speed_rounded, (final String t, final String s) => "SELECT round(sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0), 4) AS cache_hit_ratio FROM pg_statio_user_tables;"),
    _Prebuilt("Index usage", Icons.bolt_rounded, (final String t, final String s) => "SELECT relname AS table, indexrelname AS index, idx_scan AS scans FROM pg_stat_user_indexes ORDER BY idx_scan DESC LIMIT 30;"),
    _Prebuilt("Dead rows", Icons.cleaning_services_rounded, (final String t, final String s) => "SELECT relname AS table, n_dead_tup AS dead_rows FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 20;"),
  ];
}

class _Prebuilt {
  _Prebuilt(this.title, this.icon, this.sql);

  final String title;
  final IconData icon;
  final String Function(String table, String schema) sql;
}
