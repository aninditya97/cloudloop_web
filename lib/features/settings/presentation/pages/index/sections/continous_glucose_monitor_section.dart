import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/index/sections/section.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Utilities.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/serviceUuid.dart';

class ContinousGlucoseSection extends StatelessWidget {
  const ContinousGlucoseSection({Key? key}) : super(key: key);
  static const int MAX_USE_CGM_TRANSMITTER_DAYS = 7;

  ///< 7 days

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityMgr>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: Dimens.appPadding,
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_outlined,
                  ),
                  const SizedBox(width: Dimens.dp14),
                  MenuTitleText(
                    text: context.l10n.continuousGlucoseMonitor,
                    textColor: AppColors.blueGray[800],
                  )
                ],
              ),
            ),
            Divider(
              color: AppColors.blueGray[100],
              thickness: 1,
            ),
            SettingMenuTile(
              title: Text(
                (provider.mCgm != null &&
                        provider.mCgm!.getModelName().isNotEmpty)
                    ? '${provider.mCgm!.getModelName()} ${context.l10n.cgmSN}${provider.mCgm!.cgmSN}'
                    : '${context.l10n.noCgm} ${context.l10n.cgmSN}xxxxxxxx',
                /*
                (CspPreference.mCGM_NAME.toLowerCase().contains('${serviceUUID.ISENSE_CGM_NAME.toLowerCase()}') && provider.mCgm != null) ?
                context.l10n.iSens + ' ' + context.l10n.cgmSN + '${provider.mCgm!.cgmSN}'
                : (provider.mCgm != null && provider.mCgm!.getModelName().isNotEmpty && provider.mCgm!.cgmSN.isNotEmpty) ?
                  '${provider.mCgm!.getModelName()}' + ' ' + context.l10n.cgmSN + '${provider.mCgm!.cgmSN}'
                : (provider.mCgm != null && provider.mCgm!.getModelName().isEmpty && provider.mCgm!.cgmSN.isNotEmpty && CspPreference.mCGM_NAME.isNotEmpty) ?
                  CspPreference.mCGM_NAME.toString() + ' ' + context.l10n.cgmSN + '${provider.mCgm!.cgmSN}'
                : (provider.mCgm != null && provider.mCgm!.getModelName().isNotEmpty && provider.mCgm!.cgmSN.isEmpty) ?
                  '${provider.mCgm!.getModelName()}' + ' ' + context.l10n.cgmSN + 'xxxxxxxx'
                : context.l10n.noCgm + ' ' + context.l10n.cgmSN + 'xxxxxxxx',
                 */
                style: TextStyle(color: Colors.blueAccent),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.theme.primaryColor,
              ),
              onTap: () {
                // if (provider.mCgm != null) {
                _showDissconnectCgmDialog(
                  context,
                  provider,
                );
                // } else {
                //   print('asssu');
                // }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                //kai_20231006 text: context.l10n.sinceInsertion + ': 3${context.l10n.day} 15${context.l10n.hour} 40${context.l10n.mins}',
                text: provider.mCgm != null
                    ? '${context.l10n.sinceInsertion}: ${formatDurationEx(context, calculateTimeDifference(provider.mCgm!.gettransmitterInsertTime() <= 0 ? DateTime.now().millisecondsSinceEpoch : provider.mCgm!.gettransmitterInsertTime(), DateTime.now().millisecondsSinceEpoch))}'
                    : '${context.l10n.sinceInsertion}: 0${context.l10n.day} 00${context.l10n.hour} 00${context.l10n.mins}',
                textColor: AppColors.blueGray[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                text: provider.mCgm == null
                    ? '${context.l10n.sensorExpires}: 0${context.l10n.day} 00${context.l10n.hour} 00${context.l10n.mins}'
                    : provider.mCgm!.gettransmitterInsertTime() <= 0
                        ? '${context.l10n.sensorExpires}: 0${context.l10n.day} 00${context.l10n.hour} 00${context.l10n.mins}'
                        : '${context.l10n.sensorExpires}: ${formatDurationEx2(context, calculateTimeDifference(provider.mCgm!.gettransmitterInsertTime(), 0), MAX_USE_CGM_TRANSMITTER_DAYS, 0, 0, 0)}',
                textColor: AppColors.blueGray[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                text: provider.mCgm == null
                    ? '${context.l10n.lastCalibration}: 0${context.l10n.hour} 00${context.l10n.mins}'
                    : provider.mCgm!.getlastCalibrationTime() <= 0
                        ? '${context.l10n.lastCalibration}: 0${context.l10n.hour} 00${context.l10n.mins}'
                        : '${context.l10n.lastCalibration}: ${CvtMiliSecsToTimeDateFormat(provider.mCgm!.getlastCalibrationTime())}',
                textColor: AppColors.blueGray[800],
              ),
            ),
          ],
        );
      },
    );
  }

  Future _showDissconnectCgmDialog(
    BuildContext context,
    ConnectivityMgr cMgr,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _DisconnectCgmSheet(
          onPressed: () {
            cMgr.disconnectCGM();
            //kai_20231013 add to update screen
            if (cMgr.mCgm != null && cMgr.mCgm!.getModelName().isNotEmpty) {
              cMgr.mCgm!.cgmModelName = '';
              debugPrint(
                  'kai:_DisconnectCgmSheet: call cMgr.mCgm!.notifyListeners()');
              cMgr.mCgm!.notifyListeners();
            }
            debugPrint('kai:_DisconnectCgmSheet: call cMgr.notifyListeners() ');
            cMgr.notifyListeners();
            // _showConnectCgmDialog(context);
            // if (Navigator.canPop(context)) {
            //   Navigator.of(context).pop();
            // }
          },
        );
      },
    );
  }
}

class _DisconnectCgmSheet extends StatelessWidget {
  const _DisconnectCgmSheet({Key? key, required this.onPressed})
      : super(
          key: key,
        );

  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<ProfileBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<DisconnectCgmBloc>(),
        ),
      ],
      child: _DisconnectCgmView(
        onPressed: onPressed,
      ),
    );
  }
}

class _DisconnectCgmView extends StatefulWidget {
  const _DisconnectCgmView({Key? key, required this.onPressed})
      : super(
          key: key,
        );

  final VoidCallback onPressed;

  @override
  State<_DisconnectCgmView> createState() => _DisconnectCgmSheetState();
}

class _DisconnectCgmSheetState extends State<_DisconnectCgmView> {
  late SwitchState? _ASS = null;

  Future _showConnectCgmDialog(BuildContext context) async {
    await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: ConnectionDialogPage(
          // onDeviceSelected: (value) {},
          onPressed: () {
            //kai_20230830 exception is occurred when access this page thru Settings => CGM Stop
            if (mounted) {
              Navigator.pop(context);
            }
          },
          context: context,
          accessType: 'setting_cgm',
          switchStateAlert: _ASS!,
          /*
          onCheckAlertCondition: (){
            if(USE_ALERT_PAGE_INSTANCE == true)
            {
              SwitchState ASS = Provider.of<SwitchState>(context, listen: false);
              ConnectivityMgr mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
              if(ASS != null && mCMgr != null)
              {
                AlertPage? _mAPage = ASS!.mAlertPage;
                if (_mAPage != null) {
                  _mAPage!.checkAlertNotificationCondition(
                      (USE_APPCONTEXT == true && mCMgr.appContext != null &&
                          !mounted) ? mCMgr.appContext! : context);
                }
                else {
                  debugPrint(
                      '_DisconnectCgmSheetState:kai:no registered SwitchSate. check alert notification');
                }
              }

            }
          },  */
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DisconnectCgmBloc, DisconnectCgmState>(
      listener: (context, state) {
        if (state is DisconnectCgmFailure) {
          log('failed');
        } else if (state is DisconnectCgmSuccess) {
          log('success');
          widget.onPressed.call();
          Navigator.pop(context);
          _showConnectCgmDialog(context);
        }
      },
      child: ActionableContentSheet(
        header: HeadingText2(text: context.l10n.stopCgm),
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                context
                    .read<DisconnectCgmBloc>()
                    .add(const DisconnectCgmFetched());
              },
              child: Text(context.l10n.stop),
            ),
            const SizedBox(height: Dimens.small),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blueGray,
              ),
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
        content: Text(
          context.l10n.stopCgmDescription,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // let's get SwitchState instance here
    log('kai:_DisconnectCgmSheetState.initState() is called');
    _ASS = Provider.of<SwitchState>(context, listen: false);
    if (_ASS == null) {
      log('kai:_DisconnectCgmSheetState.initState()._ASS is null!!');
    }
  }

  @override
  void dispose() {
    log('kai:_DisconnectCgmSheetState.dispose() is called');
    super.dispose();
  }
}
