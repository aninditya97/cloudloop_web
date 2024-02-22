import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RangeChartSection extends StatelessWidget {
  const RangeChartSection({Key? key, required this.data}) : super(key: key);

  final GlucoseReportData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.appPadding,
        vertical: Dimens.dp24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           HeadingText2(text: context.l10n.timeInRange),
          _PieChart(data: data),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({Key? key, required this.data}) : super(key: key);
  final GlucoseReportData data;

  @override
  Widget build(BuildContext context) {
    final _glucoseReportMetaList = <GlucoseReportMetaLevel?>[];
    if (data.meta != null) {
      _glucoseReportMetaList
        ..add(data.veryLowLevel)
        ..add(data.lowLevel)
        ..add(data.normalLevel)
        ..add(data.highLevel)
        ..add(data.veryHeightLevel);
    }
    return SfCircularChart(
      palette: const [
        Color(0xFFBE123C),
        Color(0xFFF43F5E),
        Color(0xff73D13D),
        Color(0xffFDE68A),
        Color(0xffFBBF24),
      ],
      tooltipBehavior:
          TooltipBehavior(enable: true, format: 'point.x : point.y%'),
      margin: EdgeInsets.zero,
      legend: Legend(
        isVisible: true,
        isResponsive: true,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      series: [
        DoughnutSeries<GlucoseReportMetaLevel?, String>(
          radius: '80%',
          explode: true,
          explodeOffset: '10%',
          dataSource: _glucoseReportMetaList,
          xValueMapper: (data, index) {
            switch (index) {
              case 0:
                return context.l10n.veryLow;
              case 1:
                return context.l10n.low;
              case 2:
                return context.l10n.normal;
              case 3:
                return context.l10n.high;
              case 4:
                return context.l10n.veryHigh;
              default:
                return '';
            }
          },
          yValueMapper: (data, index) => data?.percentage ?? 0.0,
        ),
      ],
    );
  }
}
