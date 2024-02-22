import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartSection extends StatelessWidget {
  const ChartSection({
    Key? key,
    required this.data,
  }) : super(key: key);

  final GlucoseReportData data;

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        interval: 10,
        dateFormat: DateFormat.Hm(),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: NumericAxis(labelFormat: '{value}', interval: 10),
      series: _getChartDatas(),
    );
  }

  /// Returns the list of chart series
  List<ScatterSeries<ChartData, DateTime>> _getChartDatas() {
    final _result = <ScatterSeries<ChartData, DateTime>>[];

    var _group = <ChartData>[];

    var _sourceType = ReportSource.user;

    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      if (_group.isNotEmpty && item.source != _sourceType) {
        _result.add(
          ScatterSeries<ChartData, DateTime>(
            dataSource: _group,
            xValueMapper: (ChartData item, _) => item.x,
            yValueMapper: (ChartData item, _) => item.y,
            color: AppColors.lightBlue[500],
            enableTooltip: true,
          ),
        );

        _sourceType = item.source;
        _group.add(
          ChartData(
            x: item.time,
            y: item.value,
          ),
        );
      } else {
        _sourceType = item.source;
        _group.add(
          ChartData(
            x: item.time,
            y: item.value,
          ),
        );
        if (_group.isNotEmpty && i == data.items.length - 1) {
          _result.add(
            ScatterSeries<ChartData, DateTime>(
              dataSource: _group,
              xValueMapper: (ChartData item, _) => item.x,
              yValueMapper: (ChartData item, _) => item.y,
              color: AppColors.lightBlue[500],
              enableTooltip: true,
            ),
          );
          _group = [];
        }
      }
    }

    return _result;
  }
}
