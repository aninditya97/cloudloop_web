import 'dart:developer';
import 'dart:io';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/index/sections/section.dart';
import 'package:cloudloop_mobile/features/settings/presentation/blocs/disconnect_pump/disconnect_pump_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/blocs/profile/profile_bloc.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/cspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/Utilities.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/index/component/components.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get_it/get_it.dart';
// import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class InsulinPumpSection extends StatelessWidget {
  const InsulinPumpSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const tag = 'InsulinPumpSection:';
    final _ass = Provider.of<SwitchState>(context, listen: false);

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
                    Icons.sensors_sharp,
                  ),
                  const SizedBox(width: Dimens.dp14),
                  MenuTitleText(
                    text: context.l10n.insulinPump,
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
                (provider.mPump != null &&
                        provider.mPump!.getModelName().isNotEmpty)
                    ? '${provider.mPump!.getModelName()} ${context.l10n.pumpSN}'
                        '${provider.mPump!.SN}'
                    : USE_BROADCASTING_POLICYNET_BOLUS == true &&
                            (CspPreference.getBooleanDefaultFalse(
                                  CspPreference.broadcastingPolicyNetBolus,
                                ) ==
                                true)
                        ? 'virtual pump ${CspPreference.getString(
                            CspPreference.destinationPackageName,
                            defaultValue: 'com.kai.bleperipheral',
                          )}'
                        : '${context.l10n.noPump} ${context.l10n.pumpSN}xxxxxx',

                // context.l10n.caremedi + ' ' + context.l10n.pumpSN +
                // '${provider.mPump!.SN}',
                /*
                (CspPreference.mPUMP_NAME.toLowerCase()
                .contains('${serviceUUID.CareLevo_PUMP_NAME.toLowerCase()}') 
                && provider.mPump != null) ?
                context.l10n.caremedi + ' ' + context.l10n.pumpSN + 
                '${provider.mPump!.SN}'
                    : (provider.mPump != 
                    null && provider.mPump!.getModelName().isNotEmpty && 
                    provider.mPump!.SN.isNotEmpty) ?
                      '${provider.mPump!.getModelName()}' + ' ' + 
                      context.l10n.pumpSN + '${provider.mPump!.SN}'
                     : (provider.mPump != null && 
                     provider.mPump!.getModelName().isEmpty && 
                     provider.mPump!.SN.isNotEmpty && 
                     CspPreference.mPUMP_NAME.isNotEmpty) ?
                       CspPreference.mPUMP_NAME.toString() + ' ' + 
                       '${provider.mPump!.SN}'
                     : (provider.mPump != null && 
                     provider.mPump!.getModelName().isNotEmpty && 
                     provider.mPump!.SN.isEmpty) ?
                       '${provider.mPump!.getModelName()}' + ' ' + 
                       context.l10n.pumpSN + 'xxxxxxxx'
                     : '${context.l10n.noPump}' + ' ' + 
                     context.l10n.pumpSN + 'xxxxxxxx',
                 */
                style: const TextStyle(color: Colors.blueAccent),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: context.theme.primaryColor,
              ),
              onTap: () async {
                //kai_20230831 add disconnectPumpSheet here as like
                //cgm case <start>
                if (CspPreference.getBooleanDefaultFalse(
                      CspPreference.pumpTestPage,
                    ) ==
                    true) {
                  if (Platform.isAndroid) {
                    WidgetsFlutterBinding.ensureInitialized();
                    await [
                      Permission.location,
                      Permission.storage,
                      Permission.bluetooth,
                      Permission.bluetoothConnect,
                      Permission.bluetoothScan
                    ].request().then((status) {
                      // GoRouter.of(context).push('/scan');
                    });
                  } else {
                    // GoRouter.of(context).push('/scan');
                  }
                } else {
                  if ((provider.mPump != null &&
                          provider.mPump!.ConnectionStatus ==
                              BluetoothDeviceState.connected) ||
                      USE_BROADCASTING_POLICYNET_BOLUS == true &&
                          (CspPreference.getBooleanDefaultFalse(
                                CspPreference.broadcastingPolicyNetBolus,
                              ) ==
                              true)) {
                    //show stop/cancel
                    log('${tag}kai:provider.mPump!.ConnectionStatus '
                        '== connected');
                    await _showDissconnectPumpDialog(
                      context,
                      provider,
                    );
                  }
                  // kai_20230912 blocked for testing csp-1 temporarily,
                  // let's unblock to support commercial release
                  //
                  else if (provider.mPump != null &&
                      provider.mPump!.ConnectionStatus !=
                          BluetoothDeviceState.connected) {
                    //show select pump type & scan & connection
                    log('${tag}kai:provider.mPump!.ConnectionStatus '
                        '!= connected');
                    /*
                  _showDissconnectPumpDialog(
                    context,
                    provider,
                  );
                   */
                    //kai_20230911 add
                    await showDialog<String>(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) => WillPopScope(
                        onWillPop: () => Future.value(false),
                        child: ConnectionDialogPage(
                          // onDeviceSelected: (value) {},
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          context: context,
                          accessType: 'setting_pump',
                          switchStateAlert: _ass,
                          /*
                          onCheckAlertCondition: (){
                            if(USE_ALERT_PAGE_INSTANCE == true)
                            {  debugPrint(
                                      '${TAG}:kai:no registered SwitchSate. 
                                      check alert notification');
                            }
                          },  */
                        ),
                      ),
                    );
                  } else {
                    if (Platform.isAndroid) {
                      WidgetsFlutterBinding.ensureInitialized();
                      await [
                        Permission.location,
                        Permission.storage,
                        Permission.bluetooth,
                        Permission.bluetoothConnect,
                        Permission.bluetoothScan
                      ].request().then((status) {
                        // GoRouter.of(context).push('/scan');
                      });
                    } else {
                      // GoRouter.of(context).push('/scan');
                    }
                  }
                }

                //<end>
              },
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                text: provider.mPump != null
                    ? '${context.l10n.activeInsulin}: '
                        '${provider.mPump!.bolusDeliveryValue.toString()} U'
                    : '${context.l10n.activeInsulin}: 0 U',
                textColor: AppColors.blueGray[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                text: provider.mPump != null
                    ? '${context.l10n.pumpReservior}: '
                        '${provider.mPump!.reservoir} U'
                    : '${context.l10n.pumpReservior}: 0 U',
                textColor: AppColors.blueGray[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                text: provider.mPump != null
                    ? '${context.l10n.pumpBattery}: '
                        '${provider.mPump!.getBatteryLevel()}%'
                    : '${context.l10n.pumpBattery}: 00%',
                textColor: AppColors.blueGray[800],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              child: MenuTitleText(
                //kai_20231006 text: context.l10n.sinceRefill + ':
                //5${context.l10n.day} 12${context.l10n.hour}
                //50${context.l10n.mins}',
                text: provider.mPump != null
                    ? '${context.l10n.sinceRefill}: '
                        ' ${formatDurationEx(
                        context,
                        calculateTimeDifference(
                          provider.mPump!.getrefillTime() <= 0
                              ? DateTime.now().millisecondsSinceEpoch
                              : provider.mPump!.getrefillTime(),
                          DateTime.now().millisecondsSinceEpoch,
                        ),
                      )}'
                    : '${context.l10n.sinceRefill}: '
                        '0${context.l10n.day} 00${context.l10n.hour} '
                        '00${context.l10n.mins}',
                textColor: AppColors.blueGray[800],
              ),
            ),
          ],
        );
      },
    );
  }

  //kai_20230831  add functions here
  Future _showDissconnectPumpDialog(
    BuildContext context,
    ConnectivityMgr cMgr,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _DisconnectPumpSheet(
          onPressed: () {
            cMgr.disconnectPUMP();
            CspPreference.setBool(
              CspPreference.disconnectedByUser,
              true,
            ); // kai_20230926 : disconnect by user action
            if (USE_RESET_PUMP_BY_PRESSING_STOP == true) {
              //kai_20231016 let's clear the flag here
              CspPreference.setBool(CspPreference.pumpSetTimeReqDoneKey, false);
              /*
              if(cMgr != null && cMgr.mPump != null){
                cMgr.mPump!.refillTime = 0;
              } */
            }
            if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
                (CspPreference.getBooleanDefaultFalse(
                      CspPreference.broadcastingPolicyNetBolus,
                    ) ==
                    true)) {
              CspPreference.removeValue(
                CspPreference.broadcastingPolicyNetBolus,
              );
              CspPreference.removeValue(
                CspPreference.destinationPackageName,
              );
            }
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

class _DisconnectPumpSheet extends StatelessWidget {
  const _DisconnectPumpSheet({
    Key? key,
    required this.onPressed,
  }) : super(
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
          create: (context) => GetIt.I<DisconnectPumpBloc>(),
        ),
      ],
      child: _DisconnectPumpView(
        onPressed: onPressed,
      ),
    );
  }
}

class _DisconnectPumpView extends StatefulWidget {
  const _DisconnectPumpView({
    Key? key,
    required this.onPressed,
  }) : super(
          key: key,
        );

  final VoidCallback onPressed;

  @override
  State<_DisconnectPumpView> createState() => _DisconnectPumpSheetState();
}

class _DisconnectPumpSheetState extends State<_DisconnectPumpView> {
  late SwitchState? _ass;

  @override
  void initState() {
    super.initState();
    // let's get SwitchState instance here
    log('kai:_DisconnectPumpSheetState.initState() is called');
    _ass = Provider.of<SwitchState>(context, listen: false);
    if (_ass == null) {
      log('kai:_DisconnectPumpSheetState.initState()._ASS is null!!');
    }
  }

  @override
  void dispose() {
    log('kai:_DisconnectPumpSheetState.dispose() is called');
    super.dispose();
  }

  Future _showConnectPumpDialog(BuildContext context) async {
    await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: ConnectionDialogPage(
          // onDeviceSelected: (value) {},
          onPressed: () {
            //kai_20230830 exception is occurred when
            //access this page thru Settings => CGM Stop
            if (mounted) {
              Navigator.pop(context);
            }
          },
          context: context,
          accessType: 'setting_pump',
          switchStateAlert: _ass!,
          /*
          onCheckAlertCondition: (){
            if(USE_ALERT_PAGE_INSTANCE == true)
            {  debugPrint(
                '_DisconnectPumpSheetState:kai:no 
                registered SwitchSate. check alert notification');
            }
          },  */
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DisconnectPumpBloc, DisconnectPumpState>(
      listener: (context, state) {
        if (state is DisconnectPumpFailure) {
          log('failed');
        } else if (state is DisconnectPumpSuccess) {
          log('success');
          widget.onPressed.call();
          Navigator.pop(context);
          _showConnectPumpDialog(context);
        }
      },
      child: ActionableContentSheet(
        header: HeadingText2(text: context.l10n.stopPump),
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                context.read<DisconnectPumpBloc>().add(
                      const DisconnectPumpFetched(),
                    );
              },
              child: Text(context.l10n.stop),
            ),
            const SizedBox(
              height: Dimens.small,
            ),
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
          context.l10n.stopPumpDescription,
        ),
      ),
    );
  }
}
