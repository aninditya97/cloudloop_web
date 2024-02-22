import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GlucoseReportSection extends StatelessWidget {
  const GlucoseReportSection({
    Key? key,
    required this.loggedInUser,
  }) : super(key: key);

  final bool loggedInUser;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyMemberDetailBloc, FamilyMemberDetailState>(
      builder: (context, state) {
        if (state is FamilyMemberDetailSuccess) {
          return _SuccessContent(
            data: state.data,
            loggedInUser: loggedInUser,
          );
        }
        return const ChartSkeleton();
      },
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({
    Key? key,
    this.data,
    required this.loggedInUser,
  }) : super(key: key);

  final FamilyData? data;
  final bool loggedInUser;

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
                      text: context.l10n.bloodGlucose,
                    ),
                    const SizedBox(height: Dimens.dp4),
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
                              'Cur. ${data?.user != null && data?.user?.bloodGlucoses?.isNotEmpty == true ? (data?.user?.summary?.glucose?.value ?? 0).format() : 0} mg/dL',
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
                              'Avg. ${data?.user != null && data?.user?.bloodGlucoses?.isNotEmpty == true ? (data?.user?.summary?.glucose?.average ?? 0).format() : 0} mg/dL',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // if (loggedInUser) ...[
            //   TextButton(
            //     onPressed: () {
            //       GoRouter.of(context).push('/glucose-detail');
            //     },
            //     child: HeadingText3(
            //       text: context.l10n.detail,
            //       textColor: AppColors.primarySolidColor,
            //     ),
            //   ),
            // ],
          ],
        ),
        SfCartesianChart(
          plotAreaBorderWidth: 0,
          primaryXAxis: DateTimeAxis(
            majorGridLines: const MajorGridLines(width: 0),
            interval: 5,
            dateFormat: DateFormat.Hm(),
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),
          primaryYAxis: NumericAxis(labelFormat: '{value}', interval: 50),
          series: data?.user != null &&
                  data?.user?.bloodGlucoses?.isNotEmpty == true
              ? _getChartDatas(data!)
              : <StepLineSeries<ChartData, DateTime>>[],
        ),
      ],
    );
  }

  /// Returns the list of chart series
  List<StepLineSeries<ChartData, DateTime>> _getChartDatas(FamilyData data) {
    final _result = <StepLineSeries<ChartData, DateTime>>[];

    var _group = <ChartData>[];

    var _sourceType = ReportSource.user;

    for (var i = 0; i < data.user!.bloodGlucoses!.length; i++) {
      final item = data.user!.bloodGlucoses![i];
      if (_group.isNotEmpty && item.source != _sourceType) {
        _result.add(
          StepLineSeries<ChartData, DateTime>(
            dataSource: _group,
            xValueMapper: (ChartData item, _) => item.x,
            yValueMapper: (ChartData item, _) => item.y,
            color: AppColors.lightBlue[500],
            enableTooltip: true,
            dashArray: const <double>[10, 5],
            width: 2,
            markerSettings:
                MarkerSettings(isVisible: item.source == ReportSource.user),
          ),
        );

        _sourceType = item.source;
        _group.add(ChartData(x: item.time, y: item.value));
      } else {
        _sourceType = item.source;
        _group.add(ChartData(x: item.time, y: item.value));
        if (_group.isNotEmpty && i == data.user!.bloodGlucoses!.length - 1) {
          _result.add(
            StepLineSeries<ChartData, DateTime>(
              dataSource: _group,
              xValueMapper: (ChartData item, _) => item.x,
              yValueMapper: (ChartData item, _) => item.y,
              color: AppColors.lightBlue[500],
              enableTooltip: true,
              dashArray: const <double>[10, 5],
              width: 2,
              markerSettings:
                  MarkerSettings(isVisible: item.source == ReportSource.user),
            ),
          );
          _group = [];
        }
      }
    }

    return _result;
  }
}
