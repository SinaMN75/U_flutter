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
        IconButton(tooltip: U.s.filter, icon: const Icon(Icons.tune_rounded), onPressed: _showFilterDialog),
        IconButton(tooltip: U.s.refresh, icon: const Icon(Icons.refresh_rounded), onPressed: c.refreshAll),
      ],
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(_isWide ? 24 : 14),
      child: UColumn(
        spacing: 0,
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
        spacing: 0,
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
            ).pSymmetric(vertical: 12)
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
    spacing: 0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UTextBodySmall(title, color: UAdminTheme.white.withValues(alpha: 0.75)),
      const SizedBox(height: 4),
      UTextHeadlineSmall(value, color: UAdminTheme.white, fontWeight: FontWeight.w800),
    ],
  );

  Widget _percentileBadge(String label, double ms) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: UAdminTheme.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
    child: UTextBodySmall("$label: ${ms.toStringAsFixed(0)} ms", color: UAdminTheme.white, fontWeight: FontWeight.w600).ltr(),
  );

  Widget _osMetricsSection() {
    final UOsMetricsResponse? m = c.osMetrics.value;
    return UColumn(
      padding: const EdgeInsets.all(20),
      radius: 20,
      color: Theme.of(context).cardTheme.color,
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        URow(
          spacing: 0,
          children: <Widget>[
            const Icon(Icons.dns_rounded, size: 20),
            const SizedBox(width: 8),
            UTextTitleSmall(U.s.osMetrics, fontWeight: FontWeight.w700).expanded(),
            if (m != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: UAdminTheme.green.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: URow(
                  spacing: 0,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: UAdminTheme.green, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    UTextBodySmall(m.generatedAt.formatDate("HH:mm:ss"), color: UAdminTheme.green, fontWeight: FontWeight.w600).ltr(),
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
            spacing: 0,
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
    spacing: 0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      URow(
        spacing: 0,
        children: <Widget>[
          UTextBodyMedium(label, fontWeight: FontWeight.w600).expanded(),
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
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _timelineChart().expanded(flex: 2),
              const SizedBox(width: 16),
              _distributionChart().expanded(),
            ],
          )
        : UColumn(
            spacing: 0,
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
      spacing: 0,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _bucketButton("minute", U.s.minute),
        _bucketButton("hour", U.s.hour),
        _bucketButton("day", U.s.day),
      ],
    ),
    child: (c.stats.value?.timeline.isEmpty ?? true)
        ? Center(child: UTextBodyMedium(U.s.noData))
        : SfCartesianChart(
            primaryXAxis: const DateTimeAxis(),
            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries<UApiLogBucketResponse, DateTime>>[
              SplineAreaSeries<UApiLogBucketResponse, DateTime>(
                name: U.s.count,
                dataSource: c.stats.value!.timeline,
                xValueMapper: (UApiLogBucketResponse b, _) => b.time,
                yValueMapper: (UApiLogBucketResponse b, _) => b.count,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                borderColor: Theme.of(context).colorScheme.primary,
              ),
              LineSeries<UApiLogBucketResponse, DateTime>(
                name: U.s.errors,
                dataSource: c.stats.value!.timeline,
                xValueMapper: (UApiLogBucketResponse b, _) => b.time,
                yValueMapper: (UApiLogBucketResponse b, _) => b.errorCount,
                color: UAdminTheme.red,
              ),
            ],
          ),
  );

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
        : SfCircularChart(
            legend: const Legend(isVisible: true, position: LegendPosition.bottom),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CircularSeries<_StatusSlice, String>>[
              DoughnutSeries<_StatusSlice, String>(
                dataSource: <_StatusSlice>[
                  _StatusSlice(U.s.success, c.stats.value!.successCount, UAdminTheme.green),
                  _StatusSlice(U.s.errors, c.stats.value!.errorCount, UAdminTheme.red),
                ],
                xValueMapper: (_StatusSlice s, _) => s.label,
                yValueMapper: (_StatusSlice s, _) => s.count,
                pointColorMapper: (_StatusSlice s, _) => s.color,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
          ),
  );

  Widget _chartCard({required String title, required Widget child, Widget? trailing}) => UColumn(
    height: 320,
    padding: const EdgeInsets.all(18),
    radius: 12,
    color: Theme.of(context).cardTheme.color,
    spacing: 0,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      URow(
        spacing: 0,
        children: <Widget>[
          UTextTitleSmall(title, fontWeight: FontWeight.w700).expanded(),
          if (trailing != null) trailing,
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
            spacing: 0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _endpointBarChart(title: U.s.slowestPaths, items: s.slowestEndpoints, color: UAdminTheme.orange).expanded(),
              const SizedBox(width: 16),
              _endpointBarChart(title: U.s.mostFailingPaths, items: s.failingEndpoints, color: UAdminTheme.red).expanded(),
            ],
          )
        : UColumn(
            spacing: 0,
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
        : SfCartesianChart(
            primaryXAxis: const CategoryAxis(),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries<UApiLogEndpointResponse, String>>[
              BarSeries<UApiLogEndpointResponse, String>(
                dataSource: items,
                xValueMapper: (UApiLogEndpointResponse e, _) => e.path.subStringIfExist(0, 32),
                yValueMapper: (UApiLogEndpointResponse e, _) => e.averageDurationMs,
                color: color,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
              ),
            ],
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
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          URow(
            spacing: 0,
            children: <Widget>[
              const Icon(Icons.local_fire_department_rounded, size: 20, color: UAdminTheme.orange),
              const SizedBox(width: 8),
              UTextTitleSmall(U.s.slowestRequests, fontWeight: FontWeight.w700).expanded(),
            ],
          ),
          const Divider(height: 18),
          if (items.isEmpty)
            UTextBodySmall(U.s.noData).pSymmetric(vertical: 12)
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
    subtitle: UTextBodySmall(i.createdAt.formatDate("yyyy-MM-dd HH:mm:ss")).ltr(),
    trailing: URow(
      spacing: 0,
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
    if (!c.state.value.isLoaded())
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );

    final List<UApiLogResponse> data = c.list;
    final bool desktop = MediaQuery.sizeOf(context).width >= 800;
    final Widget list = desktop
        ? UListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            header: URow(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(8),
              children: <Widget>[
                UTextBodyLarge(U.s.time, color: UAdminTheme.white, textAlign: .center).expanded(),
                UTextBodyLarge(U.s.method, color: UAdminTheme.white, textAlign: .center).expanded(),
                UTextBodyLarge(U.s.path, color: UAdminTheme.white, textAlign: .center).expanded(flex: 3),
                UTextBodyLarge(U.s.status, color: UAdminTheme.white, textAlign: .center).expanded(),
                UTextBodyLarge(U.s.duration, color: UAdminTheme.white, textAlign: .center).expanded(),
                UTextBodyLarge(U.s.userSlashIp, color: UAdminTheme.white, textAlign: .center).expanded(flex: 2),
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
      spacing: 0,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: URow(
            spacing: 0,
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
        spacing: 0,
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

  Widget _itemDesktop({required UApiLogResponse i, required int index}) => InkWell(
    onTap: () => _openDetail(i),
    child: URow(
      color: index.isOdd ? UAdminTheme.transparent : Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
      children: <Widget>[
        UTextBodySmall(i.createdAt.formatDate("yyyy-MM-dd HH:mm:ss"), textAlign: .center).ltr().expanded(),
        _methodChip(i.jsonData.method).alignAtCenter().expanded(),
        _pathCell(i).expanded(flex: 3),
        _statusChip(i.statusCode).alignAtCenter().expanded(),
        UTextBodyMedium("${i.durationMs} ms", textAlign: .center, color: i.durationMs > 1000 ? UAdminTheme.orange : null).expanded(),
        UTextBodySmall(i.ipAddress ?? "-", textAlign: .center, overflow: TextOverflow.ellipsis).ltr().expanded(flex: 2),
      ],
    ),
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
          spacing: 0,
          children: <Widget>[
            _methodChip(i.jsonData.method),
            const SizedBox(width: 8),
            UTextBodyMedium(i.path, maxLines: 1, overflow: TextOverflow.ellipsis).ltr().expanded(),
            if (_hasException(i)) _exceptionBadge(),
          ],
        ),
        subtitle: UTextBodySmall("${i.createdAt.formatDate("yyyy-MM-dd HH:mm:ss")} • ${i.durationMs} ms${i.ipAddress != null ? " • ${i.ipAddress}" : ""}").ltr(),
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

  Widget _pathCell(UApiLogResponse i) => URow(
    spacing: 0,
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      if (_hasException(i)) _exceptionBadge(),
      Flexible(
        child: UTextBodyMedium(i.path, textAlign: .center, maxLines: 2, overflow: TextOverflow.ellipsis).ltr(),
      ),
    ],
  );

  Widget _methodChip(String method) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _methodColor(method).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
    child: UTextBodySmall(method, color: _methodColor(method), fontWeight: FontWeight.w700).ltr(),
  );

  Widget _statusChip(int statusCode) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _statusColor(statusCode).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
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
      title: Text(U.s.filterLogs),
      content: SizedBox(
        width: context.dialogWidth(),
        child: SingleChildScrollView(
          child: UColumn(
            spacing: 0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextField(controller: c.pathContainsCtrl, labelText: U.s.pathContains).pSymmetric(vertical: 6),
              URow(
                spacing: 0,
                children: <Widget>[
                  UTextField(controller: c.minDurationCtrl, labelText: U.s.minDurationMs, keyboardType: TextInputType.number).expanded(),
                  const SizedBox(width: 8),
                  UTextField(controller: c.maxDurationCtrl, labelText: U.s.maxDurationMs, keyboardType: TextInputType.number).expanded(),
                ],
              ).pSymmetric(vertical: 6),
              UTextField(controller: c.statusCodeCtrl, labelText: U.s.exactStatusCode, keyboardType: TextInputType.number).pSymmetric(vertical: 6),
              UTextField(controller: c.userIdCtrl, labelText: U.s.userId).pSymmetric(vertical: 6),
              UTextField(controller: c.ipAddressCtrl, labelText: U.s.ipAddress).pSymmetric(vertical: 6),
              UTextField(controller: c.traceIdCtrl, labelText: U.s.traceId).pSymmetric(vertical: 6),
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
}

class _StatusSlice {
  _StatusSlice(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _ApiLogDetailView extends StatelessWidget {
  const _ApiLogDetailView({required this.item, required this.methodColor, required this.statusColor});

  final UApiLogResponse item;
  final Color methodColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) => UColumn(
    spacing: 0,
    children: <Widget>[
      _header(context),
      const Divider(height: 1),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (item.jsonData.exceptionType != null || item.jsonData.exceptionMessage != null || item.jsonData.stackTrace != null) ...<Widget>[
                _exceptionBlock(context),
              ],
              if (item.jsonData.queryString != null) ...<Widget>[
                _metaItem(context, U.s.queryString, item.jsonData.queryString!),
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
        spacing: 0,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: methodColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: UTextBodySmall(item.jsonData.method, color: methodColor, fontWeight: FontWeight.w700).ltr(),
          ),
          const SizedBox(width: 8),
          UTextBodyMedium(item.path, maxLines: 1, overflow: TextOverflow.ellipsis).ltr().expanded(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: UTextBodySmall(item.statusCode.toString(), color: statusColor, fontWeight: FontWeight.w700).ltr(),
          ),
          const SizedBox(width: 8),
          const IconButton(icon: Icon(Icons.close_rounded), onPressed: UNavigator.back),
        ],
      ),
    ),
  );

  Widget _metaGrid(BuildContext context) => UColumn(
    spacing: 0,
    children: <Widget>[
      _metaItem(context, U.s.time, item.createdAt.formatDate("yyyy-MM-dd HH:mm:ss")),
      _metaItem(context, U.s.duration, "${item.durationMs} ms"),
      if (item.jsonData.userName != null) _metaItem(context, U.s.userName, item.jsonData.userName!),
      if (item.jsonData.userEmail != null) _metaItem(context, U.s.userEmail, item.jsonData.userEmail!),
      if (item.userId != null) _metaItem(context, item.userId!, U.s.userId),
      if (item.jsonData.userRoles != null) _metaItem(context, U.s.roles, item.jsonData.userRoles!),
      if (item.ipAddress != null) _metaItem(context, "IP", item.ipAddress!),
      if (item.jsonData.host != null) _metaItem(context, "Host", item.jsonData.host!),
      _metaItem(context, U.s.requestSize, _formatBytes(item.jsonData.requestSizeBytes)),
      _metaItem(context, U.s.responseSize, _formatBytes(item.jsonData.responseSizeBytes)),
      if (item.jsonData.userAgent != null) SizedBox(width: 280, child: _metaItem(context, "User-Agent", item.jsonData.userAgent!)),
    ],
  );

  Widget _metaItem(BuildContext context, String label, String value) => ListTile(
    title: Text(label),
    trailing: value.length <= 50 ? SelectableText(value) : null,
    subtitle: value.length >= 50 ? SelectableText(value) : null,
  ).card(elevation: 0);

  Widget _exceptionBlock(BuildContext context) {
    final Color error = Theme.of(context).colorScheme.error;
    final String? stack = item.jsonData.stackTrace;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: error.withValues(alpha: 0.35)),
      ),
      child: UColumn(
        spacing: 0,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: URow(
              spacing: 0,
              children: <Widget>[
                Icon(Icons.error_outline_rounded, color: error, size: 20),
                const SizedBox(width: 8),
                UTextBodyMedium(item.jsonData.exceptionType ?? U.s.exception, color: error, fontWeight: FontWeight.w800).ltr().expanded(),
                IconButton(
                  tooltip: U.s.copyToClipboard,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.copy_rounded, size: 16, color: error),
                  onPressed: () => _copy(_exceptionAsText()),
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
        onPressed: () => _copy(stack),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: <Widget>[_codeBlock(context, stack)],
    ),
  );

  Widget _codeBlock(BuildContext context, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    constraints: const BoxConstraints(maxHeight: 260),
    child: SingleChildScrollView(
      child: SelectableText(
        text,
        style: TextStyle(fontFamily: "monospace", fontSize: 11.5, height: 1.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ).ltr(),
    ),
  );

  String _exceptionAsText() => <String?>[item.jsonData.exceptionType, item.jsonData.exceptionMessage, item.jsonData.stackTrace]
      .where((String? s) => s != null && s.trim().isNotEmpty)
      .join(
        "\n\n",
      );

  void _copy(String value) {
    UClipboard.set(value);
    UToast.snackBar(message: U.s.copiedToClipboard);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }
}
