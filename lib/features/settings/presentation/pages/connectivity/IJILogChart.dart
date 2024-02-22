import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/IJILog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/*
 * @brief kai_20230226
 * To update IJILogChart when data is changed by another widget on a different page,
 * you can make use of the StatefulWidget and State classes.
 * First, wrap the IJILogChart widget in a StatefulWidget and define a state class for it.
 * Then, in the state class, define a method that updates the data that IJILogChart displays.
 * This method should call setState() to trigger a rebuild of the widget.
 * Next, pass a reference to the state object to the widget that can update the data,
 * such as by passing the state object to the constructor of the widget or
 * by using a provider or callback function. When the widget updates the data,
 * it can call the method in the IJILogChart state object to trigger a rebuild of the chart.
 * Here's an example of how you might modify the IJILogChart widget
 * to support updating the data from another widget:
 */

const bool DEBUG_MESSAGE_FLAG = true;

class IJILogChart extends StatefulWidget {
  // kai_20230226
  /*
   * By providing a default value to the key parameter,
   * you ensure that it is never null, even if the caller does not pass a value for it.
   * providing a default value of const [] for the logs parameter is generally considered a better practice,
   * as it avoids the need for a null check in your code.
   * Note that you can use any value for the default key,
   * as long as it is unique among the widgets in your app.
   * In this example, I used ValueKey('IJILogChart')
   * because it is a simple and unique identifier for the IJILogChart widget.
   * If you have multiple instances of the IJILogChart widget in your app,
   * you should use a different key value for each instance to ensure that
   * they are treated as separate widgets by Flutter's widget tree.
   */

  IJILogChart({
    this.key = const ValueKey('IJILogChart'),
    required this.logs,
  }) : super(key: key);
  List<IJILog> logs = [];
  final Key key;

  @override
  _IJILogChartState createState() => _IJILogChartState();

  void updateChart(BuildContext context) {
    _IJILogChartState state = _IJILogChartState();
   // state._createDataFromLogs(logs);
    state.didUpdateWidget;
  }
}

class _IJILogChartState extends State<IJILogChart> {
  final String TAG = '_IJILogChartState:';

  List<ChartData> _data = [];

  @override
  void initState() {
    super.initState();

    if (DEBUG_MESSAGE_FLAG) {
      debugPrint('${TAG}initState()');
    }

    _createDataFromLogs(widget.logs);

    /*
    var count = 0;
    widget.logs.forEach((log) {
      //_data.add(ChartData(log.time, log.data as int));
      //_data.add(ChartData(DateFormat("yy/MM/dd-HH:mm").format(DateTime.fromMillisecondsSinceEpoch(log.time*1000,isUtc: true)), double.parse(log.data)));
      _data.add(ChartData(DateFormat("yyyy/MM/dd-HH:mm").format(DateTime.fromMillisecondsSinceEpoch(log.time*1000,isUtc: true)).toString(), double.parse(log.data)));

      if(DEBUG_MESSAGE_FLAG)
      {
        count = count + 1;
        debugPrint(TAG + ': ChartData($count).time = ' + DateFormat("yyyy/MM/dd-HH:mm").format(DateTime.fromMillisecondsSinceEpoch(log.time*1000,isUtc: true)).toString());
        debugPrint(TAG + ': ChartData($count).data = ' + log.data.toString());
      }

    });
    */
  }

  /*
   * @brief widget to support updating the data from another widget:
   * To update the chart from another widget,
   * you could pass a reference to the _IJILogChartState object to that widget, like this:
   *
   * class SomeOtherWidget extends StatelessWidget {
      final _IJILogChartState _chartState;
      SomeOtherWidget(this._chartState);

      @override
      Widget build(BuildContext context) {
      // Build the widget and call _chartState.updateLogs() when the data changes
      }
      }
   *
   * When the data changes,
   * you can call _chartState.updateLogs(newLogs) to trigger a rebuild of the IJILogChart widget with
   * the updated data.
   * Note that this assumes that the SomeOtherWidget is a child of the widget that
   * created the _IJILogChartState object (i.e., the widget that created the IJILogChart widget).
   * If the widgets are not in the same subtree,
   * you may need to use a provider or callback function to pass the state object between them.
   *
   */
  void updateLogs(List<IJILog> newLogs) {
    setState(() {
      _data = newLogs.cast<ChartData>();
    });
  }

  void _createDataFromLogs(List<IJILog> logs) {
    setState(() {
      _data.clear();
      for (final log in logs) {
        _data.add(
          ChartData(
            DateFormat('HH:mm:ss').format(
              DateTime.fromMillisecondsSinceEpoch(log.time, isUtc: true),
            ),
            double.parse(log.data),
          ),
        );
      }
    });
  }

  @override
  void didUpdateWidget(IJILogChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logs != widget.logs) {
      _createDataFromLogs(widget.logs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      /*  kai_20230303
      child: SfCartesianChart(
        primaryXAxis: NumericAxis(
          edgeLabelPlacement: EdgeLabelPlacement.shift,
        ),
        primaryYAxis: NumericAxis(
          edgeLabelPlacement: EdgeLabelPlacement.shift,
        ),
        series: <LineSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
            dataSource: _data,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.data,
          )
        ],
      ),
      */
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          // opposedPosition: true,  ///< kai X axis : reverse X axis label is on the top
          isInversed: true,

          ///< kai X axis : the latest Time is located end of right corner
        ),
        primaryYAxis: NumericAxis(
          opposedPosition: true,
        ),
        title: ChartTitle(text: 'Insulin Injection Chart'),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <ChartSeries>[
          LineSeries<ChartData, String>(
            name: 'Insulin',
            dataSource: _data,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.data,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          header: '',
          canShowMarker: false,
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.time, this.data);
  final String time;
  final double data;
}
