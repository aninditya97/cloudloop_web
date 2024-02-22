import 'dart:async';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/components/component.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/enums/enums.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/presentation.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart';

class HomeSummarySection extends StatelessWidget {
  const HomeSummarySection({
    Key? key,
    required this.onRefresh,
    required this.onCheckAutoMode,
    required this.onCGMRequestConnect,
    required this.onPumpRequestConnect,
    this.onSetDose,
  }) : super(key: key);

  final VoidCallback onRefresh;
  final VoidCallback onCheckAutoMode;
  final VoidCallback onCGMRequestConnect;
  final VoidCallback onPumpRequestConnect;
  final VoidCallback? onSetDose;

  @override
  Widget build(BuildContext context) {
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
                onPumpRequestConnect: onPumpRequestConnect,
                cMgr: provider,
                onSetDose: onSetDose,
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
    required this.onPumpRequestConnect,
    this.onSetDose,
  }) : super(key: key);

  final GlucoseReportData data;
  final VoidCallback onRefresh;
  final ConnectivityMgr cMgr;
  final VoidCallback onCGMRequestConnect;
  final VoidCallback onPumpRequestConnect;
  final VoidCallback? onSetDose;

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

    // set init direction
    if (widget.data.items.length >= 2) {
      initDirection(
        lastValue ?? 0,
        widget.data.items[1].value.toInt(),
      );
    } else {
      icon = MainAssets.flatArrowIcon;
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
    //kai_20230615 added
    // return Consumer<ConnectivityMgr>(
    //   builder: (context, provider, child) {
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

        // set direction
        directions = xDripdata.direction;
        if (directions == Directions.doubleDown) {
          icon = MainAssets.doubleDownArrowIcon;
        } else if (directions == Directions.doubleUp) {
          icon = MainAssets.doubleUpArrowIcon;
        } else if (directions == Directions.singleDown) {
          icon = MainAssets.singleDownArrowIcon;
        } else if (directions == Directions.singleUp) {
          icon = MainAssets.singleUpArrowIcon;
        } else if (directions == Directions.fortyFiveDown) {
          icon = MainAssets.fortyFiveDownArrowIcon;
        } else if (directions == Directions.fortyFiveUp) {
          icon = MainAssets.fortyFiveUpArrowIcon;
        } else {
          icon = MainAssets.flatArrowIcon;
        }
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
            pillIcon: Image.asset(
              MainAssets.statusIcon,
              width: Dimens.dp32,
            ),
            pillDesc: lastUpdate.toString(),
          ),
          BlocBuilder<GetAutoModeBloc, GetAutoModeState>(
            builder: (context, state) {
              if (state is GetAutoModeSuccess) {
                return Column(
                  children: [
                    Text(
                      '${context.l10n.autoMode} \n'
                      '${state.success == 1 ? context.l10n.on : context.l10n.off}',
                      style: const TextStyle(
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Switch(
                      // This bool value toggles the switch.
                      value: state.success == 1,
                      activeColor: Colors.red,
                      onChanged: (bool value) {
                        // This is called when the user toggles the switch.

                        if (state.success == 1) {
                          _showMyDialog(
                            context.l10n.autoModeOff,
                            state.success == 1,
                          );
                        } else {
                          _showMyDialog(
                            context.l10n.autoModeOn,
                            state.success == 1,
                          );
                        }
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          InkWell(
            child: HomeSummaryPills(
              pillIcon: Image.asset(
                MainAssets.syringeIcon,
                width: Dimens.dp32,
              ),
              pillDesc: 'Bolus',
            ),
            onTap: () {
              final state = context.read<GetAutoModeBloc>().state;
              if (state is GetAutoModeSuccess) {
                if (state.success == 1) {
                  context.showErrorSnackBar(context.l10n.automodeTurnOn);
                } else {
                  widget.onSetDose?.call();
                }
              }
            },
          ),
          HomeSummaryPills(
            pillIcon: Column(
              children: [
                HeadingText1(
                  //kai_20230615 added
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
                )
              ],
            ),
            pillDesc: lastTime,
          ),
          HomeSummaryPills(
            pillIcon: Image.asset(
              icon.toString(),
              width: Dimens.dp32,
            ),
          ),
        ],
      ),
    );
    // },
    // );
  }

  Future<void> _showMyDialog(String question, bool mode) async {
    light = mode;
    //kai_20231102 check cMgr instance here
    log('kai:_showMyDialog:mounted($mounted)');
    if (widget.cMgr == null) {
      log('kai:_showMyDialog::widget.cMgr is null ');
    }

    return showDialog<void>(
      context: (mounted == true)
          ? context
          : (widget.cMgr.appContext != null)
              ? widget.cMgr.appContext!
              : context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.autoMode),
          content: Text(question),
          actions: [
            TextButton(
              child: Text(context.l10n.confirm),
              onPressed: () {
                if (!light) {
                  //kai_20231101 exception occur: //log('udin:call total bg history ='
                  //'${widget.cMgr.mCgm!.getBloodGlucoseHistoryList().length}');
                  if (widget.cMgr.mCgm == null) {
                    _showCheckCGMConnectionDialog();
                  } else if (widget.cMgr.mPump!.ConnectionStatus !=
                      BluetoothDeviceState.connected) {
                    //kai_20231220 add to skip checking below when broadcasting bolus is enabled with turning on auto mode
                    if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
                        CspPreference.getBooleanDefaultFalse(
                              CspPreference.broadcastingPolicyNetBolus,
                            ) ==
                            true) {
                      log('kai:call total bg history ='
                          '${widget.cMgr.mCgm!.getBloodGlucoseHistoryList().length}');
                      if (widget.cMgr.mCgm!
                              .getBloodGlucoseHistoryList()
                              .length <
                          6) {
                        Navigator.of(context).pop();

                        _showCheckBloodGlucoseHistoryDialog(context);
                      } else {
                        Navigator.of(context).pop();
                        context.read<SetAutoModeBloc>().add(
                              const AutoModeRequestSubmitted(),
                            );
                      }
                    } else {
                      _showCheckPumpConnectionDialog();
                    }
                  } else {
                    log('udin:call total bg history ='
                        '${widget.cMgr.mCgm!.getBloodGlucoseHistoryList().length}');
                    if (widget.cMgr.mCgm!.getBloodGlucoseHistoryList().length <
                        6) {
                      Navigator.of(context).pop();

                      _showCheckBloodGlucoseHistoryDialog(context);
                    } else {
                      Navigator.of(context).pop();
                      context.read<SetAutoModeBloc>().add(
                            const AutoModeRequestSubmitted(),
                          );
                    }
                  }
                } else {
                  Navigator.of(context).pop();
                  context.read<SetAutoModeBloc>().add(
                        const AutoModeRequestSubmitted(),
                      );
                  context.read<SetAnnounceMealBloc>().add(
                        const AnnounceMealRequestSubmitted(type: 0),
                      );
                }
              },
            ),
            TextButton(
              child: Text(context.l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCheckBloodGlucoseHistoryDialog(BuildContext context) async {
    //kai_20231102 check cMgr instance here
    log('kai:_showCheckBloodGlucoseHistoryDialog:mounted($mounted)');
    if (widget.cMgr == null) {
      log('kai:_showCheckBloodGlucoseHistoryDialog::widget.cMgr is null ');
    }
    return showDialog<void>(
      context: (mounted == true)
          ? context
          : (widget.cMgr.appContext != null)
              ? widget.cMgr.appContext!
              : context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.bloodGlucoseHistory),
          content: Text(
            context.l10n.bloodGlucoseHistoryDescription,
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCheckCGMConnectionDialog() async {
    //kai_20231102 check cMgr instance here
    log('kai:_showCheckCGMConnectionDialog:mounted($mounted)');
    if (widget.cMgr == null) {
      log('kai:_showCheckCGMConnectionDialog::widget.cMgr is null ');
    }
    return showDialog<void>(
      context: (mounted == true)
          ? context
          : (widget.cMgr != null && widget.cMgr.appContext != null)
              ? widget.cMgr.appContext!
              : context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.cgmStatus),
          content: Text(
            context.l10n.cgmStatusDescription,
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.confirm),
              onPressed: () {
                log('kai:call widget.onCGMRequestConnect.call()');
                Navigator.of(context).pop();
                widget.onCGMRequestConnect.call();
              },
            ),
            TextButton(
              child: Text(context.l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCheckPumpConnectionDialog() async {
    //kai_20231102 check cMgr instance here
    log('kai:_showCheckPumpConnectionDialog:mounted($mounted)');
    if (widget.cMgr == null) {
      log('kai:_showCheckPumpConnectionDialog::widget.cMgr is null ');
    }

    return showDialog<void>(
      context: (mounted == true)
          ? context
          : (widget.cMgr != null && widget.cMgr.appContext != null)
              ? widget.cMgr.appContext!
              : context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.pumpStatus),
          content: Text(
            context.l10n.pumpStatusDescription,
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.confirm),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPumpRequestConnect.call();
              },
            ),
            TextButton(
              child: Text(context.l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void initDirection(int lastValue, int beforeLastValue) {
    final finalValue = lastValue - beforeLastValue;
    if (finalValue < -19) {
      icon = MainAssets.doubleDownArrowIcon;
    } else if (finalValue > 19) {
      icon = MainAssets.doubleUpArrowIcon;
    } else if (finalValue <= -9 && finalValue >= -19) {
      icon = MainAssets.singleDownArrowIcon;
    } else if (finalValue >= 9 && finalValue <= 19) {
      icon = MainAssets.singleUpArrowIcon;
    } else if (finalValue <= -5 && finalValue >= -9) {
      icon = MainAssets.fortyFiveDownArrowIcon;
    } else if (finalValue <= 5 && finalValue <= 9) {
      icon = MainAssets.fortyFiveUpArrowIcon;
    } else {
      icon = MainAssets.flatArrowIcon;
    }
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
