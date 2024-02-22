import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/database/database_helper.dart';
import 'package:cloudloop_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/enums/enums.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/presentation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart';

class AlertSummarySection extends StatelessWidget {
  const AlertSummarySection({
    Key? key,
    required this.onRefresh,
    required this.onCGMRequestConnect,
  }) : super(key: key);

  final VoidCallback onRefresh;
  final VoidCallback onCGMRequestConnect;

  @override
  Widget build(BuildContext context) {
    var light = false;
    return Consumer<ConnectivityMgr>(
      builder: (context, provider, child) {
        onRefresh.call();
        return BlocBuilder<GlucoseReportBloc, GlucoseReportState>(
          builder: (context, state) {
            if (state is GlucoseReportSuccess) {
              return _SuccessContent(
                data: state.data,
                onRefresh: onRefresh,
                onCGMRequestConnect: onCGMRequestConnect,
                cMgr: provider,
              );
            } else if (state is GlucoseReportFailure) {
              return _FailureContent(
                message: state.error.message,
                onRefresh: onRefresh,
              );
            }
            return const _LoadingContent();
          },
        );
      },
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 5; i++) ...[
          Container(
            height: 80,
            width: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimens.dp8),
              border: Border.all(
                color: AppColors.blueGray[200]!,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Skeleton(
                  width: Dimens.dp32,
                  height: Dimens.dp32,
                  radius: Dimens.dp16,
                ),
                SizedBox(height: Dimens.dp8),
                Skeleton(width: Dimens.dp40, height: Dimens.dp12)
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SuccessContent extends StatefulWidget {
  const _SuccessContent({
    Key? key,
    required this.data,
    required this.cMgr,
    required this.onRefresh,
    required this.onCGMRequestConnect,
  }) : super(key: key);

  final GlucoseReportData data;
  final VoidCallback onRefresh;
  final ConnectivityMgr cMgr;
  final VoidCallback onCGMRequestConnect;

  @override
  State<_SuccessContent> createState() => _SuccessContentState();
}

class MyCustomMessages implements LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => '0 min ago';
  @override
  String aboutAMinute(int minutes) => '$minutes min ago';
  @override
  String minutes(int minutes) => '$minutes min ago';
  @override
  String aboutAnHour(int minutes) => '$minutes min ago';
  @override
  String hours(int hours) => '$hours hr ago';
  @override
  String aDay(int hours) => '$hours hr ago';
  @override
  String days(int days) => '$days day ago';
  @override
  String aboutAMonth(int days) => '$days day ago';
  @override
  String months(int months) => '$months mon ago';
  @override
  String aboutAYear(int year) => '$year y ago';
  @override
  String years(int years) => '$years y ago';
  @override
  String wordSeparator() => ' ';
}

class _SuccessContentState extends State<_SuccessContent> {
  bool light = false;
  String? icon;
  Timer? timer;
  String? lastUpdate = '0 min ago';
  int? lastValue = 0;
  String? lastTimeAgo;
  String? lastTime;
  Directions? directions;

  late DateTime currentTime;

  @override
  void initState() {
    initValue();
    super.initState();
    /* Noti.initialize(); */
  }

  void initValue() {
    timeago.setLocaleMessages('en', MyCustomMessages());

    if (widget.data.items.isNotEmpty) {
      lastValue = widget.data.items.first.value.toInt();
      lastTimeAgo = widget.data.items.first.time.toIso8601String();
      lastTime = DateFormat('HH:mm a').format(
        DateTime.parse(
          widget.data.items.first.time.toIso8601String(),
        ),
      );

      currentTime = lastTimeAgo != null
          ? DateTime.parse(lastTimeAgo.toString())
          : DateTime.now();

      lastUpdate = timeago.format(
        currentTime.subtract(
          const Duration(seconds: 1),
        ),
      );

      timer = Timer.periodic(
        const Duration(seconds: 1),
            (timer) {
          lastUpdate = timeago.format(
            currentTime.subtract(
              const Duration(seconds: 1),
            ),
          );
          setState(() {});
        },
      );
    }
  }

  @override
  void dispose() {
    if (timer != null) {
      timer!.cancel();
    }
    super.dispose();
  }

  Future<void> _fetchAutoMode() async {
    context.read<GetAutoModeBloc>().add(
      const AutoModeFetched(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (timer != null) {
      timer!.cancel();
    }

    // widget.onRefresh.call();

    if (widget.cMgr.mCgm != null) {
      if (widget.cMgr.mCgm!.getCollectBloodGlucose() != null) {
        // get json data fom XDrip
        // widget.onRefresh.call();
        final xDripdata = widget.cMgr.mCgm!.getCollectBloodGlucose();
        currentTime = DateTime.parse(
          DateFormat('yyyy-MM-dd HH:mm:ss').format(
            DateTime.fromMillisecondsSinceEpoch(
              int.parse(xDripdata!.timestamp),
            ),
          ),
        );

        // set last time to receive the data
        lastUpdate = timeago.format(
          currentTime.subtract(
            const Duration(seconds: 1),
          ),
        );
        timer = Timer.periodic(
          const Duration(seconds: 1),
              (timer) {
            lastUpdate = timeago.format(
              currentTime.subtract(
                const Duration(seconds: 1),
              ),
            );
            setState(() {});
          },
        );

        // set blood glucose value
        lastValue = double.parse(xDripdata.glucose).floor();
        lastTime = DateFormat('HH:mm a').format(
          DateTime.fromMillisecondsSinceEpoch(
            int.parse(xDripdata.timestamp),
          ),
        );
      }
    } else {
      icon = MainAssets.flatArrowIcon;
    }
    return BlocListener<SetAutoModeBloc, SetAutoModeState>(
      listener: (context, state) {
        if (state is SetAutoModeSuccess) {
          _fetchAutoMode();
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          HomeSummaryPills(
            pillIcon: Column(
              children: [
                HeadingText1(
                  //annisa added
                  text: lastValue != null && lastValue! > 0
                      ? lastValue.toString()
                      : 0.format(),
                  textColor: AppColors.primarySolidColor,
                ),
                const Text(
                  'mg/dl',
                  style: TextStyle(
                    fontSize: Dimens.dp10,
                    color: AppColors.primarySolidColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // },
    // );
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
