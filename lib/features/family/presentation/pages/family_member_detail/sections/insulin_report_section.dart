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

class InsulinReportSection extends StatelessWidget {
  const InsulinReportSection({
    Key? key,
    required this.loggedInUser,
  }) : super(
          key: key,
        );

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
    required this.data,
    required this.loggedInUser,
  }) : super(key: key);

  final FamilyData data;
  final bool loggedInUser;

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
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          color: AppColors.amber,
                          size: Dimens.medium,
                        ),
                        const SizedBox(width: Dimens.dp6),
                        HeadingText6(
                          text:
                              'Cur. ${data.user!.insulinDeliveries?.isNotEmpty == true ? data.user!.insulinDeliveries?.first.value.toString() : 0}',
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
            //       GoRouter.of(context).push('/report/insulin');
            //     },
            //     child: HeadingText3(
            //       text: _l10n.detail,
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
          primaryYAxis: NumericAxis(labelFormat: '{value}', interval: 0.1),
          series: data.user != null &&
                  data.user?.insulinDeliveries?.isNotEmpty == true
              ? _getChartDatas()
              : <StepLineSeries<ChartData, DateTime>>[],
        ),
      ],
    );
  }

  /// Returns the list of chart series
  List<StepLineSeries<ChartData, DateTime>> _getChartDatas() {
    final _result = <StepLineSeries<ChartData, DateTime>>[];

    var _group = <ChartData>[];

    var _sourceType = ReportSource.user;

    for (var i = 0; i < data.user!.insulinDeliveries!.length; i++) {
      final item = data.user!.insulinDeliveries![i];
      if (_group.isNotEmpty && item.source != _sourceType) {
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
      } else {
        _sourceType = item.source;
        _group.add(ChartData(x: item.time, y: item.value));
        if (_group.isNotEmpty &&
            i == data.user!.insulinDeliveries!.length - 1) {
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
          _group = [];
        }
      }
    }

    return _result;
  }
}
