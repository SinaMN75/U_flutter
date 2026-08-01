import "package:flutter/material.dart";
import "package:syncfusion_flutter_gauges/gauges.dart";

class UGauge extends StatelessWidget {
  const UGauge({
    required this.value,
    super.key,
    this.min = 0,
    this.max = 100,
    this.size = 200,
    this.ranges,
    this.annotations,
    this.showTicks = true,
    this.showLabels = true,
    this.axisColor,
    this.axisThickness,
    this.needleColor,
    this.needleWidth = 1,
    this.needleKnobRadius = 0.08,
    this.majorTickColor,
    this.majorTickLength,
    this.minorTickColor,
    this.minorTickLength,
    this.labelFontSize,
    this.labelColor,
  });

  final double min;
  final double max;
  final double value;
  final double size;
  final List<UGaugeRange>? ranges;
  final List<UGaugeAnnotation>? annotations;
  final bool showTicks;
  final bool showLabels;
  final Color? axisColor;
  final double? axisThickness;
  final Color? needleColor;
  final double needleWidth;
  final double needleKnobRadius;
  final Color? majorTickColor;
  final double? majorTickLength;
  final Color? minorTickColor;
  final double? minorTickLength;
  final double? labelFontSize;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: min,
          maximum: max,
          showTicks: showTicks,
          showLabels: showLabels,
          axisLineStyle: AxisLineStyle(
            thickness: axisThickness ?? 10,
            color: axisColor,
          ),
          majorTickStyle: MajorTickStyle(
            length: majorTickLength ?? 10,
            color: majorTickColor,
          ),
          minorTickStyle: MinorTickStyle(
            length: minorTickLength ?? 5,
            color: minorTickColor,
          ),
          axisLabelStyle: GaugeTextStyle(
            fontSize: labelFontSize ?? 12,
            color: labelColor,
          ),
          ranges: ranges?.map((UGaugeRange r) => r._toSfRange()).toList(),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: value,
              needleColor: needleColor,
              needleStartWidth: needleWidth,
              knobStyle: KnobStyle(knobRadius: needleKnobRadius),
            ),
          ],
          annotations: annotations?.map((UGaugeAnnotation a) => a._toSfAnnotation()).toList(),
        ),
      ],
    ),
  );
}

class UGaugeRange {
  UGaugeRange({
    required this.start,
    required this.end,
    required this.color,
    this.startWidth,
    this.endWidth,
  });

  final double start;
  final double end;
  final Color color;
  final double? startWidth;
  final double? endWidth;

  GaugeRange _toSfRange() => GaugeRange(
    startValue: start,
    endValue: end,
    color: color,
    startWidth: startWidth ?? 10,
    endWidth: endWidth ?? 10,
  );
}

class UGaugeAnnotation {
  UGaugeAnnotation({
    required this.widget,
    required this.angle,
    required this.position,
  });

  final Widget widget;
  final double angle;
  final double position;

  GaugeAnnotation _toSfAnnotation() => GaugeAnnotation(
    widget: widget,
    angle: angle,
    positionFactor: position,
  );
}
