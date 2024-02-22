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

class InsulinReportSection extends StatelessWidget {
  const InsulinReportSection({
    Key? key,
    required this.onRefresh,
    required this.cMgr,
  }) : super(key: key);

  final VoidCallback onRefresh;
  final ConnectivityMgr cMgr;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsulinReportBloc, InsulinReportState>(
      builder: (context, state) {
        if (state is InsulinReportSuccess) {
          if (state.data.items.isNotEmpty) {
            if (cMgr.mPump != null) {
              cMgr.mPump!.setLastBolusDeliveryValue(state.data.items[0].value);
            }
          }
          return _SuccessContent(data: state.data);
        } else if (state is InsulinReportFailure) {
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

  final InsulinReportData data;

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.amber[100],
                    borderRadius: const BorderRadius.all(
                      Radius.circular(Dimens.small),
                    ),
                  ),
                  child: Image.asset(
                    MainAssets.syringeIcon,
                    width: Dimens.dp24,
                  ),
                ),
                const SizedBox(width: Dimens.dp8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeadingText4(
                      text: context.l10n.insulinDelivery,
                    ),
                    const HeadingText6(
                      // text: '0.44 U',
                      text: '',
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                // GoRouter.of(context).push('/report/insulin');
              },
              child: HeadingText3(
                text: context.l10n.detail,
                textColor: AppColors.primarySolidColor,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 150,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: DateTimeAxis(
              majorGridLines: const MajorGridLines(width: 0),
              interval: 5,
              dateFormat: DateFormat.Hm(),
              edgeLabelPlacement: EdgeLabelPlacement.shift,
            ),
            primaryYAxis: NumericAxis(
              labelFormat: '{value}',
              interval: 0.2,
              opposedPosition: true,
            ),
            series: _getChartDatas(),
          ),
        ),
      ],
    );
  }

  /// Returns the list of chart series
  List<StepLineSeries<ChartData, DateTime>> _getChartDatas() {
    final _result = <StepLineSeries<ChartData, DateTime>>[];

    var _group = <ChartData>[];

    var _sourceType = ReportSource.user;

    for (var i = 0; i < data.items.length; i++) {
      final item = data.items[i];
      if (_group.isNotEmpty && item.source != _sourceType) {
        _group = [];
        _result.add(
          StepLineSeries<ChartData, DateTime>(
            dataSource: _group,
            xValueMapper: (ChartData item, _) => item.x,
            yValueMapper: (ChartData item, _) => item.y,
            color: AppColors.amber[500],
            enableTooltip: true,
            dashArray: const <double>[10, 5],
            width: 2,
            markerSettings:
                MarkerSettings(isVisible: item.source == ReportSource.user),
          ),
        );

        _sourceType = item.source;
        _group.add(
          ChartData(x: item.time, y: item.value),
        );
      } else {
        // _group = [];

        // if (_group.isNotEmpty) {
        _result.add(
          StepLineSeries<ChartData, DateTime>(
            dataSource: _group,
            xValueMapper: (ChartData item, _) => item.x,
            yValueMapper: (ChartData item, _) => item.y,
            color: AppColors.amber[500],
            enableTooltip: true,
            dashArray: const <double>[10, 5],
            width: 2,
            markerSettings:
                MarkerSettings(isVisible: item.source == ReportSource.user),
          ),
        );
        _sourceType = item.source;
        _group.add(ChartData(x: item.time, y: item.value));
        // _group = [];
        // }
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
