import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GlucoseInsulinReportSection extends StatefulWidget {
  const GlucoseInsulinReportSection({
    Key? key,
    required this.onRefresh,
    required this.cMgr,
    required this.onCalibrate,
  }) : super(key: key);

  final VoidCallback onRefresh;
  final ConnectivityMgr cMgr;
  final VoidCallback onCalibrate;

  @override
  State<GlucoseInsulinReportSection> createState() =>
      _GlucoseInsulinReportSectionState();
}

class _GlucoseInsulinReportSectionState
    extends State<GlucoseInsulinReportSection> {
  GlucoseReportData? data;
  InsulinReportData? data2;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GlucoseReportBloc, GlucoseReportState>(
          listener: (context, state) {
            if (state is GlucoseReportSuccess) {
              if (state.data.items.isNotEmpty) {
                if (widget.cMgr.mCgm != null) {
                  widget.cMgr.mCgm!
                      .setLastBloodGlucose(state.data.items[0].value.toInt());
                  log('udin:call set last blood '
                      'glucose //${state.data.items[0].value.toInt()}');
                  log(
                    'get diff : '
                    '${DateTime.now().difference(state.data.items[0].time).inMinutes}',
                  );
                  if (widget.cMgr.mCgm!.getBloodGlucoseHistoryList().isEmpty) {
                    for (var i = 0; i < state.data.items.length; i++) {
                      if (DateTime.now()
                              .difference(state.data.items[i].time)
                              .inMinutes <
                          30) {
                        widget.cMgr.mCgm!.setRecievedTimeHistoryList(
                          1,
                          state.data.items[i].time.toIso8601String(),
                        );
                        widget.cMgr.mCgm!.setBloodGlucoseHistoryList(
                          1,
                          double.parse(
                            state.data.items[i].value.toString(),
                          ).floor(),
                        );
                      }
                    }
                  }
                }
              }
              data = state.data;
              setState(() {});
              // return _SuccessContent(data: state.data);
            }

            // else if (state is GlucoseReportFailure) {
            //   return _FailureContent(
            //     message: state.error.message,
            //     onRefresh: onRefresh,
            //   );
            // }
            // return const ChartSkeleton();
          },
        ),
        BlocListener<InsulinReportBloc, InsulinReportState>(
          listener: (context, state) {
            if (state is InsulinReportSuccess) {
              if (state.data.items.isNotEmpty) {
                if (widget.cMgr.mPump != null) {
                  widget.cMgr.mPump!
                      .setLastBolusDeliveryValue(state.data.items[0].value);
                }
              }
              data2 = state.data;
              setState(() {});
            }
          },
        ),
      ],
      child: _SuccessContent(
        data: data,
        data2: data2,
        onCalibrate: widget.onCalibrate,
      ),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    Key? key,
    required this.data,
    required this.data2,
    required this.onCalibrate,
  }) : super(key: key);

  final GlucoseReportData? data;
  final InsulinReportData? data2;
  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: Dimens.dp36,
                  padding: const EdgeInsets.all(Dimens.dp8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue[100],
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Dimens.small),
                    ),
                  ),
                  child: Image.asset(
                    MainAssets.bloodDropIcon,
                    width: Dimens.dp24,
                  ),
                ),
                const SizedBox(width: Dimens.dp8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeadingText4(
                      text: _l10n.bloodGlucose,
                    ),
                    const SizedBox(
                      height: Dimens.dp4,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.lightBlue,
                          size: Dimens.medium,
                        ),
                        const SizedBox(width: Dimens.dp6),
                        HeadingText6(
                          text:
                              'Cur. ${(data?.meta?.current ?? 0.0).format()} mg/dL',
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: AppColors.blueGray[300],
                          size: Dimens.medium,
                        ),
                        const SizedBox(width: Dimens.dp6),
                        HeadingText6(
                          text:
                              'Avg. ${(data?.meta?.average ?? 0.0).format()} mg/dL',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: onCalibrate.call,
              child: HeadingText3(
                text: context.l10n.calibrate,
                textColor: AppColors.primarySolidColor,
              ),
            )
          ],
        ),
        SizedBox(
          height: 400,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            tooltipBehavior: TooltipBehavior(enable: true),
            axes: <ChartAxis>[
              NumericAxis(
                opposedPosition: false,
                name: 'yAxis1',
                majorGridLines: const MajorGridLines(width: 0),
                labelFormat: '{value}',
                interval: 0.2,
                maximum: 2,
                minimum: 0,
                edgeLabelPlacement: EdgeLabelPlacement.shift,
              )
            ],
            primaryXAxis: DateTimeAxis(
              majorGridLines: const MajorGridLines(width: 0),
              interval: 10,
              dateFormat: DateFormat.Hm(),
              maximum: DateTime.now(),
              maximumLabels: 10,
              edgeLabelPlacement: EdgeLabelPlacement.none,
            ),
            primaryYAxis: CategoryAxis(
              interval: 10,
              maximum: 300,
              minimum: 0,
              opposedPosition: true,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              plotBands: <PlotBand>[
                PlotBand(
                  start: 70,
                  end: 180,
                  opacity: 0.3,
                  textStyle: const TextStyle(
                    color: Colors.black,
                  ),
                  color: Colors.greenAccent,
                ),
              ],
            ),
            series: _getChartDatas(),
            zoomPanBehavior: ZoomPanBehavior(
              enableDoubleTapZooming: true,
              enablePanning: true,
              enablePinching: true,
              enableSelectionZooming: true,
              zoomMode: ZoomMode.x,
            ),
          ),
        ),
      ],
    );
  }

  /// Returns the list of chart series
  List<ChartSeries<ChartData, DateTime>> _getChartDatas() {
    final _result = <ChartSeries<ChartData, DateTime>>[];

    var _group = <ChartData>[];

    var _sourceType = ReportSource.user;

    if (data != null) {
      for (var i = 0; i < data!.items.length; i++) {
        final item = data!.items[i];
        if (_group.isNotEmpty && item.source != _sourceType) {
          _result.add(
            ScatterSeries<ChartData, DateTime>(
              dataSource: _group,
              xValueMapper: (ChartData item, _) => item.x,
              yValueMapper: (ChartData item, _) => item.y,
              enableTooltip: true,
              pointColorMapper: (ChartData item, _) => _getPointColor(item.y),
            ),
          );

          _sourceType = item.source;
          _group.add(ChartData(x: item.time, y: item.value));
        } else {
          _sourceType = item.source;
          _group.add(ChartData(x: item.time, y: item.value));
          if (_group.isNotEmpty && i == data!.items.length - 1) {
            _result.add(
              ScatterSeries<ChartData, DateTime>(
                dataSource: _group,
                xValueMapper: (ChartData item, _) => item.x,
                yValueMapper: (ChartData item, _) => item.y,
                enableTooltip: true,
                pointColorMapper: (ChartData item, _) => _getPointColor(item.y),
              ),
            );
            _group = [];
          }
        }
      }
    }

    if (data2 != null) {
      for (var i = 0; i < data2!.items.length; i++) {
        final item = data2!.items[i];
        if (_group.isNotEmpty && item.source != _sourceType) {
          _result.add(
            StepLineSeries<ChartData, DateTime>(
              dataSource: _group,
              yAxisName: 'yAxis1',
              xValueMapper: (ChartData item, _) => item.x.toUtc(),
              yValueMapper: (ChartData item, _) => item.y,
              color: AppColors.amber[500],
              enableTooltip: true,
              width: 2,
            ),
          );

          _sourceType = item.source;
          _group.add(ChartData(x: item.time, y: item.value));
        } else {
          _sourceType = item.source;
          _group.add(ChartData(x: item.time, y: item.value));
          if (_group.isNotEmpty && i == data2!.items.length - 1) {
            _result.add(
              StepLineSeries<ChartData, DateTime>(
                dataSource: _group,
                yAxisName: 'yAxis1',
                xValueMapper: (ChartData item, _) => item.x.toUtc(),
                yValueMapper: (ChartData item, _) => item.y,
                color: AppColors.amber[500],
                enableTooltip: true,
                width: 2,
              ),
            );
            _group = [];
          }
        }
      }
    }

    return _result;
  }

  Color? _getPointColor(num? value) {
    Color? color;
    if (value! > 180) {
      color = Colors.red;
    } else if (value < 70) {
      color = Colors.yellow;
    } else {
      color = AppColors.lightBlue[500];
    }
    return color;
  }
}

class _FailureContent extends StatelessWidget {
  const _FailureContent({Key? key, this.message, this.onRefresh})
      : super(key: key);

  final String? message;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ErrorMessageWidget(
        message: message,
        onPress: onRefresh,
      ),
    );
  }
}
