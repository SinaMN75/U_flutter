import "package:u/utilities.dart";

import "../widgets/demo_section.dart";
import "../widgets/gallery_page.dart";

class _Point {
  const _Point(this.x, this.y);
  final String x;
  final double y;
}

/// Demonstrates the data-visualisation widgets: charts, gauge, JSON viewer,
/// pagination and a map.
class DataVizPage extends StatefulWidget {
  const DataVizPage({super.key});

  @override
  State<DataVizPage> createState() => _DataVizPageState();
}

class _DataVizPageState extends State<DataVizPage> {
  int _page = 1;
  final MapController _mapController = MapController();

  static const List<_Point> _data = <_Point>[
    _Point("Jan", 12), _Point("Feb", 18), _Point("Mar", 9),
    _Point("Apr", 22), _Point("May", 16),
  ];

  @override
  Widget build(BuildContext context) => GalleryPage(
    title: "Data viz",
    intro: "Syncfusion-backed charts and gauges, a collapsible JSON tree, number pagination and a "
        "flutter_map view — all pre-themed.",
    sections: <Widget>[
      DemoSection(
        title: "UCartesianChart",
        description: "Pass any Syncfusion CartesianSeries; titles and legend are handled for you.",
        code: r'''
UCartesianChart(
  title: "Sales",
  primaryXAxisTitle: "Month",
  primaryYAxisTitle: "Units",
  series: <CartesianSeries<dynamic, dynamic>>[
    ColumnSeries<Point, String>(dataSource: data, xValueMapper: (p, _) => p.x, yValueMapper: (p, _) => p.y),
  ],
);''',
        child: SizedBox(
          height: 260,
          child: UCartesianChart(
            title: "Sales",
            primaryXAxisTitle: "Month",
            primaryYAxisTitle: "Units",
            series: <CartesianSeries<dynamic, dynamic>>[
              ColumnSeries<_Point, String>(
                dataSource: _data,
                xValueMapper: (_Point p, _) => p.x,
                yValueMapper: (_Point p, _) => p.y,
              ),
            ],
          ),
        ),
      ),
      DemoSection(
        title: "UGauge",
        description: "A radial gauge with optional colored ranges.",
        code: r'''UGauge(value: 72, ranges: <UGaugeRange>[UGaugeRange(start: 0, end: 60, color: Colors.green)]);''',
        child: SizedBox(
          height: 200,
          child: UGauge(
            value: 72,
            size: 180,
            ranges: <UGaugeRange>[
              UGaugeRange(start: 0, end: 50, color: Theme.of(context).colorScheme.tertiary),
              UGaugeRange(start: 50, end: 80, color: Theme.of(context).colorScheme.primary),
              UGaugeRange(start: 80, end: 100, color: Theme.of(context).colorScheme.error),
            ],
          ),
        ),
      ),
      DemoSection(
        title: "UJsonViewer",
        description: "Pretty-print and explore a JSON string as a collapsible tree.",
        code: r'''UJsonViewer(jsonString: '{"name":"u","version":"0.1.0"}');''',
        child: const UJsonViewer(
          jsonString: '{"name":"u","version":"0.1.0","platforms":["android","ios","web"],"nested":{"ok":true}}',
        ),
      ),
      DemoSection(
        title: "UNumberPagination",
        description: "A page selector with prev/next and a sliding window of page numbers.",
        code: r'''
UNumberPagination(currentPage: page, totalPages: 12, onPageChanged: (int p) => setState(() => page = p));''',
        child: UColumn(
          spacing: 8,
          children: <Widget>[
            UNumberPagination(
              currentPage: _page,
              totalPages: 12,
              onPageChanged: (int p) => setState(() => _page = p),
            ),
            DemoLabel("Page $_page of 12"),
          ],
        ),
      ),
      DemoSection(
        title: "UMap",
        description: "A flutter_map view; pass a MapController plus markers/polylines/polygons.",
        code: r'''UMap(controller: MapController(), center: LatLng(35.6892, 51.3890), zoom: 11);''',
        child: SizedBox(
          height: 220,
          child: UMap(controller: _mapController, center: const LatLng(35.6892, 51.3890), zoom: 11),
        ),
      ),
      DemoSection(
        title: "UChat",
        description: "A full chat UI (bubbles, composer, avatars). Feed it your message list and the "
            "current user id — see UChat for the message model and builder hooks.",
        code: r'''UChat(messages: messages, outgoingUserId: currentUserId, onMessageSent: send);''',
        child: const UTextBodySmall("Reference — requires a message list and user id from your app."),
      ),
    ],
  );
}
