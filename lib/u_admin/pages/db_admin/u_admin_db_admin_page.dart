import "package:u/utilities.dart";

class UAdminDbAdminPage extends StatefulWidget {
  const UAdminDbAdminPage({super.key});

  @override
  State<UAdminDbAdminPage> createState() => _UAdminDbAdminPageState();
}

class _UAdminDbAdminPageState extends State<UAdminDbAdminPage> {
  static const List<int> _pageSizes = <int>[50, 100, 200, 500];

  List<UDbTableResponse> _tables = <UDbTableResponse>[];
  bool _loadingTables = true;
  String _tableSearch = "";

  UDbTableResponse? _selected;
  int _tab = 0; // 0 = data, 1 = structure, 2 = query

  UDbQueryResultResponse? _rows;
  bool _loadingRows = false;
  int _page = 1;
  int _pageSize = 100;
  int _pageCount = 1;
  int _totalCount = 0;
  String? _orderBy;
  bool _descending = false;
  final TextEditingController _whereController = TextEditingController();

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
    _whereController.dispose();
    _sqlController.dispose();
    super.dispose();
  }

  // ===== Data loading =====

  Future<void> _loadTables() async {
    setState(() => _loadingTables = true);
    await UServices.dbAdmin.tables(
      p: UDbAdminTablesParams(),
      onOk: (UResponse<List<UDbTableResponse>> r) => setState(() {
        _tables = r.result ?? <UDbTableResponse>[];
        _loadingTables = false;
      }),
      onError: (UEmptyResponse e) {
        setState(() => _loadingTables = false);
        UToast.error(message: e.message);
      },
      onException: (String e) {
        setState(() => _loadingTables = false);
        UToast.error(message: e);
      },
    );
  }

  void _selectTable(UDbTableResponse t) {
    setState(() {
      _selected = t;
      _tab = 0;
      _page = 1;
      _orderBy = null;
      _descending = false;
      _rows = null;
      _schema = null;
      _whereController.clear();
    });
    _loadRows(withCount: true);
    _loadSchema();
  }

  // withCount is only true on the first load / new filter / new page size, so paging & sorting
  // never re-scan the whole table with count(*).
  Future<void> _loadRows({bool withCount = false}) async {
    if (_selected == null) return;
    setState(() => _loadingRows = true);
    final String where = _whereController.text.trim();
    await UServices.dbAdmin.rows(
      p: UDbAdminRowsParams(
        table: _selected!.name,
        schema: _selected!.schema,
        pageSize: _pageSize,
        pageNumber: _page,
        orderByColumn: _orderBy,
        descending: _descending,
        where: where.isEmpty ? null : where,
        withCount: withCount,
      ),
      onOk: (UResponse<UDbQueryResultResponse> r) => setState(() {
        _rows = r.result;
        if (withCount) {
          _totalCount = r.totalCount;
          _pageCount = _totalCount <= 0 ? 1 : (_totalCount + _pageSize - 1) ~/ _pageSize;
        }
        _loadingRows = false;
      }),
      onError: (UEmptyResponse e) {
        setState(() => _loadingRows = false);
        UToast.error(message: e.message);
      },
      onException: (String e) {
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
      onOk: (UResponse<UDbTableSchemaResponse> r) => setState(() {
        _schema = r.result;
        _loadingSchema = false;
      }),
      onError: (UEmptyResponse e) {
        setState(() => _loadingSchema = false);
        UToast.error(message: e.message);
      },
      onException: (String e) {
        setState(() => _loadingSchema = false);
        UToast.error(message: e);
      },
    );
  }

  void _sortBy(String column) {
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

  void _applyFilter() {
    setState(() => _page = 1);
    _loadRows(withCount: true);
  }

  void _changePageSize(int size) {
    setState(() {
      _pageSize = size;
      _page = 1;
    });
    _loadRows(withCount: true);
  }

  void _gotoPage(int page) {
    if (page < 1 || page > _pageCount || page == _page) return;
    setState(() => _page = page);
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
      onOk: (UResponse<UDbQueryResultResponse> r) => setState(() {
        _queryResult = r.result;
        _queryError = null;
        _queryRunning = false;
      }),
      onError: (UEmptyResponse e) => setState(() {
        _queryResult = null;
        _queryError = e.message;
        _queryRunning = false;
      }),
      onException: (String e) => setState(() {
        _queryResult = null;
        _queryError = e;
        _queryRunning = false;
      }),
    );
  }

  Future<void> _runMigrations() async {
    if (!await UNavigator.confirmAsync(title: "Run migrations", message: "Apply all pending database migrations now?", confirmText: "Migrate", icon: Icons.system_update_alt_rounded)) return;
    ULoading.show();
    await UServices.dbAdmin.migrate(
      onOk: (List<String> applied) {
        ULoading.dismiss();
        UToast.success(message: applied.isEmpty ? "Database is already up to date." : "Applied ${applied.length} migration(s): ${applied.join(", ")}");
        _loadTables();
      },
      onError: (String e) {
        ULoading.dismiss();
        UToast.error(message: e.isEmpty ? "Migration failed." : e);
      },
    );
  }

  Future<void> _deleteRow(Map<String, String?> row) async {
    final String? pk = _rows?.primaryKeyColumn;
    if (_selected == null || pk == null || row[pk] == null) return;
    if (!await UNavigator.confirmAsync(title: "Delete row", message: "Delete this row? This cannot be undone.", destructive: true, icon: Icons.delete_outline_rounded)) return;

    ULoading.show();
    await UServices.dbAdmin.deleteRow(
      p: UDbAdminDeleteRowParams(table: _selected!.name, schema: _selected!.schema, primaryKeyColumn: pk, primaryKeyValue: row[pk]!),
      onOk: (UEmptyResponse r) {
        ULoading.dismiss();
        UToast.success(message: r.message);
        _loadRows(withCount: true);
      },
      onError: (UEmptyResponse e) {
        ULoading.dismiss();
        UToast.error(message: e.message);
      },
      onException: (String e) {
        ULoading.dismiss();
        UToast.error(message: e);
      },
    );
  }

  void _viewRow(Map<String, String?> row) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    UNavigator.dialog<void>(
      AlertDialog(
        title: URow(
          spacing: 8,
          children: <Widget>[
            Icon(Icons.article_outlined, color: cs.primary, size: 20),
            const UTextTitleSmall("Row details", fontWeight: FontWeight.bold),
          ],
        ),
        content: SizedBox(
          width: context.dialogWidth(max: 560),
          child: SingleChildScrollView(
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.generate(row.length, (int i) {
                final MapEntry<String, String?> e = row.entries.elementAt(i);
                return URow(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: 160,
                      child: UTextLabelSmall(e.key, fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                    SelectableText(
                      e.value ?? "NULL",
                      style: TextStyle(fontFamily: "monospace", fontSize: 12.5, color: e.value == null ? cs.onSurface.withValues(alpha: 0.4) : cs.onSurface),
                    ).expanded(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 15,
                      tooltip: "Copy",
                      onPressed: e.value == null ? null : () => UClipboard.set(e.value!),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ).pSymmetric(vertical: 7).container(backgroundColor: i.isOdd ? cs.surfaceContainerHighest.withValues(alpha: 0.3) : null, radius: 6);
              }),
            ),
          ),
        ),
        actions: <Widget>[
          UButton(title: "Copy JSON", type: UButtonType.text, icon: const Icon(Icons.data_object_rounded, size: 16), onTap: () => UClipboard.set(_rowJson(row))),
          const UButton(title: "Close", onTap: UNavigator.back),
        ],
      ),
    );
  }

  Future<void> _openRowEditor({Map<String, String?>? original}) async {
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
        builder: (BuildContext ctx, StateSetter setLocal) => AlertDialog(
          title: URow(
            spacing: 8,
            children: <Widget>[
              Icon(isInsert ? Icons.add_circle_outline_rounded : Icons.edit_outlined, color: cs.primary, size: 20),
              UTextTitleSmall(isInsert ? "Insert row" : "Edit row", fontWeight: FontWeight.bold),
            ],
          ),
          content: SizedBox(
            width: context.dialogWidth(max: 540),
            child: SingleChildScrollView(
              child: UColumn(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _schema!.columns.map((UDbColumnResponse c) {
                  final bool readOnly = !isInsert && c.name == pk;
                  return URow(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      UTextField(
                        controller: controllers[c.name],
                        labelText: "${c.name}  ·  ${c.dataType}${c.isPrimaryKey ? "  · PK" : ""}${c.isNullable ? "" : "  · NOT NULL"}",
                        readOnly: readOnly || nulls[c.name]!,
                      ).expanded(),
                      if (c.isNullable && !readOnly)
                        FilterChip(
                          label: const Text("NULL"),
                          visualDensity: VisualDensity.compact,
                          selected: nulls[c.name]!,
                          onSelected: (bool v) => setLocal(() => nulls[c.name] = v),
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
        onOk: (UResponse<UDbQueryResultResponse> r) {
          ULoading.dismiss();
          UToast.success(message: r.message);
          _loadRows(withCount: true);
        },
        onError: (UEmptyResponse e) {
          ULoading.dismiss();
          UToast.error(message: e.message);
        },
        onException: (String e) {
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
        onOk: (UResponse<UDbQueryResultResponse> r) {
          ULoading.dismiss();
          UToast.success(message: r.message);
          _loadRows();
        },
        onError: (UEmptyResponse e) {
          ULoading.dismiss();
          UToast.error(message: e.message);
        },
        onException: (String e) {
          ULoading.dismiss();
          UToast.error(message: e);
        },
      );
    }
  }

  String _rowJson(Map<String, String?> row) {
    final StringBuffer b = StringBuffer("{");
    int i = 0;
    row.forEach((String k, String? v) {
      if (i++ > 0) b.write(", ");
      b.write('"$k": ');
      b.write(v == null ? "null" : '"${v.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"")}"');
    });
    b.write("}");
    return b.toString();
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool mobile = context.isMobileWidth;
    // This console is English-only and always left-to-right, regardless of the app locale/direction.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: UScaffold(
        drawer: mobile ? Drawer(width: 280, child: SafeArea(child: _sidebar(cs))) : null,
        body: mobile
            ? _main(cs, showMenu: true)
            : URow(
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

  Widget _sidebar(ColorScheme cs) {
    final List<UDbTableResponse> filtered = _tableSearch.isEmpty ? _tables : _tables.where((UDbTableResponse t) => t.name.toLowerCase().contains(_tableSearch.toLowerCase())).toList();
    return SizedBox(
      width: 256,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          URow(
            spacing: 6,
            children: <Widget>[
              Icon(Icons.storage_rounded, color: cs.primary, size: 20),
              const UTextLabelLarge("DATABASE", fontWeight: FontWeight.w800).expanded(),
              _miniIcon(cs, Icons.system_update_alt_rounded, "Run migrations", _runMigrations),
              _miniIcon(cs, Icons.refresh_rounded, "Refresh tables", _loadTables),
            ],
          ).pOnly(left: 14, right: 6, top: 12, bottom: 8),
          UTextField(
            hintText: "Search tables",
            prefix: Icon(Icons.search_rounded, size: 17, color: cs.onSurface.withValues(alpha: 0.5)),
            hasClearButton: true,
            onChanged: (String v) => setState(() => _tableSearch = v),
          ).pSymmetric(horizontal: 10),
          UTextLabelSmall("${filtered.length} tables", color: cs.onSurface.withValues(alpha: 0.5)).pOnly(left: 14, top: 8, bottom: 4),
          const Divider(height: 1),
          if (_loadingTables)
            const Center(child: UProgressCircular(size: 26)).pAll(24)
          else if (filtered.isEmpty)
            UTextBodySmall("No tables", color: cs.onSurface.withValues(alpha: 0.5)).pAll(20)
          else
            ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (BuildContext ctx, int i) => _tableTile(cs, filtered[i]),
            ).expanded(),
        ],
      ),
    );
  }

  Widget _tableTile(ColorScheme cs, UDbTableResponse t) {
    final bool active = _selected?.name == t.name;
    return URow(
          children: <Widget>[
            UContainer(
              width: 3,
              height: 26,
              color: active ? cs.primary : Colors.transparent,
              radius: 3,
            ),
            Icon(Icons.table_rows_rounded, size: 15, color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.55)),
            UTextBodySmall(t.name, color: active ? cs.primary : cs.onSurface, fontWeight: active ? FontWeight.w700 : FontWeight.w500, maxLines: 1).expanded(),
            UTextLabelSmall(t.estimatedRows.toKMB(), color: cs.onSurface.withValues(alpha: 0.45)),
          ],
        )
        .pSymmetric(horizontal: 8, vertical: 8)
        .container(backgroundColor: active ? cs.primary.withValues(alpha: 0.08) : null, radius: 8)
        .pSymmetric(horizontal: 6, vertical: 1)
        .onTap(() => _selectTable(t));
  }

  // ===== Main =====

  Widget _main(ColorScheme cs, {bool showMenu = false}) {
    if (_selected == null && _tab != 2) {
      return UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showMenu) _mobileMenuBar(cs),
          _placeholder(
            cs,
            Icons.storage_rounded,
            "Select a table to get started",
            showMenu ? "Tap the menu to pick a table, or open the Query tab." : "Pick a table from the left to browse and edit its data, or open the Query tab.",
          ).expanded(),
        ],
      );
    }
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _toolbar(cs, showMenu: showMenu),
        const Divider(height: 1),
        IndexedStack(index: _tab, children: <Widget>[_dataTab(cs), _structureTab(cs), _queryTab(cs)]).expanded(),
      ],
    );
  }

  Widget _mobileMenuBar(ColorScheme cs) => Builder(
    builder: (BuildContext ctx) => URow(
      spacing: 4,
      children: <Widget>[
        IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(ctx).openDrawer()),
        UTextTitleSmall("${_tables.length} tables", color: cs.onSurface.withValues(alpha: 0.6)),
      ],
    ),
  );

  Widget _toolbar(ColorScheme cs, {bool showMenu = false}) => URow(
    children: <Widget>[
      if (showMenu) Builder(builder: (BuildContext ctx) => IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(ctx).openDrawer(), padding: EdgeInsets.zero)),
      if (!showMenu) Icon(Icons.grid_on_rounded, color: cs.primary, size: 18),
      Expanded(
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            UTextTitleSmall(_selected?.name ?? "SQL Query", fontWeight: FontWeight.bold, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_selected != null)
              UTextLabelSmall(
                "${_selected!.schema}  ·  ${_selected!.columnCount} cols${_selected!.size != null ? "  ·  ${_selected!.size}" : ""}",
                color: cs.onSurface.withValues(alpha: 0.55),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      _segTabs(cs, compact: showMenu),
    ],
  ).pSymmetric(horizontal: 14, vertical: 8);

  Widget _segTabs(ColorScheme cs, {bool compact = false}) {
    final List<(String, IconData)> tabs = <(String, IconData)>[("Data", Icons.grid_on_rounded), ("Structure", Icons.schema_rounded), ("Query", Icons.terminal_rounded)];
    return URow(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(tabs.length, (int i) {
        final bool active = _tab == i;
        return URow(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            Icon(tabs[i].$2, size: 15, color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.7)),
            if (!compact) UTextLabelMedium(tabs[i].$1, color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
          ],
        ).pSymmetric(horizontal: compact ? 8 : 12, vertical: 7).container(backgroundColor: active ? cs.primary : null, radius: 8).onTap(() => setState(() => _tab = i));
      }),
    ).pAll(3).container(backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5), radius: 11);
  }

  // ===== Data tab =====

  Widget _dataTab(ColorScheme cs) {
    if (_selected == null) return _placeholder(cs, Icons.touch_app_outlined, "No table selected", "");
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _dataToolbar(cs),
        SizedBox(
          height: 2,
          child: _loadingRows ? LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent, color: cs.primary) : null,
        ),
        if (_rows == null)
          const Center(child: UProgressCircular(size: 30)).pAll(40).expanded()
        else if (_rows!.columns.isEmpty)
          _placeholder(cs, Icons.inbox_outlined, "No rows", _whereController.text.trim().isEmpty ? "This table is empty." : "No rows match the filter.").expanded()
        else
          _grid(cs, _rows!, editable: true).expanded(),
        const Divider(height: 1),
        _paginationBar(cs),
      ],
    );
  }

  Widget _dataToolbar(ColorScheme cs) => URow(
    children: <Widget>[
      UTextField(
        controller: _whereController,
        hintText: "WHERE  e.g.  \"Status\" = 1  and  \"CreatedAt\" > now() - interval '7 days'",
        prefix: Icon(Icons.filter_alt_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
        hasClearButton: true,
        onFieldSubmitted: (String _) => _applyFilter(),
      ).expanded(),
      UButton(title: "Apply", type: UButtonType.outlined, icon: const Icon(Icons.play_arrow_rounded, size: 16), onTap: _applyFilter, padding: const EdgeInsets.symmetric(horizontal: 12)),
      _miniIcon(cs, Icons.add_rounded, "Insert row", _openRowEditor, filled: true),
      _miniIcon(cs, Icons.refresh_rounded, "Reload", () => _loadRows(withCount: true)),
    ],
  ).pSymmetric(horizontal: 14, vertical: 8);

  Widget _paginationBar(ColorScheme cs) {
    final int from = _totalCount == 0 ? 0 : (_page - 1) * _pageSize + 1;
    final int to = (_page * _pageSize) < _totalCount ? _page * _pageSize : _totalCount;
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: <Widget>[
        PopupMenuButton<int>(
          tooltip: "Rows per page",
          onSelected: _changePageSize,
          itemBuilder: (BuildContext ctx) => _pageSizes.map((int s) => PopupMenuItem<int>(value: s, child: Text("$s per page"))).toList(),
          child: URow(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: <Widget>[
              UTextLabelMedium("$_pageSize / page", fontWeight: FontWeight.w600),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
            ],
          ).pSymmetric(horizontal: 10, vertical: 6).container(backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5), radius: 8),
        ),
        URow(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            UTextLabelMedium("$from–$to of $_totalCount", color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            _pageBtn(cs, Icons.first_page_rounded, _page > 1, () => _gotoPage(1)),
            _pageBtn(cs, Icons.chevron_left_rounded, _page > 1, () => _gotoPage(_page - 1)),
            UTextLabelMedium("$_page / $_pageCount", fontWeight: FontWeight.w700).pSymmetric(horizontal: 4),
            _pageBtn(cs, Icons.chevron_right_rounded, _page < _pageCount, () => _gotoPage(_page + 1)),
            _pageBtn(cs, Icons.last_page_rounded, _page < _pageCount, () => _gotoPage(_pageCount)),
          ],
        ),
      ],
    ).pSymmetric(horizontal: 12, vertical: 6);
  }

  // ===== Structure tab =====

  Widget _structureTab(ColorScheme cs) {
    if (_loadingSchema && _schema == null) return const Center(child: UProgressCircular(size: 30)).pAll(40);
    final UDbTableSchemaResponse? s = _schema;
    if (s == null) return _placeholder(cs, Icons.inbox_outlined, "No structure", "");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: UColumn(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _card(
            cs,
            "Columns",
            Icons.view_column_outlined,
            s.columns.length,
            List<Widget>.generate(s.columns.length, (int i) {
              final UDbColumnResponse c = s.columns[i];
              return URow(
                spacing: 10,
                children: <Widget>[
                  SizedBox(width: 18, child: c.isPrimaryKey ? Icon(Icons.key_rounded, size: 14, color: cs.tertiary) : null),
                  UTextBodySmall(c.name, fontWeight: FontWeight.w600, fontFamily: "monospace").expanded(flex: 3),
                  _typeBadge(cs, c.dataType),
                  UTextLabelSmall(c.isNullable ? "nullable" : "not null", color: cs.onSurface.withValues(alpha: 0.55)).expanded(flex: 2),
                  UTextLabelSmall(c.defaultValue ?? "", color: cs.onSurface.withValues(alpha: 0.45), maxLines: 1, fontFamily: "monospace").expanded(flex: 3),
                ],
              ).pSymmetric(horizontal: 4, vertical: 7).container(backgroundColor: i.isOdd ? cs.surfaceContainerHighest.withValues(alpha: 0.28) : null, radius: 6);
            }),
          ),
          if (s.indexes.isNotEmpty)
            _card(
              cs,
              "Indexes",
              Icons.bolt_rounded,
              s.indexes.length,
              s.indexes
                  .map(
                    (UDbIndexResponse idx) => UColumn(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: <Widget>[
                        URow(
                          spacing: 6,
                          children: <Widget>[
                            if (idx.isPrimary) Icon(Icons.key_rounded, size: 13, color: cs.tertiary) else if (idx.isUnique) Icon(Icons.star_rounded, size: 13, color: cs.primary),
                            UTextBodySmall(idx.name, fontWeight: FontWeight.w600),
                          ],
                        ),
                        UTextLabelSmall(idx.definition, color: cs.onSurface.withValues(alpha: 0.5), fontFamily: "monospace"),
                      ],
                    ).pSymmetric(vertical: 6),
                  )
                  .toList(),
            ),
          if (s.foreignKeys.isNotEmpty)
            _card(
              cs,
              "Foreign Keys",
              Icons.link_rounded,
              s.foreignKeys.length,
              s.foreignKeys
                  .map(
                    (UDbForeignKeyResponse fk) => URow(
                      children: <Widget>[
                        UTextBodySmall(fk.column, fontWeight: FontWeight.w600, fontFamily: "monospace"),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                        UTextBodySmall("${fk.referencesTable}.${fk.referencesColumn}", color: cs.primary, fontFamily: "monospace"),
                      ],
                    ).pSymmetric(vertical: 6),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  // ===== Query tab =====

  Widget _queryTab(ColorScheme cs) => SingleChildScrollView(
    padding: const EdgeInsets.all(14),
    child: UColumn(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          children: <Widget>[
            Icon(Icons.terminal_rounded, color: cs.primary, size: 18),
            const UTextTitleSmall("SQL Editor", fontWeight: FontWeight.bold).expanded(),
            PopupMenuButton<_Prebuilt>(
              tooltip: "Snippets",
              onSelected: (_Prebuilt q) => setState(() => _sqlController.text = q.sql(_selected?.name ?? "table_name", _selected?.schema ?? "public")),
              itemBuilder: (BuildContext ctx) => _prebuilt
                  .map(
                    (_Prebuilt q) => PopupMenuItem<_Prebuilt>(
                      value: q,
                      child: URow(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(q.icon, size: 15, color: cs.primary),
                          Text(q.title),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              child: URow(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: <Widget>[
                  Icon(Icons.bookmark_border_rounded, size: 16, color: cs.primary),
                  const UTextLabelMedium("Snippets", fontWeight: FontWeight.w600),
                  Icon(Icons.arrow_drop_down_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
                ],
              ).pSymmetric(horizontal: 10, vertical: 7).container(backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5), radius: 8),
            ),
            UButton(title: "Run", icon: const Icon(Icons.play_arrow_rounded, size: 18), isLoading: _queryRunning, onTap: _runQuery),
          ],
        ),
        TextField(
          controller: _sqlController,
          maxLines: 9,
          minLines: 6,
          style: const TextStyle(fontFamily: "monospace", fontSize: 13, height: 1.4),
          decoration: InputDecoration(
            hintText: "SELECT * FROM ...",
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
          ),
        ),
        if (_queryError != null)
          URow(
            margin: const EdgeInsets.all(12),
            color: cs.errorContainer.withValues(alpha: 0.35),
            radius: 10,
            border: Border.all(color: cs.error.withValues(alpha: 0.3)),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
              SelectableText(
                _queryError!,
                style: TextStyle(color: cs.error, fontSize: 12.5, fontFamily: "monospace"),
              ).expanded(),
            ],
          ),
        if (_queryResult != null) _queryResultView(cs, _queryResult!),
      ],
    ),
  );

  Widget _queryResultView(ColorScheme cs, UDbQueryResultResponse r) {
    final String meta = r.columns.isEmpty ? "${r.affectedRows ?? 0} rows affected  ·  ${r.executionMs} ms" : "${r.rowCount} rows  ·  ${r.executionMs} ms${r.truncated ? "  ·  truncated" : ""}";
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          spacing: 6,
          children: <Widget>[
            Icon(r.columns.isEmpty ? Icons.check_circle_outline_rounded : Icons.table_rows_rounded, size: 15, color: cs.primary),
            UTextLabelSmall(meta, color: cs.onSurface.withValues(alpha: 0.65)),
          ],
        ),
        if (r.columns.isNotEmpty) ConstrainedBox(constraints: const BoxConstraints(maxHeight: 460), child: _grid(cs, r, editable: false)),
      ],
    );
  }

  // ===== Shared result grid =====

  Widget _grid(ColorScheme cs, UDbQueryResultResponse data, {required bool editable}) {
    final bool canMutate = editable && data.primaryKeyColumn != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 40,
          horizontalMargin: 12,
          columnSpacing: 20,
          dividerThickness: 0.4,
          headingRowColor: WidgetStatePropertyAll<Color>(cs.surfaceContainerHighest.withValues(alpha: 0.55)),
          border: TableBorder(horizontalInside: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4), width: 0.4)),
          columns: <DataColumn>[
            if (canMutate) const DataColumn(label: SizedBox(width: 4)),
            ...List<DataColumn>.generate(data.columns.length, (int i) {
              final String col = data.columns[i];
              final bool sorted = editable && _orderBy == col;
              return DataColumn(
                label: URow(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: <Widget>[
                    UTextLabelMedium(col, fontWeight: FontWeight.w800),
                    if (i < data.columnTypes.length && data.columnTypes[i] != null) UTextLabelSmall(data.columnTypes[i]!, color: cs.onSurface.withValues(alpha: 0.4)),
                    if (sorted) Icon(_descending ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 12, color: cs.primary),
                  ],
                ),
                onSort: editable ? (int columnIndex, bool ascending) => _sortBy(col) : null,
              );
            }),
          ],
          rows: List<DataRow>.generate(data.rows.length, (int rowIndex) {
            final Map<String, String?> row = data.rows[rowIndex];
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.hovered)) return cs.primary.withValues(alpha: 0.06);
                return rowIndex.isOdd ? cs.surfaceContainerHighest.withValues(alpha: 0.22) : null;
              }),
              cells: <DataCell>[
                if (canMutate)
                  DataCell(
                    URow(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _cellIcon(cs, Icons.visibility_outlined, "View", () => _viewRow(row)),
                        _cellIcon(cs, Icons.edit_outlined, "Edit", () => _openRowEditor(original: row), color: cs.primary),
                        _cellIcon(cs, Icons.delete_outline_rounded, "Delete", () => _deleteRow(row), color: cs.error),
                      ],
                    ),
                  ),
                ...data.columns.map((String col) {
                  final String? value = row[col];
                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: value == null
                          ? UTextLabelSmall("NULL", color: cs.onSurface.withValues(alpha: 0.32), fontStyle: FontStyle.italic)
                          : UTextBodySmall(value, maxLines: 1, fontFamily: "monospace"),
                    ),
                    onTap: value == null
                        ? null
                        : () {
                            UClipboard.set(value);
                            UToast.info(message: "Copied");
                          },
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ===== Small building blocks =====

  Widget _card(ColorScheme cs, String title, IconData icon, int count, List<Widget> children) => UCard(
    child: UColumn(
      margin: const EdgeInsets.all(16),
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          children: <Widget>[
            Icon(icon, color: cs.primary, size: 18),
            UTextTitleSmall(title, fontWeight: FontWeight.bold),
            UTextLabelSmall(
              "$count",
              color: cs.onSurface.withValues(alpha: 0.5),
            ).pSymmetric(horizontal: 7, vertical: 2).container(backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6), radius: 20),
          ],
        ),
        const Divider(height: 14),
        ...children,
      ],
    ),
  );

  Widget _typeBadge(ColorScheme cs, String type) =>
      UTextLabelSmall(type, color: cs.primary, fontWeight: FontWeight.w600).pSymmetric(horizontal: 8, vertical: 3).container(backgroundColor: cs.primary.withValues(alpha: 0.1), radius: 6);

  Widget _miniIcon(ColorScheme cs, IconData icon, String tooltip, VoidCallback onTap, {bool filled = false}) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    style: filled ? IconButton.styleFrom(backgroundColor: cs.primary.withValues(alpha: 0.12)) : null,
    icon: Icon(icon, color: cs.primary),
  );

  Widget _pageBtn(ColorScheme cs, IconData icon, bool enabled, VoidCallback onTap) => IconButton(
    onPressed: enabled ? onTap : null,
    visualDensity: VisualDensity.compact,
    iconSize: 20,
    icon: Icon(icon),
  );

  Widget _cellIcon(ColorScheme cs, IconData icon, String tooltip, VoidCallback onTap, {Color? color}) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    iconSize: 16,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    padding: EdgeInsets.zero,
    icon: Icon(icon, color: color ?? cs.onSurface.withValues(alpha: 0.7)),
  );

  Widget _placeholder(ColorScheme cs, IconData icon, String title, String subtitle) => UColumn(
    margin: const EdgeInsets.all(40),
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 10,
    children: <Widget>[
      Icon(icon, size: 44, color: cs.onSurface.withValues(alpha: 0.22)),
      UTextBodyMedium(title, color: cs.onSurface.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
      if (subtitle.isNotEmpty)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: UTextBodySmall(subtitle, color: cs.onSurface.withValues(alpha: 0.4), textAlign: TextAlign.center),
        ),
    ],
  );

  // Prebuilt query catalog for the Query tab snippets menu.
  List<_Prebuilt> get _prebuilt => <_Prebuilt>[
    _Prebuilt("Row counts per table", Icons.numbers_rounded, (String t, String s) => "SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY n_live_tup DESC;"),
    _Prebuilt(
      "Table sizes",
      Icons.sd_storage_outlined,
      (String t, String s) => "SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS size FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;",
    ),
    _Prebuilt("Recent rows (selected)", Icons.history_rounded, (String t, String s) => 'SELECT * FROM "$s"."$t" ORDER BY "CreatedAt" DESC LIMIT 50;'),
    _Prebuilt("Database size", Icons.data_usage_rounded, (String t, String s) => "SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;"),
    _Prebuilt("Connections by state", Icons.cable_rounded, (String t, String s) => "SELECT state, count(*) FROM pg_stat_activity GROUP BY state ORDER BY count DESC;"),
    _Prebuilt(
      "Long-running queries",
      Icons.timelapse_rounded,
      (String t, String s) => "SELECT pid, now() - query_start AS duration, state, query FROM pg_stat_activity WHERE state <> 'idle' AND query_start IS NOT NULL ORDER BY duration DESC LIMIT 20;",
    ),
    _Prebuilt(
      "Cache hit ratio",
      Icons.speed_rounded,
      (String t, String s) => "SELECT round(sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0), 4) AS cache_hit_ratio FROM pg_statio_user_tables;",
    ),
    _Prebuilt(
      "Index usage",
      Icons.bolt_rounded,
      (String t, String s) => "SELECT relname AS table, indexrelname AS index, idx_scan AS scans FROM pg_stat_user_indexes ORDER BY idx_scan DESC LIMIT 30;",
    ),
    _Prebuilt(
      "Dead rows (vacuum)",
      Icons.cleaning_services_rounded,
      (String t, String s) => "SELECT relname AS table, n_dead_tup AS dead_rows FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 20;",
    ),
  ];
}

class _Prebuilt {
  _Prebuilt(this.title, this.icon, this.sql);

  final String title;
  final IconData icon;
  final String Function(String table, String schema) sql;
}
