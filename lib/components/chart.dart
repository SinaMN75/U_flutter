import "package:intl/intl.dart" as intl;
import "package:u/utilities.dart";

class UCartesianChart extends StatefulWidget {
  const UCartesianChart({
    required this.series,
    required this.primaryXAxisTitle,
    required this.primaryYAxisTitle,
    required this.title,
    this.numberFormat,
    super.key,
  });

  final String title;
  final String primaryXAxisTitle;
  final String primaryYAxisTitle;
  final intl.NumberFormat? numberFormat;
  final List<CartesianSeries<dynamic, dynamic>> series;

  @override
  State<UCartesianChart> createState() => _UCartesianChartState();
}

class _UCartesianChartState extends State<UCartesianChart> {
  @override
  Widget build(BuildContext context) => SfCartesianChart(
    title: ChartTitle(text: widget.title),
    legend: const Legend(isVisible: true),
    tooltipBehavior: TooltipBehavior(enable: true),
    primaryXAxis: CategoryAxis(title: AxisTitle(text: widget.primaryXAxisTitle)),
    primaryYAxis: NumericAxis(
      title: AxisTitle(text: widget.primaryYAxisTitle),
      numberFormat: widget.numberFormat,
    ),
    series: widget.series,
  );
}
