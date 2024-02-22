import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GlucoseReportSection extends StatelessWidget {
  const GlucoseReportSection({
    Key? key,
    required this.onRefresh,
    required this.cMgr,
  }) : super(key: key);

  final VoidCallback onRefresh;
  final ConnectivityMgr cMgr;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlucoseReportBloc, GlucoseReportState>(
      builder: (context, state) {
        if (state is GlucoseReportSuccess) {
          if (state.data.items.isNotEmpty) {
            if (cMgr.mCgm != null) {
              cMgr.mCgm!.setLastBloodGlucose(state.data.items[0].value.toInt());
              log('udin:call set last blood '
                  'glucose ${state.data.items[0].value.toInt()}');
              log('get diff : '
                  '${DateTime.now().difference(state.data.items[0].time).inMinutes}');
              if (cMgr.mCgm!.getBloodGlucoseHistoryList().isEmpty) {
                for (var i = 0; i < state.data.items.length; i++) {
                  if (DateTime.now()
                          .difference(state.data.items[i].time)
                          .inMinutes <
                      30) {
                    cMgr.mCgm!.setRecievedTimeHistoryList(
                      1,
                      state.data.items[i].time.toIso8601String(),
                    );
                    cMgr.mCgm!.setBloodGlucoseHistoryList(
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
          return _SuccessContent(data: state.data);
        } else if (state is GlucoseReportFailure) {
          return _FailureContent(
            message: state.error.message,
            onRefresh: onRefresh,
          );
        }
        return const ChartSkeleton();
      },
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({Key? key, required this.data}) : super(key: key);

  final GlucoseReportData data;

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
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.lightBlue,
                          size: Dimens.medium,
                        ),
                        const SizedBox(width: Dimens.dp6),
                        HeadingText6(
                          text: '${(data.meta?.current ?? 0.0).format()} mg/dL',
                        ),
                        const SizedBox(width: Dimens.dp12),
                        Icon(
                          Icons.circle,
                          color: AppColors.blueGray[300],
                          size: Dimens.medium,
                        ),
                        const SizedBox(width: Dimens.dp6),
                        HeadingText6(
                          text:
                              'Avg. ${(data.meta?.average ?? 0.0).format()} mg/dL',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // GoRouter.of(context).push('/glucose-detail');
              },
              child: HeadingText3(
                text: _l10n.detail,
                textColor: AppColors.primarySolidColor,
              ),
            )
          ],
        ),
        SizedBox(
          height: 200,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: DateTimeAxis(
              majorGridLines: const MajorGridLines(width: 0),
              interval: 30,
              dateFormat: DateFormat.Hm(),
              zoomPosition: 0.5,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
            ),
            primaryYAxis: NumericAxis(
              labelFormat: '{value}',
              interval: 10,
              opposedPosition: true,
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
        _group.add(ChartData(x: item.time, y: item.value));
      } else {
        _sourceType = item.source;
        _group.add(ChartData(x: item.time, y: item.value));
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
