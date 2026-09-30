import "package:u/utilities.dart";

import "../../demo/demo.dart";

/// Charts, gauges, pagination, side menu, tab bar, popup menu, carousel.
class ChartsNavigationPage extends StatefulWidget {
  const ChartsNavigationPage({super.key});

  @override
  State<ChartsNavigationPage> createState() => _ChartsNavigationPageState();
}

class _ChartsNavigationPageState extends State<ChartsNavigationPage> {
  static const List<String> _months = <String>["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
  static const List<UChartSeries> _series = <UChartSeries>[
    UChartSeries(name: "Sales", values: <double>[3, 5, 4, 8, 6, 9]),
    UChartSeries(name: "Costs", values: <double>[2, 3, 3, 4, 5, 4]),
  ];
  static const List<USlice> _slices = <USlice>[USlice(label: "Food", value: 40), USlice(label: "Rent", value: 35), USlice(label: "Fun", value: 15), USlice(label: "Other", value: 10)];
  static const List<UCandle> _candles = <UCandle>[
    UCandle(open: 10, high: 12, low: 9, close: 11, label: "Mon"),
    UCandle(open: 11, high: 13, low: 10, close: 10.5, label: "Tue"),
    UCandle(open: 10.5, high: 12, low: 10, close: 11.8, label: "Wed"),
    UCandle(open: 11.8, high: 14, low: 11, close: 13.5, label: "Thu"),
  ];
  static final List<UPointSeries> _points = <UPointSeries>[
    UPointSeries(
      name: "A",
      points: List<UChartPoint>.generate(12, (int i) => UChartPoint(x: i.toDouble(), y: (i * 7 % 10).toDouble(), size: (i % 4 + 1).toDouble())),
    ),
  ];

  final USideMenuController _menu = USideMenuController(selectedId: "home");
  final UCarouselController _carousel = UCarouselController();
  int _page = 1;
  int _tab = 0;
  List<UTab> _tabs = const <UTab>[UTab(id: "a", title: "Orders", icon: Icons.receipt), UTab(id: "b", title: "Customers", icon: Icons.people), UTab(id: "c", title: "Reports", icon: Icons.bar_chart)];

  Widget _chart(Widget chart) => SizedBox(height: 240, child: chart);

  @override
  Widget build(BuildContext context) => DemoPage(
    title: "Charts & navigation",
    children: <Widget>[
      DemoGroup("Line & area", <Widget>[
        Demo(
          "ULineChart(series: …, categories: …)",
          child: _chart(const ULineChart(series: _series, categories: _months, title: "Sales vs costs")),
        ),
        Demo(
          "USplineChart(…)",
          child: _chart(const USplineChart(series: _series, categories: _months)),
        ),
        Demo(
          "UStepLineChart(…)",
          child: _chart(const UStepLineChart(series: _series, categories: _months)),
        ),
        Demo(
          "UAreaChart(…)",
          child: _chart(const UAreaChart(series: _series, categories: _months)),
        ),
        Demo(
          "UStackedAreaChart(…)",
          child: _chart(const UStackedAreaChart(series: _series, categories: _months)),
        ),
        Demo("USparkline(values: …)", child: const USparkline(values: <double>[3, 5, 4, 8, 6, 9, 7])),
      ]),
      DemoGroup("Bars", <Widget>[
        Demo(
          "UBarChart(…)",
          child: _chart(const UBarChart(series: _series, categories: _months)),
        ),
        Demo(
          "UGroupedBarChart(…)",
          child: _chart(const UGroupedBarChart(series: _series, categories: _months)),
        ),
        Demo(
          "UHorizontalBarChart(…)",
          child: _chart(const UHorizontalBarChart(series: _series, categories: _months)),
        ),
        Demo(
          "UStackedBarChart(…)",
          child: _chart(const UStackedBarChart(series: _series, categories: _months)),
        ),
        Demo(
          "UStacked100BarChart(…)",
          child: _chart(const UStacked100BarChart(series: _series, categories: _months)),
        ),
        Demo("UHistogramChart(data: …, bins: 6)", child: _chart(UHistogramChart(data: List<double>.generate(80, (int i) => (i * 37 % 100).toDouble()), bins: 6))),
        Demo(
          "UWaterfallChart(items: …)",
          child: _chart(
            const UWaterfallChart(
              items: <UWaterfallItem>[
                UWaterfallItem(label: "Start", value: 100),
                UWaterfallItem(label: "Sales", value: 40),
                UWaterfallItem(label: "Tax", value: -25),
                UWaterfallItem(label: "End", value: 115, isTotal: true),
              ],
            ),
          ),
        ),
      ]),
      DemoGroup("Parts of a whole", <Widget>[
        Demo("UPieChart(slices: …)", child: _chart(const UPieChart(slices: _slices))),
        Demo(
          'UDonutChart(slices: …, centerText: "100")',
          child: _chart(const UDonutChart(slices: _slices, centerText: "100%")),
        ),
        Demo(
          "UFunnelChart(slices: …)",
          child: _chart(
            const UFunnelChart(
              slices: <USlice>[
                USlice(label: "Visits", value: 1000),
                USlice(label: "Cart", value: 400),
                USlice(label: "Paid", value: 120),
              ],
            ),
          ),
        ),
        Demo("UTreemapChart(slices: …)", child: _chart(const UTreemapChart(slices: _slices))),
      ]),
      DemoGroup("Points, radar, finance, heatmap", <Widget>[
        Demo("UScatterChart(data: …)", child: _chart(UScatterChart(data: _points))),
        Demo("UBubbleChart(data: …)", child: _chart(UBubbleChart(data: _points))),
        Demo(
          "URadarChart(axes: …, series: …)",
          child: _chart(
            const URadarChart(
              axes: <String>["Speed", "Power", "Range", "Price", "Comfort"],
              series: <UChartSeries>[
                UChartSeries(name: "A", values: <double>[4, 3, 5, 2, 4]),
                UChartSeries(name: "B", values: <double>[3, 5, 3, 4, 2]),
              ],
            ),
          ),
        ),
        Demo("UCandlestickChart(candles: …)", child: _chart(const UCandlestickChart(candles: _candles))),
        Demo("UOhlcChart(candles: …)", child: _chart(const UOhlcChart(candles: _candles))),
        Demo(
          "UHeatmapChart(matrix: …)",
          child: _chart(
            const UHeatmapChart(
              matrix: <List<double>>[
                <double>[1, 3, 5],
                <double>[2, 8, 4],
                <double>[6, 1, 9],
              ],
              rowLabels: <String>["A", "B", "C"],
              colLabels: <String>["x", "y", "z"],
            ),
          ),
        ),
        Demo(
          "UChartAnimator(builder: …, duration: …, curve: …)",
          child: UChartAnimator(
            duration: 1.seconds,
            curve: Curves.easeOut,
            builder: (double t) => LinearProgressIndicator(value: t),
          ),
        ),
      ]),
      DemoGroup("Gauges", <Widget>[
        Demo(
          "URadialGauge / USpeedometerGauge / USemiCircleGauge / UArcGauge",
          child: UWrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              URadialGauge(value: 72, size: 150, bands: <UGaugeBand>[UGaugeBand(start: 80, end: 100, color: Colors.red)]),
              const USpeedometerGauge(value: 120, max: 200, size: 150),
              const USemiCircleGauge(value: 40, size: 150),
              const UArcGauge(value: 64, size: 150),
            ],
          ),
        ),
        Demo(
          "UProgressRingGauge / UCompassGauge / USegmentedGauge",
          child: const UWrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UProgressRingGauge(value: 80, size: 120, label: "Done"),
              UCompassGauge(value: 45, size: 140),
              USegmentedGauge(value: 70, segments: 12, size: 140),
            ],
          ),
        ),
        const Demo("ULinearGauge / UBulletGauge", child: UColumn(spacing: 8, children: <Widget>[ULinearGauge(value: 30), UBulletGauge(value: 70, target: 85)])),
        const Demo(
          "UVerticalLinearGauge / UBatteryGauge / UThermometerGauge",
          child: URow(
            spacing: 8,
            children: <Widget>[
              SizedBox(height: 240, child: UVerticalLinearGauge(value: 55)),
              UBatteryGauge(value: 18, width: 120, height: 60),
              UThermometerGauge(value: 37, min: 30, max: 45, height: 220),
            ],
          ),
        ),
      ]),
      DemoGroup("Pagination & carousel", <Widget>[
        Demo(
          "UNumberPagination(currentPage: …, totalPages: 12, …)",
          child: UNumberPagination(currentPage: _page, totalPages: 12, onPageChanged: (int p) => setState(() => _page = p)),
        ),
        Demo(
          "USlider(images: …)",
          child: USlider(height: 160, images: List<Widget>.generate(3, (int i) => UImage("https://picsum.photos/seed/u$i/600/300", fit: BoxFit.cover))),
        ),
        Demo(
          "UCarousel<T>(items: …, itemBuilder: …, controller: …)",
          child: UColumn(
            spacing: 8,
            children: <Widget>[
              UCarousel<int>(
                height: 120,
                items: const <int>[1, 2, 3, 4],
                controller: _carousel,
                viewportFraction: 0.8,
                itemBuilder: (BuildContext c, int item, int i) => UContainer(
                  radius: 16,
                  color: Colors.primaries[item * 3],
                  child: Center(child: UTextTitleLarge("Card $item", color: Colors.white)),
                ),
              ),
              UWrap(
                spacing: 8,
                children: <Widget>[
                  UButton(title: "previous", onTap: _carousel.previous),
                  UButton(title: "next", onTap: _carousel.next),
                  UButton(title: "go to 3", onTap: () => _carousel.animateToPage(2)),
                  UButton(title: "auto play", onTap: _carousel.toggleAutoPlay),
                  UButton(title: "start", onTap: _carousel.startAutoPlay),
                  UButton(title: "stop", onTap: _carousel.stopAutoPlay),
                  UButton(
                    title: "state",
                    onTap: () => UToast.toast(message: "page ${_carousel.currentPage}, playing ${_carousel.isAutoPlaying}"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
      DemoGroup("Menus & tabs", <Widget>[
        Demo(
          "UPopupMenu(items: [UPopupMenuItem(…)])",
          child: UPopupMenu(
            items: <UPopupMenuItem>[
              UPopupMenuItem(
                label: "Edit",
                icon: Icons.edit,
                onTap: () => UToast.toast(message: "edit"),
              ),
              UPopupMenuItem(
                label: "Delete",
                icon: Icons.delete,
                destructive: true,
                onTap: () => UToast.toast(message: "delete"),
              ),
            ],
          ),
        ),
        Demo(
          "UTabBar(tabs: …, selectedIndex: …, onSelect: …, onClose: …)",
          child: UTabBar(
            tabs: _tabs,
            selectedIndex: _tab,
            onSelect: (int i) => setState(() => _tab = i),
            onClose: (int i) => setState(() {
              _tabs = <UTab>[..._tabs]..removeAt(i);
              _tab = _tab.clamp(0, max(0, _tabs.length - 1));
            }),
            onReorder: (int from, int to) => setState(() {
              final List<UTab> list = <UTab>[..._tabs];
              final UTab moved = list.removeAt(from);
              list.insert(to > from ? to - 1 : to, moved);
              _tabs = list;
            }),
          ),
        ),
        Demo(
          "USideMenu(controller: …, items: …)",
          child: SizedBox(
            height: 360,
            child: Row(
              children: <Widget>[
                USideMenu(
                  controller: _menu,
                  enableSearch: true,
                  enablePinning: true,
                  items: <UMenuEntry>[
                    const UMenuHeader("Main"),
                    const UMenuItem(id: "home", title: "Home", icon: Icons.home),
                    const UMenuItem(id: "orders", title: "Orders", icon: Icons.receipt, badge: "3"),
                    const UMenuGroup(
                      id: "settings",
                      title: "Settings",
                      icon: Icons.settings,
                      children: <UMenuItem>[
                        UMenuItem(id: "profile", title: "Profile", icon: Icons.person),
                        UMenuItem(id: "security", title: "Security", icon: Icons.lock),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _menu,
                    builder: (BuildContext c, Widget? _) => Center(child: Text("selected: ${_menu.selectedId}\nmode: ${_menu.resolvedMode.name}\ncollapsed: ${_menu.collapsed}")),
                  ),
                ),
              ],
            ),
          ),
        ),
        Demo(
          "USideMenuController actions",
          child: UWrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              UButton(title: "select orders", onTap: () => _menu.select("orders")),
              UButton(title: "selectedId = home", onTap: () => _menu.selectedId = "home"),
              UButton(title: "toggleCollapsed", onTap: _menu.toggleCollapsed),
              UButton(title: "collapsed = false", onTap: () => _menu.collapsed = false),
              UButton(title: "cycleMode", onTap: _menu.cycleMode),
              UButton(title: "mode = rail", onTap: () => _menu.mode = USideMenuMode.rail),
              UButton(title: "mode = auto", onTap: () => _menu.mode = null),
              UButton(title: "search 'se'", onTap: () => _menu.search = "se"),
              UButton(title: "toggleGroup", onTap: () => _menu.toggleGroup("settings")),
              UButton(title: "setGroupExpanded", onTap: () => _menu.setGroupExpanded("settings", true)),
              UButton(title: "togglePin orders", onTap: () => _menu.togglePin("orders")),
              UButton(
                title: "info",
                onTap: () => UToast.toast(
                  message:
                      "drawer ${_menu.isDrawerMode}/${_menu.isDrawerOpen} group ${_menu.isGroupExpanded("settings")} pinned ${_menu.isPinned("orders")} ${_menu.pinnedIds} search '${_menu.search}'",
                ),
              ),
              UButton(
                title: "open/close/toggle drawer",
                onTap: () {
                  _menu.openDrawer();
                  _menu.closeDrawer();
                  _menu.toggleDrawer();
                },
              ),
              UButton(
                title: "attach/detach drawer",
                onTap: () {
                  _menu.attachDrawer(() {}, () {});
                  _menu.detachDrawer();
                },
              ),
            ],
          ),
        ),
      ]),
    ],
  );
}
