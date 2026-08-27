import "package:u/utilities.dart";

class UAdminApiLogPage extends StatefulWidget {
  const UAdminApiLogPage({super.key});

  @override
  State<UAdminApiLogPage> createState() => _ApiLogPageState();
}

class _ApiLogPageState extends State<UAdminApiLogPage> {
  final UAdminApiLogController c = UAdminApiLogController();

  @override
  void initState() {
    super.initState();
    c.init();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  bool get _isWide => MediaQuery.sizeOf(context).width > 1000;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.apiRequestLogs),
      centerTitle: true,
      actions: <Widget>[
        IconButton(tooltip: U.s.applicationLogs, icon: const Icon(Icons.terminal_rounded), onPressed: _openAppLogs),
        IconButton(tooltip: U.s.filter, icon: const Icon(Icons.tune_rounded), onPressed: _showFilterDialog),
        IconButton(tooltip: U.s.refresh, icon: const Icon(Icons.refresh_rounded), onPressed: c.refreshAll),
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(_isWide ? 24 : 14),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Obx(_hero),
          Obx(_osMetricsSection).pSymmetric(vertical: 16),
          Obx(_chartsSection).pSymmetric(vertical: 16),
          Obx(_endpointsSection).pSymmetric(),
          Obx(_slowestRequestsSection).pSymmetric(vertical: 16),
          _quickFilters(),
          const SizedBox(height: 16),
          _table(),
          Obx(
            () => UNumberPagination(
              currentPage: c.pageNumber.value,
              totalPages: c.totalPages.value,
              onPageChanged: (int page) {
                c.pageNumber(page);
                c.search();
              },
            ).pOnly(bottom: 8, top: 16),
          ),
        ],
      ),
    ),
  );

  Widget _hero() {
    final UApiLogStatsResponse? s = c.stats.value;
    return UContainer(
      padding: const EdgeInsets.all(24),
      radius: 24,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Theme.of(context).colorScheme.primary, UAdminTheme.indigo.shade400, UAdminTheme.blueGrey.shade400],
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
      ],
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UIconTextHorizontal(
            leading: const Icon(Icons.travel_explore_rounded, color: UAdminTheme.white, size: 34),
            trailing: UTextHeadlineSmall(U.s.apiRequestLogs, color: UAdminTheme.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (c.state2.value.isLoading())
            const CircularProgressIndicator(color: UAdminTheme.white).alignAtCenter().pSymmetric(vertical: 20)
          else if (c.state2.value.isError())
            UIconTextHorizontal(
              leading: const Icon(Icons.cloud_off_rounded, color: UAdminTheme.white),
              trailing: UTextBodyMedium(U.s.errorReadingData, color: UAdminTheme.white),
              margin: const EdgeInsets.symmetric(vertical: 12),
            )
          else ...<Widget>[
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: <Widget>[
                _kpi(U.s.totalRequests, "${s?.totalCount ?? 0}"),
                _kpi(U.s.success, "${s?.successCount ?? 0}"),
                _kpi(U.s.errors, "${s?.errorCount ?? 0}"),
                _kpi(U.s.averageDuration, "${(s?.averageDurationMs ?? 0).toStringAsFixed(0)} ms"),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _percentileBadge("P50", s?.p50DurationMs ?? 0),
                _percentileBadge("P95", s?.p95DurationMs ?? 0),
                _percentileBadge("P99", s?.p99DurationMs ?? 0),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kpi(String title, String value) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UTextBodySmall(title, color: UAdminTheme.white.withValues(alpha: 0.75)),
      const SizedBox(height: 4),
      UTextHeadlineSmall(value, color: UAdminTheme.white, fontWeight: FontWeight.w800),
    ],
  );

  Widget _percentileBadge(String label, double ms) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    color: UAdminTheme.white.withValues(alpha: 0.14),
    radius: 20,
    child: UTextBodySmall("$label: ${ms.toStringAsFixed(0)} ms", color: UAdminTheme.white, fontWeight: FontWeight.w600).ltr(),
  );

  Widget _osMetricsSection() {
    final UOsMetricsResponse? m = c.osMetrics.value;
    return UColumn(
      padding: const EdgeInsets.all(20),
      radius: 20,
      color: Theme.of(context).cardTheme.color,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          children: <Widget>[
            const Icon(Icons.dns_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.osMetrics, fontWeight: FontWeight.w700, expanded: 1),
            if (m != null)
              UContainer(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: UAdminTheme.green.withValues(alpha: 0.14),
                radius: 20,
                child: URow(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const UContainer(
                      width: 8,
                      height: 8,
                      color: UAdminTheme.green,
                      shape: BoxShape.circle,
                    ),
                    const SizedBox(width: 6),
                    UTextBodySmall(m.generatedAt.toJalaliDateTime(), color: UAdminTheme.green, fontWeight: FontWeight.w600).ltr(),
                  ],
                ),
              ),
          ],
        ),
        const Divider(height: 18),
        if (c.osMetricsState.value.isLoading() && m == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (c.osMetricsState.value.isError() && m == null)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: UTextBodyMedium(U.s.errorReadingData).alignAtCenter())
        else if (m == null)
          const SizedBox.shrink()
        else ...<Widget>[
          URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _osIdentityRow(m).expanded(),
              _usageGauges(m).expanded(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _osIdentityRow(UOsMetricsResponse m) => UColumn(
    spacing: 12,
    children: <Widget>[
      _identityItem(Icons.computer_rounded, U.s.operatingSystem, m.osDescription),
      _identityItem(Icons.memory_rounded, U.s.architecture, "${m.osArchitecture} (${m.processArchitecture})"),
      _identityItem(Icons.developer_board_rounded, U.s.framework, m.frameworkDescription),
      _identityItem(Icons.dns_outlined, U.s.machineName, m.machineName),
      _identityItem(Icons.timer_outlined, U.s.systemUptime, _formatDuration(m.systemUptimeSeconds)),
      _identityItem(Icons.play_circle_outline_rounded, U.s.processUptime, _formatDuration(m.processUptimeSeconds)),
      if (m.loadAverage1Min != null)
        _identityItem(
          Icons.speed_rounded,
          U.s.loadAverage,
          "${m.loadAverage1Min!.toStringAsFixed(2)} / ${m.loadAverage5Min!.toStringAsFixed(2)} / ${m.loadAverage15Min!.toStringAsFixed(2)}",
        ),
    ],
  );

  Widget _identityItem(IconData icon, String label, String value) => ListTile(
    dense: true,
    leading: UIconBackground(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label),
    subtitle: Text(value),
  );

  Widget _usageGauges(UOsMetricsResponse m) => UColumn(
    spacing: 12,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _usageBar(U.s.cpuUsage, m.cpuUsagePercent, "${m.processorCount} ${U.s.cores}"),
      _usageBar(U.s.memoryUsage, m.memoryUsagePercent, "${m.memoryUsedGb.toStringAsFixed(1)} / ${m.memoryTotalGb.toStringAsFixed(1)} GB"),
      _usageBar(U.s.diskUsage, m.diskUsagePercent, "${m.diskUsedGb.toStringAsFixed(1)} / ${m.diskTotalGb.toStringAsFixed(1)} GB"),
    ],
  );

  Widget _usageBar(String label, double percent, String caption) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      URow(
        children: <Widget>[
          UTextBodyMedium(label, fontWeight: FontWeight.w600, expanded: 1),
          UTextBodyMedium("${percent.toStringAsFixed(1)}%", color: _usageColor(percent), fontWeight: FontWeight.w700),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: (percent / 100).clamp(0, 1),
          minHeight: 8,
          backgroundColor: _usageColor(percent).withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(_usageColor(percent)),
        ),
      ),
      const SizedBox(height: 4),
      UTextBodySmall(caption, color: Theme.of(context).disabledColor).ltr(),
    ],
  );

  Color _usageColor(double percent) {
    if (percent >= 85) return UAdminTheme.red;
    if (percent >= 60) return UAdminTheme.orange;
    return UAdminTheme.green;
  }

  String _formatDuration(double seconds) {
    final Duration d = Duration(seconds: seconds.round());
    final int days = d.inDays;
    final int hours = d.inHours % 24;
    final int minutes = d.inMinutes % 60;
    if (days > 0) return "${days}d ${hours}h ${minutes}m";
    if (hours > 0) return "${hours}h ${minutes}m";
    return "${minutes}m";
  }

  Widget _chartsSection() {
    final UApiLogStatsResponse? s = c.stats.value;
    if (c.state2.value.isLoading() || s == null) return const SizedBox.shrink();
    return _isWide
        ? URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _timelineChart().expanded(flex: 2),
              const SizedBox(width: 16),
              _distributionChart().expanded(),
            ],
          )
        : UColumn(
            children: <Widget>[
              _timelineChart(),
              const SizedBox(height: 16),
              _distributionChart(),
            ],
          );
  }

  Widget _timelineChart() => _chartCard(
    title: U.s.requestsAndResponseDurationTrend,
    trailing: URow(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _bucketButton("minute", U.s.minute),
        _bucketButton("hour", U.s.hour),
        _bucketButton("day", U.s.day),
      ],
    ),
    child: (c.stats.value?.timeline.isEmpty ?? true)
        ? Center(child: UTextBodyMedium(U.s.noData))
        : ULineChart(
            smooth: true,
            showDots: false,
            categories: c.stats.value!.timeline.map((UApiLogBucketResponse b) => _bucketLabel(b.time)).toList(),
            series: <UChartSeries>[
              UChartSeries(name: U.s.count, color: Theme.of(context).colorScheme.primary, filled: true, values: c.stats.value!.timeline.map((UApiLogBucketResponse b) => b.count.toDouble()).toList()),
              UChartSeries(name: U.s.errors, color: UAdminTheme.red, values: c.stats.value!.timeline.map((UApiLogBucketResponse b) => b.errorCount.toDouble()).toList()),
            ],
          ),
  );

  String _bucketLabel(DateTime t) => c.bucket.value == "day" ? "${t.month}/${t.day}" : "${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}";

  Widget _bucketButton(String value, String label) => Obx(
    () => TextButton(
      onPressed: () => c.setBucket(value),
      style: TextButton.styleFrom(foregroundColor: c.bucket.value == value ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor),
      child: Text(label),
    ),
  );

  Widget _distributionChart() => _chartCard(
    title: U.s.successErrorDistribution,
    child: (c.stats.value?.totalCount ?? 0) == 0
        ? Center(child: UTextBodyMedium(U.s.noData))
        : UDonutChart(
            slices: <USlice>[
              USlice(value: c.stats.value!.successCount.toDouble(), label: U.s.success, color: UAdminTheme.green),
              USlice(value: c.stats.value!.errorCount.toDouble(), label: U.s.errors, color: UAdminTheme.red),
            ],
          ),
  );

  Widget _chartCard({required String title, required Widget child, Widget? trailing}) => UColumn(
    height: 320,
    padding: const EdgeInsets.all(18),
    radius: 12,
    color: Theme.of(context).cardTheme.color,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      URow(
        children: <Widget>[
          UTextTitleSmall(title, fontWeight: FontWeight.w700, expanded: 1),
          ?trailing,
        ],
      ),
      const Divider(height: 18),
      child.expanded(),
    ],
  );

  Widget _endpointsSection() {
    final UApiLogStatsResponse? s = c.stats.value;
    if (c.state2.value.isLoading() || s == null) return const SizedBox.shrink();
    return _isWide
        ? URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _endpointBarChart(title: U.s.slowestPaths, items: s.slowestEndpoints, color: UAdminTheme.orange).expanded(),
              const SizedBox(width: 16),
              _endpointBarChart(title: U.s.mostFailingPaths, items: s.failingEndpoints, color: UAdminTheme.red).expanded(),
            ],
          )
        : UColumn(
            children: <Widget>[
              _endpointBarChart(title: U.s.slowestPaths, items: s.slowestEndpoints, color: UAdminTheme.orange),
              const SizedBox(height: 16),
              _endpointBarChart(title: U.s.mostFailingPaths, items: s.failingEndpoints, color: UAdminTheme.red),
            ],
          );
  }

  Widget _endpointBarChart({required String title, required List<UApiLogEndpointResponse> items, required Color color}) => _chartCard(
    title: title,
    child: items.isEmpty
        ? Center(child: UTextBodyMedium(U.s.noData))
        : UHorizontalBarChart(
            categories: items.map((UApiLogEndpointResponse e) => e.path.subStringIfExist(0, 32)).toList(),
            series: <UChartSeries>[UChartSeries(color: color, values: items.map((UApiLogEndpointResponse e) => e.averageDurationMs.toDouble()).toList())],
          ),
  );

  Widget _slowestRequestsSection() {
    if (c.state2.value.isLoading() || c.stats.value == null) return const SizedBox.shrink();
    final List<UApiLogResponse> items = c.stats.value!.slowestRequests;
    return UContainer(
      padding: const EdgeInsets.all(18),
      radius: 20,
      color: Theme.of(context).cardTheme.color,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            children: <Widget>[
              const Icon(Icons.local_fire_department_rounded, size: 20, color: UAdminTheme.orange),
              const SizedBox(width: 8),
              UTextTitleSmall(U.s.slowestRequests, fontWeight: FontWeight.w700, expanded: 1),
            ],
          ),
          const Divider(height: 18),
          if (items.isEmpty)
            UTextBodySmall(U.s.noData, margin: const EdgeInsets.symmetric(vertical: 12))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (BuildContext context, int index) => const Divider(height: 4),
              itemBuilder: (BuildContext context, int index) => _slowRequestRow(items[index]),
            ),
        ],
      ),
    );
  }

  Widget _slowRequestRow(UApiLogResponse i) => ListTile(
    dense: true,
    onTap: () => _openDetail(i),
    leading: _methodChip(i.jsonData.method),
    title: UTextBodyMedium(i.path, maxLines: 1, overflow: TextOverflow.ellipsis).ltr(),
    subtitle: UTextBodySmall(i.createdAt.toJalaliDateTime()).ltr(),
    trailing: URow(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_hasException(i)) _exceptionBadge(),
        _statusChip(i.statusCode),
        const SizedBox(width: 8),
        UTextBodyMedium("${i.durationMs} ms", color: UAdminTheme.orange),
      ],
    ),
  );

  Widget _quickFilters() => Obx(
    () => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _filterChip(U.s.all, c.methodFilter.value == null, () {
          c.methodFilter(null);
          c.refreshList();
        }),
        ...TagApiLog.values
            .where((TagApiLog t) => t.number < 200)
            .map(
              (TagApiLog t) => _filterChip(t.localizedTitle, c.methodFilter.value == t, () {
                c.methodFilter(c.methodFilter.value == t ? null : t);
                c.refreshList();
              }),
            ),
        _filterChip(U.s.onlyErrors, c.onlyErrors.value, () {
          c.onlyErrors(!c.onlyErrors.value);
          c.refreshList();
        }),
        _filterChip(U.s.onlyExceptions, c.onlyExceptions.value, () {
          c.onlyExceptions(!c.onlyExceptions.value);
          c.refreshList();
        }),
      ],
    ),
  );

  Widget _filterChip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );

  Widget _table() => Obx(() {
    if (c.state.value.isError()) return _tableMessage(icon: Icons.cloud_off_rounded, text: U.s.errorReadingData, retry: true);
    if (c.state.value.isEmpty()) return _tableMessage(icon: Icons.inbox_rounded, text: U.s.noData, retry: false);
    if (!c.state.value.isLoaded()) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final List<UApiLogResponse> data = c.list;
    final bool desktop = MediaQuery.sizeOf(context).width >= 800;
    final Widget list = desktop
        ? UListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            header: URow(
              spacing: 8,
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(8),
              children: <Widget>[
                UTextBodyLarge(U.s.time, color: UAdminTheme.white, textAlign: .center, expanded: 1),
                UTextBodyLarge(U.s.method, color: UAdminTheme.white, textAlign: .center, expanded: 1),
                UTextBodyLarge(U.s.path, color: UAdminTheme.white, textAlign: .center, expanded: 3),
                UTextBodyLarge(U.s.status, color: UAdminTheme.white, textAlign: .center, expanded: 1),
                UTextBodyLarge(U.s.duration, color: UAdminTheme.white, textAlign: .center, expanded: 1),
                UTextBodyLarge(U.s.user, color: UAdminTheme.white, textAlign: .center, expanded: 2),
                const UTextBodyLarge("IP", color: UAdminTheme.white, textAlign: .center, expanded: 2),
              ],
            ),
            itemBuilder: (BuildContext context, int index) => _itemDesktop(i: data[index], index: index),
            itemCount: data.length,
          )
        : UListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) => _itemResponsive(i: data[index], index: index),
            itemCount: data.length,
          );

    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: URow(
            children: <Widget>[
              Icon(Icons.format_list_bulleted_rounded, size: 16, color: Theme.of(context).disabledColor),
              const SizedBox(width: 6),
              UTextBodySmall("${U.s.totalResults}: ${c.totalCount.toString().separateNumbers3By3()}", color: Theme.of(context).disabledColor),
            ],
          ),
        ),
        list,
      ],
    );
  });

  Widget _tableMessage({required IconData icon, required String text, required bool retry}) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: UColumn(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 56, color: retry ? Theme.of(context).colorScheme.error : Theme.of(context).disabledColor),
          const SizedBox(height: 12),
          UTextBodyMedium(text, color: retry ? null : Theme.of(context).disabledColor),
          if (retry) ...<Widget>[
            const SizedBox(height: 12),
            UButton(title: U.s.tryAgain, icon: const Icon(Icons.refresh), onTap: c.search, width: 180),
          ],
        ],
      ),
    ),
  );

  Widget _itemDesktop({required UApiLogResponse i, required int index}) => URow(
    onTap: () => _openDetail(i),
    spacing: 8,
    color: index.isOdd ? UAdminTheme.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
    children: <Widget>[
      UTextBodySmall(i.createdAt.toJalaliDateTime(), textAlign: .center).ltr().expanded(),
      _methodChip(i.jsonData.method).alignAtCenter().expanded(),
      _pathCell(i).expanded(flex: 3),
      _statusChip(i.statusCode).alignAtCenter().expanded(),
      UTextBodyMedium("${i.durationMs} ms", textAlign: .center, color: i.durationMs > 1000 ? UAdminTheme.orange : null, expanded: 1),
      _userCell(i).expanded(flex: 2),
      UTextBodySmall(i.ipAddress ?? "-", textAlign: .center, overflow: TextOverflow.ellipsis).ltr().expanded(flex: 2),
    ],
  );

  Widget _itemResponsive({required UApiLogResponse i, required int index}) => UContainer(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    margin: const EdgeInsets.symmetric(vertical: 4),
    color: index.isOdd ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
    radius: 8,
    child: InkWell(
      onTap: () => _openDetail(i),
      child: ListTile(
        dense: true,
        leading: _statusChip(i.statusCode),
        title: URow(
          children: <Widget>[
            _methodChip(i.jsonData.method),
            const SizedBox(width: 8),
            UTextBodyMedium(i.path, maxLines: 1, overflow: TextOverflow.ellipsis).ltr().expanded(),
            if (_hasException(i)) _exceptionBadge(),
          ],
        ),
        subtitle: UTextBodySmall("${i.createdAt.toJalaliDateTime()} • ${i.durationMs} ms${i.ipAddress != null ? " • ${i.ipAddress}" : ""}").ltr(),
        trailing: const Icon(Icons.chevron_left_rounded),
      ),
    ),
  );

  bool _hasException(UApiLogResponse i) => i.tags.contains(TagApiLog.hasException.number);

  Widget _exceptionBadge() => Tooltip(
    message: U.s.exception,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 2, end: 6),
      child: Icon(Icons.error_outline_rounded, size: 16, color: Theme.of(context).colorScheme.error),
    ),
  );

  Widget _userCell(UApiLogResponse i) {
    final UApiLogJson j = i.jsonData;
    final String fullName = <String?>[j.userFirstName, j.userLastName].where((String? e) => e.nullIfEmpty() != null).join(" ").trim();
    final String? username = j.userName.nullIfEmpty();
    final String? phone = j.userPhoneNumber.nullIfEmpty();
    final String? email = j.userEmail.nullIfEmpty();
    final String primary = fullName.isNotEmpty ? fullName : (username ?? U.s.guest);
    final List<String> sub = <String>[
      if (fullName.isNotEmpty && username != null) "@$username",
      if (phone != null) phone,
      if (email != null) email,
    ];
    final bool hasUser = fullName.isNotEmpty || username != null || phone != null || email != null;
    if (!hasUser) return UTextBodySmall("-", textAlign: .center, color: Theme.of(context).disabledColor);
    return Tooltip(
      message: _userTooltip(j),
      child: UColumn(
        spacing: 2,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextBodySmall(primary, textAlign: .center, maxLines: 1, overflow: TextOverflow.ellipsis, fontWeight: FontWeight.w700),
          if (sub.isNotEmpty) UTextLabelSmall(sub.join(" • "), textAlign: .center, maxLines: 2, overflow: TextOverflow.ellipsis, color: Theme.of(context).disabledColor).ltr(),
        ],
      ),
    );
  }

  String _userTooltip(UApiLogJson j) => <String>[
    if (j.userFirstName.nullIfEmpty() != null) "${U.s.firstName}: ${j.userFirstName}",
    if (j.userLastName.nullIfEmpty() != null) "${U.s.lastName}: ${j.userLastName}",
    if (j.userName.nullIfEmpty() != null) "${U.s.username}: ${j.userName}",
    if (j.userPhoneNumber.nullIfEmpty() != null) "${U.s.phoneNumber}: ${j.userPhoneNumber}",
    if (j.userEmail.nullIfEmpty() != null) "${U.s.email}: ${j.userEmail}",
  ].join("\n");

  Widget _pathCell(UApiLogResponse i) => URow(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      if (_hasException(i)) _exceptionBadge(),
      Flexible(
        child: UTextBodyMedium(i.path, textAlign: .center, maxLines: 2, overflow: TextOverflow.ellipsis).ltr(),
      ),
    ],
  );

  Widget _methodChip(String method) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    color: _methodColor(method).withValues(alpha: 0.15),
    radius: 20,
    child: UTextBodySmall(method, color: _methodColor(method), fontWeight: FontWeight.w700).ltr(),
  );

  Widget _statusChip(int statusCode) => UContainer(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    color: _statusColor(statusCode).withValues(alpha: 0.15),
    radius: 20,
    child: UTextBodySmall(statusCode.toString(), color: _statusColor(statusCode), fontWeight: FontWeight.w700).ltr(),
  );

  Color _methodColor(String method) => switch (method.toUpperCase()) {
    "GET" => UAdminTheme.blue,
    "POST" => UAdminTheme.green,
    "PUT" => UAdminTheme.orange,
    "PATCH" => UAdminTheme.indigo,
    "DELETE" => UAdminTheme.red,
    _ => UAdminTheme.grey,
  };

  Color _statusColor(int statusCode) {
    if (statusCode >= 500) return UAdminTheme.red;
    if (statusCode >= 400) return UAdminTheme.orange;
    if (statusCode >= 300) return UAdminTheme.blue;
    if (statusCode >= 200) return UAdminTheme.green;
    return UAdminTheme.grey;
  }

  void _showFilterDialog() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.filterItem(U.s.logs)),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.pathContainsCtrl, labelText: U.s.pathContains, margin: const EdgeInsets.symmetric(vertical: 6)),
              URow(
                margin: const EdgeInsets.symmetric(vertical: 6),
                children: <Widget>[
                  UTextField(controller: c.minDurationCtrl, labelText: U.s.minDurationMs, keyboardType: TextInputType.number, expanded: 1),
                  const SizedBox(width: 8),
                  UTextField(controller: c.maxDurationCtrl, labelText: U.s.maxDurationMs, keyboardType: TextInputType.number, expanded: 1),
                ],
              ),
              UTextField(controller: c.statusCodeCtrl, labelText: U.s.exactStatusCode, keyboardType: TextInputType.number, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.userIdCtrl, labelText: U.s.userId, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.ipAddressCtrl, labelText: U.s.ipAddress, margin: const EdgeInsets.symmetric(vertical: 6)),
              UTextField(controller: c.traceIdCtrl, labelText: U.s.traceId, margin: const EdgeInsets.symmetric(vertical: 6)),
              Obx(
                () => UDropDownField<TagApiLog?>(
                  initialValue: c.methodFilter.value,
                  onChanged: (TagApiLog? v) => c.methodFilter.value = v,
                  items: <DropdownMenuItem<TagApiLog?>>[
                    DropdownMenuItem<TagApiLog?>(child: Text(U.s.all)),
                    ...TagApiLog.values.where((TagApiLog t) => t.number < 200).map((TagApiLog t) => DropdownMenuItem<TagApiLog?>(value: t, child: Text(t.localizedTitle))),
                  ],
                ),
              ).pSymmetric(vertical: 6),
              Obx(
                () => UDropDownField<TagOrderBy>(
                  initialValue: c.orderBy.value,
                  onChanged: (TagOrderBy? v) => c.orderBy.value = v ?? c.orderBy.value,
                  items: <DropdownMenuItem<TagOrderBy>>[
                    DropdownMenuItem<TagOrderBy>(value: TagOrderBy.createdAtDescending, child: Text(TagOrderBy.createdAtDescending.localizedTitle)),
                    DropdownMenuItem<TagOrderBy>(value: TagOrderBy.createdAt, child: Text(TagOrderBy.createdAt.localizedTitle)),
                    DropdownMenuItem<TagOrderBy>(value: TagOrderBy.durationMsDescending, child: Text(TagOrderBy.durationMsDescending.localizedTitle)),
                    DropdownMenuItem<TagOrderBy>(value: TagOrderBy.durationMs, child: Text(TagOrderBy.durationMs.localizedTitle)),
                  ],
                ),
              ).pSymmetric(vertical: 6),
              Obx(
                () => CheckboxListTile(
                  value: c.onlyErrors.value,
                  onChanged: (bool? v) => c.onlyErrors.value = v ?? false,
                  title: Text(U.s.onlyErrors),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              Obx(
                () => CheckboxListTile(
                  value: c.onlyExceptions.value,
                  onChanged: (bool? v) => c.onlyExceptions.value = v ?? false,
                  title: Text(U.s.onlyExceptions),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 20),
              UButtonSubmitCancel(
                submitTitle: U.s.filter,
                cancelTitle: U.s.clearFilters,
                onSubmit: () {
                  c.applyFilters();
                  UNavigator.back();
                },
                onCancel: () {
                  c.clearFilters();
                  UNavigator.back();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _openDetail(UApiLogResponse item) => c.openDetail(item, (UApiLogResponse detail) {
    UNavigator.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: context.dialogWidth(max: 820),
          height: context.dialogHeight(max: 680),
          child: _ApiLogDetailView(item: detail, methodColor: _methodColor(detail.jsonData.method), statusColor: _statusColor(detail.statusCode)),
        ),
      ),
    );
  });

  void _openAppLogs() {
    c.loadAppLogs();
    UNavigator.dialog(
      UScaffold(
        appBar: AppBar(
          title: Text(U.s.applicationLogs),
          leading: const IconButton(icon: Icon(Icons.close_rounded), onPressed: UNavigator.back),
          actions: <Widget>[
            IconButton(tooltip: U.s.refresh, icon: const Icon(Icons.refresh_rounded), onPressed: c.loadAppLogs),
            IconButton(tooltip: U.s.clearLogs, icon: const Icon(Icons.delete_sweep_rounded), color: UAdminTheme.red, onPressed: _confirmClearAppLogs),
          ],
        ),
        body: Obx(() {
          if (c.appLogsState.value.isLoading() || c.appLogsState.value.isInitial()) return const Center(child: CircularProgressIndicator());
          if (c.appLogsState.value.isError()) return Center(child: UTextBodyMedium(U.s.errorReadingData, color: Theme.of(context).colorScheme.error));
          if (c.appLogs.isEmpty) return Center(child: UTextBodyMedium(U.s.noData, color: Theme.of(context).disabledColor));
          return ListView.builder(
            itemBuilder: (BuildContext _, int index) {
              final String i = c.appLogs[index];
              Color color = Colors.black;
              if (i.contains("[INFO]")) color = Colors.blue;
              if (i.contains("[ERROR]")) color = Colors.red;
              if (i.contains("[SUCCESS]")) color = Colors.green;
              if (i.contains("[WARNING]")) color = Colors.yellow.shade700;
              return UCard(
                margin: const EdgeInsets.all(16),
                child: SelectableText(
                  i,
                  style: TextStyle(color: color, fontSize: 16),
                  textDirection: TextDirection.ltr,
                ).pAll(16),
              );
            },
            itemCount: c.appLogs.length,
          );
        }),
      ),
    );
  }

  void _confirmClearAppLogs() => UNavigator.dialog(
    AlertDialog(
      title: Text(U.s.clearLogs),
      content: Text(U.s.clearLogsConfirm),
      actions: <Widget>[
        UButton(title: U.s.cancel, type: UButtonType.text, onTap: UNavigator.back),
        UButton(
          title: U.s.clearLogs,
          backgroundColor: UAdminTheme.red,
          onTap: () {
            UNavigator.back();
            c.clearAppLogs();
          },
        ),
      ],
    ),
  );
}

class _ApiLogDetailView extends StatelessWidget {
  const _ApiLogDetailView({required this.item, required this.methodColor, required this.statusColor});

  final UApiLogResponse item;
  final Color methodColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => UColumn(
    children: <Widget>[
      _header(context),
      const Divider(height: 1),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: UColumn(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (item.jsonData.exceptionType != null || item.jsonData.exceptionMessage != null || item.jsonData.stackTrace != null) ...<Widget>[
                _exceptionBlock(context),
              ],
              if (item.jsonData.queryString != null) ...<Widget>[
                _metaItem(U.s.queryString, item.jsonData.queryString!),
              ],
              UTextTitleSmall(U.s.requestBody, fontWeight: FontWeight.w700),
              UJsonViewer(jsonString: item.jsonData.requestBody ?? "-"),
              UTextTitleSmall(U.s.responseBody, fontWeight: FontWeight.w700),
              UJsonViewer(jsonString: item.jsonData.responseBody ?? "-"),
              if (item.jsonData.requestHeaders != null) ...<Widget>[
                UTextTitleSmall(U.s.requestHeaders, fontWeight: FontWeight.w700),
                UJsonViewer(jsonString: item.jsonData.requestHeaders!),
              ],
              if (item.jsonData.responseHeaders != null) ...<Widget>[
                UTextTitleSmall(U.s.responseHeaders, fontWeight: FontWeight.w700),
                UJsonViewer(jsonString: item.jsonData.responseHeaders!),
              ],
              _metaGrid(context),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _header(BuildContext context) => Material(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: URow(
        children: <Widget>[
          UContainer(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: methodColor.withValues(alpha: 0.15),
            radius: 20,
            child: UTextBodySmall(item.jsonData.method, color: methodColor, fontWeight: FontWeight.w700).ltr(),
          ),
          const SizedBox(width: 8),
          UTextBodyMedium(item.path, maxLines: 1, overflow: TextOverflow.ellipsis).ltr().expanded(),
          const SizedBox(width: 8),
          UContainer(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: statusColor.withValues(alpha: 0.15),
            radius: 20,
            child: UTextBodySmall(item.statusCode.toString(), color: statusColor, fontWeight: FontWeight.w700).ltr(),
          ),
          const SizedBox(width: 8),
          const IconButton(icon: Icon(Icons.close_rounded), onPressed: UNavigator.back),
        ],
      ),
    ),
  );

  Widget _metaGrid(BuildContext context) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _metaItem(U.s.time, item.createdAt.toJalaliDateTime()),
      _metaItem(U.s.duration, "${item.durationMs} ms"),
      if (item.jsonData.userName.nullIfEmpty() != null) _metaItem(U.s.username, item.jsonData.userName!),
      if (item.jsonData.userFirstName.nullIfEmpty() != null) _metaItem(U.s.firstName, item.jsonData.userFirstName!),
      if (item.jsonData.userLastName.nullIfEmpty() != null) _metaItem(U.s.lastName, item.jsonData.userLastName!),
      if (item.jsonData.userPhoneNumber.nullIfEmpty() != null) _metaItem(U.s.phoneNumber, item.jsonData.userPhoneNumber!),
      if (item.jsonData.userEmail != null) _metaItem(U.s.userEmail, item.jsonData.userEmail!),
      if (item.userId != null) _metaItem(item.userId!, U.s.userId),
      if (item.jsonData.userRoles != null) _metaItem(U.s.roles, item.jsonData.userRoles!),
      if (item.ipAddress != null) _metaItem("IP", item.ipAddress!),
      if (item.jsonData.host != null) _metaItem("Host", item.jsonData.host!),
      _metaItem(U.s.requestSize, _formatBytes(item.jsonData.requestSizeBytes)),
      _metaItem(U.s.responseSize, _formatBytes(item.jsonData.responseSizeBytes)),
      if (item.jsonData.userAgent != null) SizedBox(width: 280, child: _metaItem("User-Agent", item.jsonData.userAgent!)),
    ],
  );

  Widget _metaItem(String label, String value) => ListTile(
    title: Text(label),
    trailing: value.length <= 50 ? SelectableText(value) : null,
    subtitle: value.length >= 50 ? SelectableText(value) : null,
  ).card(elevation: 0);

  Widget _exceptionBlock(BuildContext context) {
    final Color error = Theme.of(context).colorScheme.error;
    final String? stack = item.jsonData.stackTrace;
    return UContainer(
      width: double.infinity,
      color: error.withValues(alpha: 0.06),
      radius: 14,
      border: Border.all(color: error.withValues(alpha: 0.35)),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: URow(
              children: <Widget>[
                Icon(Icons.error_outline_rounded, color: error, size: 20),
                const SizedBox(width: 8),
                UTextBodyMedium(item.jsonData.exceptionType ?? U.s.exception, color: error, fontWeight: FontWeight.w800).ltr().expanded(),
                IconButton(
                  tooltip: U.s.copyToClipboard,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.copy_rounded, size: 16, color: error),
                  onPressed: () => UClipboard.set(_exceptionAsText(), snackBar: true),
                ),
              ],
            ),
          ),
          if (item.jsonData.exceptionMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: SelectableText(
                item.jsonData.exceptionMessage!,
                style: TextStyle(fontFamily: "monospace", fontSize: 12.5, height: 1.4, color: Theme.of(context).colorScheme.onSurface),
              ).ltr(),
            ),
          if (stack != null && stack.trim().isNotEmpty) _stackTraceTile(context, stack),
        ],
      ),
    );
  }

  Widget _stackTraceTile(BuildContext context, String stack) => Theme(
    data: Theme.of(context).copyWith(dividerColor: UAdminTheme.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(Icons.subject_rounded, size: 18, color: Theme.of(context).disabledColor),
      title: UTextBodyMedium(U.s.stackTrace, fontWeight: FontWeight.w700),
      trailing: IconButton(
        tooltip: U.s.copyToClipboard,
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.copy_rounded, size: 16),
        onPressed: () => UClipboard.set(stack, snackBar: true),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: <Widget>[_codeBlock(context, stack)],
    ),
  );

  Widget _codeBlock(BuildContext context, String text) => UContainer(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
    radius: 10,
    border: Border.all(color: Theme.of(context).dividerColor),
    constraints: const BoxConstraints(maxHeight: 260),
    child: SingleChildScrollView(
      child: SelectableText(
        text,
        style: TextStyle(fontFamily: "monospace", fontSize: 11.5, height: 1.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ).ltr(),
    ),
  );

  String _exceptionAsText() => <String?>[item.jsonData.exceptionType, item.jsonData.exceptionMessage, item.jsonData.stackTrace].where((String? s) => s != null && s.trim().isNotEmpty).join("\n\n");

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
}
