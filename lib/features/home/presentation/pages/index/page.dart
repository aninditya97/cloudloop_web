import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloudloop_mobile/core/core.dart';
import 'package:cloudloop_mobile/core/helpers/date_time_helper.dart';
import 'package:cloudloop_mobile/features/auth/auth.dart';
import 'package:cloudloop_mobile/features/family/family.dart';
import 'package:cloudloop_mobile/features/home/home.dart';
import 'package:cloudloop_mobile/features/home/presentation/pages/index/sections/section.dart';
import 'package:cloudloop_mobile/features/settings/domain/entities/xdrip_data.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/AlertPage.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/CspPreference.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/XDripLauncher.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/audioplay/csaudioplayer.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ConnectivityMgr.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/PumpDanars.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/ResponseCallback.dart';
import 'package:cloudloop_mobile/features/settings/presentation/pages/connectivity/provider/featureFlag.dart';
import 'package:cloudloop_mobile/features/settings/settings.dart';
import 'package:cloudloop_mobile/features/summary/summary.dart';
import 'package:cloudloop_mobile/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:formz/formz.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

//kai_20230622   test flag here ==========
const bool TEST_FEATCH_DATA_UPDATE = false;
const bool TEST_FEATCH_DATA_TWO_DAYS = true;

//dwi_20231220  test flag here
const bool TEST_WITHOUT_PUMP = true;
//========================================

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetIt.I<AcceptFamilyInvitationBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<RejectFamilyInvitationBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<UpdateFamilyBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<FamilyMemberBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<InvitationsMemberBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<GetPumpBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<GetCgmBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<SaveCgmBloc>(),
        ),
        BlocProvider(
          create: (context) => GetIt.I<SavePumpBloc>(),
        ),
      ],
      child: const HomeView(),
      /*
      //kai_20230615
      child: ChangeNotifierProvider<ConnectivityMgr>(
        create: (_) => ConnectivityMgr(),
        child: const HomeView(),
      ),
       */
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isLoadingDialogOpen = false;
  bool _isFamilyStatusDialogOpen = false;
  int? _userId;
  String? _label;
  static bool _setDose = false;
  static bool get setDose => _setDose;
  static set setDose(bool value) {
    _setDose = value;
  }

  final _date = (TEST_FEATCH_DATA_TWO_DAYS == true)
      ? DateTimeRange(
          start: DateTimeHelper.minifyFormatDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
          end: DateTimeHelper.minifyFormatDate(DateTime.now()),
        )
      : DateTimeRange(
          start: DateTimeHelper.minifyFormatDate(DateTime.now()),
          end: DateTimeHelper.minifyFormatDate(DateTime.now()),
        );

  final String tag = '_HomeViewState:';
  final bool _isShowCGMDialog = false;
  late ConnectivityMgr mCMgr;
  late BuildContext mContext;

  CgmInfoData? _cgmInfoData;
  final int maxValodCodeLength = 4;
  final int maxTransmitterIDLength = 6;
  bool _isConnecting = false;
  bool _pumpIsConnected = false;

  late CsaudioPlayer mAudioPlayer;
  late AlertPage? _mAPage = null;
  late SwitchState? _mSwitchState = null;

  Future<void> _fetchAllData() async {
    await _fetchBloodGlucose();
    await _fetchInsulinDelivery();
    // await _fetchCarbohydrate();
    await _fetchSummaryReport();
    await _fetchInvitation();
    await _fetchCgm();
    await _fetchPump();
    await _fetchAutoMode();
    await _fetchAnnounceMeal();
  }

  Future<void> _fetchBloodGlucose() async {
    context.read<GlucoseReportBloc>().add(
          GlucoseReportFetched(
            startDate: _date.start,
            endDate: _date.end,
            filter: false,
          ),
        );
  }

  Future<void> _fetchAutoMode() async {
    context.read<GetAutoModeBloc>().add(
          const AutoModeFetched(),
        );
  }

  Future<void> _fetchAnnounceMeal() async {
    context.read<GetAnnounceMealBloc>().add(
          const AnnounceMealFetched(),
        );
  }

  Future<void> _fetchInsulinDelivery() async {
    context.read<InsulinReportBloc>().add(
          InsulinReportFetched(
            startDate: _date.start,
            endDate: _date.end,
            filter: false,
          ),
        );
  }

  Future<void> _fetchSummaryReport() async {
    context.read<SummaryReportBloc>().add(
          SummaryReportFetched(startDate: _date.start, endDate: _date.end),
        );
  }

  Future<void> _fetchInvitation() async {
    context.read<InvitationsMemberBloc>().add(
          FetchInvitationsMemberEvent(
            page: 1,
            perPage: 2,
          ),
        );
  }

  Future<void> _fetchPump() async {
    context.read<GetPumpBloc>().add(
          const PumpFetched(),
        );
  }

  Future<void> _fetchCgm() async {
    context.read<GetCgmBloc>().add(
          const CgmFetched(),
        );
  }

  void _acceptInvitation(int id) {
    context.read<AcceptFamilyInvitationBloc>().add(
          AcceptFamilyInvitationFetched(
            id: id,
          ),
        );
  }

  void _rejectInvitation(int id) {
    context.read<RejectFamilyInvitationBloc>().add(
          RejectFamilyInvitationFetched(
            id: id,
          ),
        );
  }

  void _onUpdate(int id, String label) {
    context.read<UpdateFamilyBloc>().add(
          UpdateFamilyFetched(
            id: id,
            label: label,
          ),
        );
  }

  void _fetchFamilyData(int page) {
    context.read<FamilyMemberBloc>().add(
          FetchFamilyMemberEvent(
            page: page,
            perPage: 20,
          ),
        );
  }

  Future<void> _showConnectSensorDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          title: Text(context.l10n.connectSensor),
          content: Text(
            context.l10n.connectToCgmAndInsulin,
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.connect),
              onPressed: () async {
                if (mounted) {
                  Navigator.of(context).pop();
                }
                //  await _showCGMDialog();
                //kai_20230911
                await _onCGMSettingDialog();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCGMDialog() {
    var selectedRadio = '';
    return showDialog(
      context: (mounted == true)
          ? context
          : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
              ? mCMgr.appContext!
              : context,
      barrierDismissible: false, // user must tap button!
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          title: Text(
            context.l10n.selectInputItem(context.l10n.cgm),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                height: 120,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text('${context.l10n.iSens} ${context.l10n.cgm}'),
                      leading: Radio(
                        value: context.l10n.iSens,
                        groupValue: selectedRadio,
                        onChanged: (value) {
                          setState(
                            () => selectedRadio = value.toString(),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      title:
                          Text('${context.l10n.virtual} ${context.l10n.cgm}'),
                      leading: Radio(
                        value: context.l10n.virtual,
                        groupValue: selectedRadio,
                        onChanged: (value) {
                          setState(
                            () => selectedRadio = value.toString(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.confirm),
              onPressed: () async {
                if (mounted) {
                  Navigator.of(context).pop();
                }
                if (selectedRadio == context.l10n.iSens) {
                  await _showInpuCGMDialog();
                }
              },
            ),
            TextButton(
              child: Text(context.l10n.cancel),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInpuCGMDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (
        BuildContext context,
      ) {
        return BlocProvider(
          create: (context) => GetIt.I<SaveCgmBloc>(),
          child: BlocConsumer<SaveCgmBloc, SaveCgmState>(
            listener: (context, state) {
              if (state.status.isSubmissionSuccess) {
                _dismissLoadingDialog();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } else if (state.status.isSubmissionInProgress) {
                _showLoadingDialog();
              } else if (state.status.isSubmissionFailure) {
                _dismissLoadingDialog();
                context.showErrorSnackBar(state.failure?.message);
              }
            },
            builder: (context, state) {
              return AlertDialog(
                title: Text(context.l10n.inputCgmIdentity),
                content: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SizedBox(
                      height: 150,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimens.dp8,
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: context.l10n.enterCgmTransmitterId,
                                hintStyle: const TextStyle(
                                  fontSize: Dimens.dp14,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.blueGray[200]!,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(Dimens.dp8),
                                  ),
                                ),
                                errorText: state.id.invalid
                                    ? context.l10n.invalidInputCannotEmpty(
                                        'id',
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                context
                                    .read<SaveCgmBloc>()
                                    .add(CgmTransmitterIdChanged(value));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimens.dp8,
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: context.l10n.enterCgmSensorCode,
                                hintStyle: const TextStyle(
                                  fontSize: Dimens.dp14,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppColors.blueGray[200]!,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(Dimens.dp8),
                                  ),
                                ),
                                errorText: state.deviceId.invalid
                                    ? context.l10n.invalidInputCannotEmpty(
                                        'code',
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                context
                                    .read<SaveCgmBloc>()
                                    .add(CgmTransmitterCodeChanged(value));
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: state.id.valid &&
                            state.transmitterCode.valid &&
                            state.transmitterCode.valid
                        ? () {
                            context.read<SaveCgmBloc>().add(
                                  const CgmRequestSubmitted(),
                                );
                          }
                        : null,
                    child: Text(context.l10n.confirm),
                  ),
                  TextButton(
                    child: Text(context.l10n.cancel),
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /*
   * @fn _handlePumpResponseCallback(RSPType indexRsp, String message, 
   * String actionType)
   * @brief when bolus injection is success then pushing the data to 
   * remote DB by using this API.
   *        this API is used in Home screen
   * @param[in] indexRsp : RESPType index
   * @param[in] message : message
   * @param[in] actionType : pump protocol Command Type
   */
  void _handlePumpResponseCallback(
    RSPType indexRsp,
    String message,
    String actionType,
  ) {
    if (mCMgr.mPump == null) {
      log('kai:_handlePumpResponseCallback(): mCMgr.mPump is null!!: '
          'Cannot handle the response event!! ');
      return;
    }

    log('${tag}kai:_handlePumpResponseCallback() is called, mounted = $mounted');
    log('${tag}kai:RSPType($indexRsp)'
        '\nmessage($message)\nActionType($actionType)');

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          // To do something here after receive the processing result
          if (actionType == HCL_BOLUS_RSP_SUCCESS) {
            //kai_20230613 add to update insulin delivery chart and DB here
            if (mCMgr != null && mCMgr.mPump != null) {
              // final insulDelivery = mCMgr.mPump!.BolusDeliveryValue;
              final insulDelivery = mCMgr.mPump!.getBolusDeliveryValue();
              setDose = true;
              log('${tag}kai:HCL_BOLUS_RSP_SUCCESS:'
                  'BolusDeliveryValue(${insulDelivery.toString()}), '
                  'call updateInsulinDelivery()');
              _inputInsulinDelivery(insulDelivery.toString());
              mCMgr.notifyListeners();
            }
          }
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          log('${tag}kai:TOAST_POPUP: redraw Screen widgits ');
          final msg = message;
          // String Title = '${(USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext!: context.l10n.processing}';
          final type = actionType;
          mCMgr.mPump!.showNoticeMsgDlg = false;
          mCMgr.mPump!.SetUpWizardMsg = '';

          ///< clear
          mCMgr.mPump!.SetUpWizardActionType = '';

          //kai_20230512 let's call connectivityMgr.notifyListener() to notify bolus injection processing time & value
          // for consumer or selector page
          mCMgr.notifyListeners();

          showMsgProgress(
            (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                ? mCMgr.appContext!
                : context,
            msg,
            'blue',
            int.parse(type),
          );
        }
        break;

      case RSPType.ALERT:
        {
          log('${tag}kai:ALERT: redraw Screen widgits ');
        }
        if (mCMgr.mPump!.showALertMsgDlg) {
          final msg = mCMgr.mPump!.AlertMsg;
          final title = mCMgr.appContext!.l10n.alert;
          mCMgr.mPump!
            ..showALertMsgDlg = false
            ..AlertMsg = '';

          ///< clear
          //  _showTXErrorMsgDialog(Title,Msg);
          // create dialog and start alert playback onetime
          WarningMsgDlg(title, msg, 'red', 5);
        }

        break;

      case RSPType.NOTICE:
        {
          log('${tag}kai:NOTICE: show toast message ');
          String Msg = mCMgr.mPump!.NoticeMsg;
          String Type = actionType;
          mCMgr.mPump!.showNoticeMsgDlg = false;
          mCMgr.mPump!.NoticeMsg = '';
          // _showToastMessage(context,Msg,'blue',int.parse(Type));
          showToastMessageDebounce(
              (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
              Msg,
              'blue',
              int.parse(Type));
          //kai_20240109 should call below to refresh changed variable on the Pump info of setting page.
          mCMgr.notifyListeners();
        }
        break;

      case RSPType.ERROR:
        {
          log('${tag}kai:ERROR: redraw Screen widgits ');
        }
        if (mCMgr.mPump!.showTXErrorMsgDlg) {
          //let' clear variable here after copy them to buffer
          final msg = mCMgr.mPump!.TXErrorMsg;
          final title = mCMgr.appContext!.l10n.error;
          mCMgr.mPump!
            ..showTXErrorMsgDlg = false
            ..TXErrorMsg = '';

          ///< clear
          showTXErrorMsgDialog(title, msg);
        }

        break;

      case RSPType.WARNING:
        {
          log('${tag}kai:WARNING: redraw Screen widgits ');
        }
        if (mCMgr.mPump!.showWarningMsgDlg) {
          final msg = mCMgr.mPump!.WarningMsg;
          final title = mCMgr.appContext!.l10n.warning;
          mCMgr.mPump!.showWarningMsgDlg = false;
          //  _notifier.WarningMsg = '';  ///< clear

          //kai_20230512 let's call connectivityMgr.notifyListener() to notify bolus injection processing time & value
          // for consumer or selector page
          mCMgr.notifyListeners();

          //  _showTXErrorMsgDialog(Title,Msg);
          // create dialog and start alert playback onetime
          WarningMsgDlg(title, msg, 'red', 0);
        }
        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          log('${tag}kai:SETUP_INPUT_DLG: redraw Screen widgits ');
          final msg = message;
          final title = mCMgr.appContext!.l10n.setup;
          final type = actionType;
          mCMgr.mPump!
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';
          _showSetupWizardMsgDialog(title, msg, type);
        }
        break;

      case RSPType.SETUP_DLG:
        {
          log('${tag}kai:SETUP_DLG: redraw Screen widgits ');
          final msg = message;
          final title = mCMgr.appContext!.l10n.setup;
          final type = actionType;
          mCMgr.mPump!
            ..showNoticeMsgDlg = false
            ..SetUpWizardMsg = ''

            ///< clear
            ..SetUpWizardActionType = '';
          _showSetupWizardMsgDialog(title, msg, type);
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          //update screen, redraw
          if (mounted) {
            setState(() {
              //kai_20230502
              log('${tag}kai:Pump:UPDATE_SCREEN: redraw Screen widgits ');
            });

            switch (actionType) {
              case 'DISCONNECT_PUMP_FROM_USER_ACTION':
                {
                  log('${tag}kai:DISCONNECT_PUMP_FROM_USER_ACTION');
                  setState(() {
                    _showMessage(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      '${CspPreference.mPUMP_NAME} '
                      '${(USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext! : context.l10n.disconnectByUSer}',
                    );
                  });
                  mCMgr.notifyListeners();
                }
                break;

              case 'DISCONNECT_FROM_DEVICE_PUMP':
                {
                  log('${tag}kai:DISCONNECT_FROM_DEVICE_PUMP');
                  setState(() {
                    _showWarningMessage(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      '${CspPreference.mPUMP_NAME} '
                      '${(USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext! : context.l10n.disconnectDevice}',
                    );
                  });
                  mCMgr.notifyListeners();
                  //kai_20230612 we need to consider auto reconnection in this
                  //case in order to keep use the service.
                }
                break;

              case 'CONNECT_TO_DEVICE_PUMP':
                {
                  log('${tag}kai:CONNECT_TO_DEVICE_PUMP');
                  setState(() {
                    _showMessage(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      '${CspPreference.mPUMP_NAME} '
                      '${(USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext! : context.l10n.hasBeenConnected}',
                    );
                  });
                  mCMgr.notifyListeners();
                }
                break;

              case 'TIMEOUT_CONNECT_TO_DEVICE_PUMP':
                {
                  log('${tag}kai:TIMEOUT_CONNECT_TO_DEVICE_PUMP');
                  setState(() {
                    _showMessage(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      '${(USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext! : context.l10n.timeoutForConnecting} '
                      '${CspPreference.mPUMP_NAME}!!',
                    );
                  });
                  mCMgr.notifyListeners();
                }
                break;
            }
          }
        }
        break;
      case RSPType.MAX_RSPTYPE:
        // TODO: Handle this case.
        break;
    }
  }

  @override
  void initState() {
    _fetchAllData();
    super.initState();

    log('kai:_HomeViewState.initState() is called');
    //kai_20230613 add
    mCMgr = Provider.of<ConnectivityMgr>(context, listen: false);
    mContext = (USE_APPCONTEXT == true && mCMgr.appContext != null)
        ? mCMgr.appContext!
        : context;

    if (mCMgr != null && mCMgr.mPump != null) {
      // log('kai:_HomeViewState.initState():
      //register mCMgr.mPump!.addListener()');
      //  mCMgr.mPump!.removeListener(_handlePumpProviderEvent);f
      // mCMgr.mPump!.addListener(_handlePumpProviderEvent);
      final prevRspCallback = mCMgr.mPump!.getResponseCallbackListener();
      if (prevRspCallback == null) {
        log('kai:_HomeViewState.initState(): '
            'register mCMgr.RegisterResponseCallbackListener(mCMgr.mPump!, '
            '_handlePumpResponseCallback)');
        mCMgr.registerResponseCallbackListener(
          mCMgr.mPump,
          _handlePumpResponseCallback,
        );
      }
    }

    if (mCMgr != null && mCMgr.mCgm != null) {
      final prevRspCallbackCgm = mCMgr.mCgm!.getResponseCallbackListener();
      if (prevRspCallbackCgm == null) {
        log('kai:_HomeViewState.initState(): register '
            'mCMgr.RegisterResponseCallbackListener(mCMgr.mCgm!, '
            'HandleResponseCallbackCgm)');
        mCMgr.registerResponseCallbackListener(
          mCMgr.mCgm,
          _handleResponseCallbackCgm,
        );
      }
    }

    //kai_20230802  add to keep default BGDataStream Listener for the cgm that use broadcasting method as like xdrip
    if (mCMgr != null) {
      log('kai:_HomeViewState.initState(): register '
          'mCMgr.SetDefaultPumpResponseListener(_handlePumpResponseCallback)');
      //kai_20230802 added
      mCMgr.SetDefaultPumpResponseListener(_handlePumpResponseCallback);
      log('kai:_HomeViewState.initState(): register '
          'mCMgr.SetDefaultCgmResponseListener(_handleResponseCallbackCgm)');
      mCMgr.SetDefaultCgmResponseListener(_handleResponseCallbackCgm);
      log('kai:_HomeViewState.initState(): register '
          'mCMgr.SetDefaultBGDataStreamListener(_bloodGlucoseDataStreamCallback)');
      mCMgr.SetDefaultBGDataStreamListener(_bloodGlucoseDataStreamCallback);

      if (mCMgr.mPump != null) {
        log('kai:_HomeViewState.initState(): register '
            'mCMgr.RegisterDefaultPumpResponseListener(mCMgr.mPump)');
        mCMgr.RegisterDefaultPumpResponseListener(mCMgr.mPump);
      }

      if (mCMgr.mCgm != null) {
        log('kai:_HomeViewState.initState(): register '
            'RegisterDefaultCgmResponseListener(mCMgr.mCgm)');
        mCMgr.RegisterDefaultCgmResponseListener(mCMgr.mCgm);
        log('kai:_HomeViewState.initState(): register '
            'RegisterDefaultBGDataStreamListener(mCMgr.mCgm)');
        mCMgr.RegisterDefaultBGDataStreamListener(mCMgr.mCgm);
      } else {
        log('kai:_HomeViewState.initState():mCMgr.mCgm == null');
      }
    }

    if (USE_AUDIO_PLAYBACK == true) {
      if (USE_AUDIOCACHE == true) {
        //maudioCacheplayer = AudioCache();
        mAudioPlayer = CsaudioPlayer();
      } else {
        // maudioPlayer = AudioPlayer();
        mAudioPlayer = CsaudioPlayer();
      }
    }

    if (USE_ALERT_PAGE_INSTANCE == true) {
      final ASS = Provider.of<SwitchState>(context, listen: false);
      if (ASS == null) {
        _mAPage = const AlertPage();
      } else {
        _mAPage = ASS.mAlertPage;
        _mSwitchState = ASS;
      }
    }
  }

  void checkAlertNotification() {
    if (_mAPage != null) {
      _mAPage!.checkAlertNotificationCondition(
        (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
            ? mCMgr.appContext!
            : context,
      );
      if (USE_CHECK_NEW_BG_IS_INCOMING) {
        _mAPage!.checkNewBGIncomingTimer(
          (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
              ? mCMgr.appContext!
              : context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _l10n = context.l10n;

    Future<void> _showMyDialog() async {
      var _isSelected = 0;
      return showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (
          BuildContext ctx,
        ) {
          return AlertDialog(
            title: Text(_l10n.announceMeal),
            content: StatefulBuilder(
              // You need this, notice the parameters below:

              builder: (BuildContext ctx, StateSetter setInnerState) {
                // _setState = setState;
                return SizedBox(
                  height: Dimens.dp150,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimens.dp16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.eatNext30min,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.dp8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setInnerState(() => _isSelected = 1);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSelected == 1
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                    side: BorderSide(
                                      width: 2, // the thickness
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.snack,
                                    style: TextStyle(
                                      color: _isSelected == 1
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimens.dp8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setInnerState(() => _isSelected = 2);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSelected == 2
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                    side: BorderSide(
                                      width: 2, // the thickness
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.meal,
                                    style: TextStyle(
                                      color: _isSelected == 2
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Dimens.dp16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: Dimens.dp8),
                      child: TextButton(
                        child: Text(context.l10n.confirm),
                        onPressed: () {
                          if (mounted) {
                            Navigator.of(ctx).pop();
                          }
                          if (_isSelected > 0) {
                            context.read<SetAnnounceMealBloc>().add(
                                  AnnounceMealRequestSubmitted(
                                    type: _isSelected,
                                  ),
                                );
                          } else {
                            _showWarningMessage(
                              context,
                              "You haven't selected anything, please check again.",
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: Dimens.dp8),
                      child: TextButton(
                        child: Text(context.l10n.cancel),
                        onPressed: () {
                          if (mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAllData();
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: MultiBlocListener(
          listeners: [
            BlocListener<InvitationsMemberBloc, InvitationsMemberState>(
              listener: (context, state) {
                if (state is InvitationsMemberFailure) {
                  _dismissCGMDialog();
                  _dismissLoadingDialog();
                } else if (state is InvitationsMemberSuccess) {
                  _dismissLoadingDialog();
                  final itemList = state.data
                      .where((e) => e.status == InvitationStatus.status3)
                      .toList();
                  if (itemList.isNotEmpty) {
                    _showInvitationDialogSheet(
                      context,
                      itemList,
                    );
                  }
                }
              },
            ),
            BlocListener<AcceptFamilyInvitationBloc,
                AcceptFamilyInvitationState>(
              listener: (context, state) {
                if (state is AcceptFamilyInvitationFailure) {
                  _dismissCGMDialog();
                  _dismissLoadingDialog();
                  _onFailure(state.failure);
                } else if (state is AcceptFamilyInvitationSuccess) {
                  _dismissLoadingDialog();
                  _onSuccess(_l10n.acceptInvitation);
                  Future.delayed(
                    const Duration(seconds: 1),
                    () {
                      if (mounted) {
                        _fetchFamilyData(1);
                        // _isFamilyStatusDialogOpen = true;
                      }
                    },
                  );
                } else if (state is AcceptFamilyInvitationLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<RejectFamilyInvitationBloc,
                RejectFamilyInvitationState>(
              listener: (context, state) {
                if (state is RejectFamilyInvitationFailure) {
                  _dismissCGMDialog();
                  _dismissLoadingDialog();
                  _onFailure(state.failure);
                } else if (state is RejectFamilyInvitationSuccess) {
                  _dismissLoadingDialog();
                  _onSuccess(_l10n.rejectInvitation);
                } else if (state is RejectFamilyInvitationLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<UpdateFamilyBloc, UpdateFamilyState>(
              listener: (context, state) {
                if (state is UpdateFamilyFailure) {
                  _dismissCGMDialog();
                  _dismissLoadingDialog();
                  _onFailure(state.failure);
                } else if (state is UpdateFamilySuccess) {
                  Future.delayed(
                    const Duration(seconds: 5),
                    () {
                      _dismissLoadingDialog();
                      if (_isFamilyStatusDialogOpen) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                  Future.delayed(const Duration(seconds: 5), () {
                    _onSuccess(_l10n.dataUpdated);
                  });
                } else if (state is UpdateFamilyLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<GetCgmBloc, GetCgmState>(
              listener: (context, state) async {
                if (state is GetCgmFailure) {
                  _dismissCGMDialog();
                  _dismissLoadingDialog();
                } else if (state is GetCgmSuccess) {
                  _dismissLoadingDialog();
                  log('udin:call cgm data main page : ${state.data}');

                  if (mCMgr.mCgm == null && state.data == null) {
                    log('kai:call _onCGMSettingDialog()');
                    await _showConnectSensorDialog();
                    //kai_20230911  _onCGMSettingDialog();
                  } else {
                    if (state.data != null) {
                      if (state.data?.status == true && mCMgr.mCgm == null) {
                        log(
                          'kai:call re-connect data: ${state.data})',
                        );
                        log('kai:call re-connect again with ${state.data!.deviceId}');
                        log('kai:call re-connect status is ${state.data!.status}');
                        //kai_20230911  _onCGMSettingDialog(data: state.data);
                        // await _showConnectSensorDialog();
                        await _onCGMSettingDialog(data: state.data);
                      } else {
                        log('kai:call connecting with ${state.data!.deviceId}');
                        log('kai:call connecting status is ${state.data!.status}');
                      }
                    }
                  }
                } else if (state is GetCgmLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<GetPumpBloc, GetPumpState>(
              listener: (context, state) async {
                if (state is GetPumpFailure) {
                  _dismissLoadingDialog();
                } else if (state is GetPumpSuccess) {
                  log('udin:call re-connect pump : ${state.data}');

                  if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
                      (CspPreference.getBooleanDefaultFalse(
                            CspPreference.broadcastingPolicyNetBolus,
                          ) ==
                          true)) {
                    /*
                    await CspPreference.setBool(
                      CspPreference.broadcastingPolicyNetBolus,
                      true,
                    );
                     */
                    await CspPreference.setString(
                      CspPreference.destinationPackageName,
                      state.data?.name ?? 'com.kai.bleperipheral',
                    );
                    log(
                      'udin:call re-connect broadcasting policynet bolus',
                    );
                  } else {
                    _pumpIsConnected = state.data?.status ?? false;
                    await _autoConnect();
                    log(
                      'udin:call re-connect bluetooth pump',
                    );
                  }

                  _dismissLoadingDialog();
                } else if (state is GetPumpLoading) {
                  _showLoadingDialog();
                }
              },
            ),
            BlocListener<InputBloodGlucoseBloc, InputBloodGlucoseState>(
              listener: (context, state) {
                if (state.status.isSubmissionInProgress) {
                  _showLoadingDialog();
                } else if (state.status.isSubmissionSuccess) {
                  _dismissLoadingDialog();
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      _fetchBloodGlucose();
                    }
                  });
                } else if (state.status.isSubmissionFailure) {
                  _dismissLoadingDialog();
                  _onFailure(state.failure!);
                }
              },
            ),
            BlocListener<InputInsulinBloc, InputInsulinState>(
              listener: (context, state) {
                if (state.status.isSubmissionInProgress) {
                  _showLoadingDialog();
                } else if (state.status.isSubmissionSuccess) {
                  _dismissLoadingDialog();
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      _fetchInsulinDelivery();
                    }
                  });
                } else if (state.status.isSubmissionFailure) {
                  _dismissLoadingDialog();
                  _onFailure(state.failure!);
                }
              },
            ),
            BlocListener<SetAnnounceMealBloc, SetAnnounceMealState>(
              listener: (context, state) async {
                if (state is SetAnnounceMealSuccess) {
                  await _fetchAnnounceMeal();
                }
              },
            ),
            BlocListener<SetAutoModeBloc, SetAutoModeState>(
              listener: (context, state) async {
                if (state is SetAutoModeSuccess) {
                  await _fetchAutoMode();
                }
              },
            ),
            BlocListener<FamilyMemberBloc, FamilyMemberState>(
              listener: (context, state) async {
                if (state is FamilyMemberFailure) {
                  _dismissLoadingDialog();
                  _onFailure(state.failure);
                } else if (state is FamilyMemberSuccess) {
                  _dismissLoadingDialog();
                  final _user = (await GetIt.I<GetProfileUseCase>().call(
                    const NoParams(),
                  ))
                      .foldRight(
                    const UserProfile(
                      gender: Gender.female,
                      name: '',
                      id: '',
                      weight: 0,
                      totalDailyDose: 0,
                    ),
                    (r, previous) => r,
                  );
                  final data = state.data
                      .where((e) => e.user!.id == int.parse(_user.id))
                      .toList();
                  if (mounted) {
                    _showUpdateLabelDialogSheet(context, data[0].id);
                  }
                }
              },
            ),
          ],
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(
                top: Dimens.dp24,
                left: Dimens.appPadding,
                right: Dimens.appPadding,
              ),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      MainAssets.logoVertical,
                      width: 134,
                      height: 27,
                    ),
                    Row(
                      children: [
                        Container(
                          alignment: Alignment.centerRight,
                          width: 100,
                          child: Text(
                            context.l10n.welcomeToUser('${context.user?.name}'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: Dimens.dp8,
                        ),
                        ClipOval(
                          child: SizedBox.fromSize(
                            size: const Size.fromRadius(
                              Dimens.dp20,
                            ), // Image radius
                            child: context.user?.avatar != null &&
                                    context.user?.avatar?.isNotEmpty == true
                                ? Image.network(
                                    context.user?.avatar ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, url, error) =>
                                        ProfilePicture(
                                      name: context.user?.name ?? '',
                                      fontsize: Dimens.dp28,
                                      radius: Dimens.dp36,
                                      random: true,
                                      count: 1,
                                    ),
                                  )
                                : ProfilePicture(
                                    name: context.user?.name ?? '',
                                    fontsize: Dimens.dp28,
                                    radius: Dimens.dp36,
                                    random: true,
                                    count: 1,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Dimens.appPadding),
                HomeSummarySection(
                  onCGMRequestConnect: _onCGMSettingDialog,
                  onPumpRequestConnect: () =>
                      _onSearchPumpDialog(context, false),
                  onCheckAutoMode: _fetchAutoMode,
                  onRefresh: () async {
                    Future.delayed(const Duration(seconds: 2), () async {
                      await _fetchBloodGlucose();
                      await _fetchInsulinDelivery();
                    });
                  },
                  onSetDose: () {
                    if (mCMgr != null) _showSendBolusDialog();
                  },
                ),
                BlocBuilder<GetAnnounceMealBloc, GetAnnounceMealState>(
                  builder: (context, state) {
                    if (state is GetAnnounceMealSuccess) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimens.dp8,
                        ),
                        child: Row(
                          children: [
                            BlocBuilder<GetAutoModeBloc, GetAutoModeState>(
                              builder: (context, autoMode) {
                                return ElevatedButton(
                                  onPressed:
                                      //kai_20231102 state.success > 1 ? null : _showMyDialog,
                                      state.success > 0 ||
                                              (autoMode
                                                      is GetAutoModeSuccess) &&
                                                  autoMode.success == 0
                                          ? null
                                          : _showMyDialog,
                                  child: Text(_l10n.announceMeal),
                                );
                              },
                            ),
                            if (state.success > 0) ...[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimens.dp12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.l10n.youAnnounceGoingToEat,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: Dimens.dp10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.disabled_by_default_outlined,
                                ),
                                onPressed: _showCancelDialog,
                              ),
                            ] else ...[
                              Expanded(
                                child: Center(
                                  child: Text(
                                    _l10n.noAnnounceMeal,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Dimens.dp8,
                  ),
                  child: HeadingText2(
                    text: _l10n.healthMonitor,
                  ),
                ),
                GlucoseInsulinReportSection(
                  onCalibrate: () {
                    _showBloodGlucoseCalibrateDialog(context);
                  },
                  cMgr: mCMgr,
                  onRefresh: () {
                    context.read<GlucoseReportBloc>().add(
                          GlucoseReportFetched(
                            startDate: _date.start,
                            endDate: _date.end,
                            filter: false,
                          ),
                        );
                    context.read<InsulinReportBloc>().add(
                          InsulinReportFetched(
                            startDate: _date.start,
                            endDate: _date.end,
                            filter: false,
                          ),
                        );
                  },
                ),
                // GlucoseInsulinReportSection(
                //   cMgr: mCMgr,
                //   onRefresh: () {
                //     context.read<GlucoseReportBloc>().add(
                //           GlucoseReportFetched(
                //             startDate: _date.start,
                //             endDate: _date.end,
                //             filter: false,
                //           ),
                //         );
                //   },
                // ),
                // const SizedBox(
                //   height: Dimens.dp8,
                // ),
                // InsulinReportSection(
                //   cMgr: mCMgr,
                //   onRefresh: () {
                //     context.read<InsulinReportBloc>().add(
                //           InsulinReportFetched(
                //             startDate: _date.start,
                //             endDate: _date.end,
                //             filter: false,
                //           ),
                //         );
                //   },
                // ),
                const SizedBox(height: Dimens.appPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSendBolusDialog() async {
    log('kai:_onCGMSettingDialog is called: call showDialog');
    await showDialog<String>(
      barrierDismissible: false,
      context: (mounted == true)
          ? context
          : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
              ? mCMgr.appContext!
              : context,
      builder: (_) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: ConnectionDialogPage(
          onPressed: () {
            //kai_20230830 let's allow to access Pump setup first time only on home page
            if (mCMgr != null && mCMgr.mPump != null) {
              if (CspPreference.getBooleanDefaultFalse(
                    CspPreference.pumpSetupfirstTimeDone,
                  ) !=
                  true) {
                _onSearchPumpDialog(
                  (USE_APPCONTEXT == true &&
                          mCMgr.appContext != null &&
                          !mounted)
                      ? mCMgr.appContext!
                      : context,
                  false,
                );
              }
            }
          },

          context: (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          accessType: 'manual_bolus_injection',
          /* kai_20231019
          onCheckAlertCondition: (){
            if(USE_ALERT_PAGE_INSTANCE == true)
            {
              if (_mAPage != null) {
                _mAPage!.checkAlertNotificationCondition(
                    (USE_APPCONTEXT == true && mCMgr.appContext != null &&
                        !mounted) ? mCMgr.appContext! : context);
              }
              else {
                debugPrint(
                    '${tag}:_onCGMSettingDialog():kai:no registered SwitchSate. check alert notification');
              }
            }
          },   */
          switchStateAlert: _mSwitchState!,
          // onDeviceSelected: (value) {
          //   log('udin:call $value');
          //   _cgmInfoData = value;
          //   if (_cgmInfoData!.deviceId == 'xdripHome') {
          //     _onXdripOptionSelected(_cgmInfoData!.deviceId);
          //   }
          //   Navigator.of(context).pop();
          //   if (mCMgr.mPump!.ConnectionStatus !=
          //       BluetoothDeviceState.connected) {
          //     _onSearchPumpDialog(context, false);
          //   }
          // },
          // onPressed: () {
          //   _onConnectPressed();
          //   if (mCMgr.mPump!.ConnectionStatus !=
          //       BluetoothDeviceState.connected) {
          //     _onSearchPumpDialog(context, false);
          //   }
          //   Navigator.of(context).pop();
          // },
          // onUpdateBloodGlucose: _bloodGlucoseDataStreamCallback,
        ),
      ),
    );

    log('kai:_onCGMSettingDialog after call showDialog');
  }

  Future _showBloodGlucoseCalibrateDialog(BuildContext context) async {
    await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: ConnectionDialogPage(
          onPressed: () {
            //kai_20230830 exception is occurred when access this page thru Settings => CGM Stop
            if (mounted) {
              Navigator.pop(context);
            }
          },
          context: context,
          accessType: 'blood_glucose_calibrate',
          switchStateAlert: _mSwitchState!,
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

  Future<void> _showCancelDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.announceMeal),
          content: Text(context.l10n.cancelAnnounceMeal),
          actions: [
            TextButton(
              child: Text(context.l10n.confirm),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
                context.read<SetAnnounceMealBloc>().add(
                      const AnnounceMealRequestSubmitted(type: 0),
                    );
              },
            ),
            TextButton(
              child: Text(context.l10n.cancel),
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    if (!_isLoadingDialogOpen) {
      setState(
        () {
          _isLoadingDialogOpen = true;
        },
      );

      (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context.showLoadingDialog().whenComplete(
              () {
                if (mounted) {
                  setState(
                    () {
                      _isLoadingDialogOpen = false;
                    },
                  );
                }
              },
            );
    }
  }

  void _dismissLoadingDialog() {
    if (_isLoadingDialogOpen) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _dismissCGMDialog() {
    if (_isShowCGMDialog) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _onFailure(ErrorException failure) {
    (mounted == true)
        ? context.showErrorSnackBar(failure.message)
        : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
            ? mCMgr.appContext!
            : context.showErrorSnackBar(failure.message);
  }

  Future _onSuccess(String message) async {
    (mounted == true)
        ? context.showSuccessSnackBar(message)
        : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
            ? mCMgr.appContext!
            : context.showSuccessSnackBar(message);
    Future.delayed(
      const Duration(seconds: 1),
      () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  void _showInvitationDialogSheet(
    BuildContext context,
    List<InvitationData> itemList,
  ) {
    final _l10n = context.l10n;
    final _item = itemList[0];
    _userId = _item.id;
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ActionableContentSheet(
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  _acceptInvitation(_userId ?? 0);
                },
                child: Text(_l10n.accept),
              ),
              const SizedBox(height: Dimens.small),
              OutlinedButton(
                onPressed: () {
                  _rejectInvitation(_userId ?? 0);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blueGray,
                ),
                child: Text(_l10n.reject),
              ),
            ],
          ),
          content: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: Dimens.dp12,
                    right: Dimens.dp12,
                    top: Dimens.dp12,
                    bottom: Dimens.small,
                  ),
                  child: Column(
                    children: [
                      if (_item.source?.avatar != null &&
                          _item.source?.avatar?.isNotEmpty == true) ...[
                        Image.network(
                          _item.source?.avatar ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, url, error) => ProfilePicture(
                            name: context.user?.name ?? '',
                            fontsize: Dimens.dp28,
                            radius: Dimens.dp36,
                            random: true,
                          ),
                        )
                      ] else
                        ProfilePicture(
                          name: context.user?.name ?? '',
                          fontsize: Dimens.dp28,
                          radius: Dimens.dp36,
                          random: true,
                        ),
                      const SizedBox(height: Dimens.dp8),
                      HeadingText4(
                        text: _item.source?.name ?? '',
                      ),
                      const SizedBox(
                        height: Dimens.dp16,
                      ),
                      Text(
                        _l10n.wantsToConnect,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: Dimens.dp12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUpdateLabelDialogSheet(BuildContext context, int userId) {
    final _l10n = context.l10n;
    final _controller = TextEditingController();
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          child: ActionableContentSheet(
            actions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    _onUpdate(userId, _controller.text);
                  },
                  child: Text(_l10n.save),
                ),
                const SizedBox(height: Dimens.small),
                OutlinedButton(
                  onPressed: () {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueGray,
                  ),
                  child: Text(_l10n.discard),
                ),
              ],
            ),
            content: Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: Dimens.dp12,
                      right: Dimens.dp12,
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          MainAssets.youHaveConnectedFamily,
                        ),
                        const SizedBox(height: Dimens.dp8),
                        const SizedBox(
                          height: Dimens.dp16,
                        ),
                        CustomTextField(
                          formLabel: _l10n.familyLabel,
                          hintText: _l10n.lebelExample,
                          controller: _controller,
                          inputType: TextInputType.text,
                          onChanged: (value) {
                            _label = value;
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onCGMSettingDialog({CgmData? data}) async {
    log('kai:_onCGMSettingDialog is called: call showDialog');
    await showDialog<String>(
      barrierDismissible: false,
      context: (mounted == true)
          ? context
          : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
              ? mCMgr.appContext!
              : context,
      builder: (_) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: ConnectionDialogPage(
          onPressed: () {
            //kai_20230830 let's allow to access Pump
            //setup first time only on home page
            if (CspPreference.getBooleanDefaultFalse(
                  CspPreference.pumpSetupfirstTimeDone,
                ) !=
                true) {
              _onSearchPumpDialog(
                (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                    ? mCMgr.appContext!
                    : context,
                false,
              );
            }
          },
          cgmData: data,
          context: (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          accessType: 'home',
          /* kai_20231019
          onCheckAlertCondition: (){
            if(USE_ALERT_PAGE_INSTANCE == true)
            {
              if (_mAPage != null) {
                _mAPage!.checkAlertNotificationCondition(
                    (USE_APPCONTEXT == true && mCMgr.appContext != null &&
                        !mounted) ? mCMgr.appContext! : context);
              }
              else {
                debugPrint(
                    '${tag}:_onCGMSettingDialog():kai:no registered SwitchSate. 
                    check alert notification');
              }
            }
          },   */
          switchStateAlert: _mSwitchState!,
          // onDeviceSelected: (value) {
          //   log('udin:call $value');
          //   _cgmInfoData = value;
          //   if (_cgmInfoData!.deviceId == 'xdripHome') {
          //     _onXdripOptionSelected(_cgmInfoData!.deviceId);
          //   }
          //   Navigator.of(context).pop();
          //   if (mCMgr.mPump!.ConnectionStatus !=
          //       BluetoothDeviceState.connected) {
          //     _onSearchPumpDialog(context, false);
          //   }
          // },
          // onPressed: () {
          //   _onConnectPressed();
          //   if (mCMgr.mPump!.ConnectionStatus !=
          //       BluetoothDeviceState.connected) {
          //     _onSearchPumpDialog(context, false);
          //   }
          //   Navigator.of(context).pop();
          // },
          // onUpdateBloodGlucose: _bloodGlucoseDataStreamCallback,
        ),
      ),
    );

    log('kai:_onCGMSettingDialog after call showDialog');
  }

  Future<void> _onSearchPumpDialog(
    BuildContext context,
    bool hasConnectedBefore,
  ) async {
    await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () => Future.value(false),
        child: ScanDialogPage(
          hasConnectedBefore: hasConnectedBefore,
        ),
      ),
    );
  }

  void _showSelectionMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showWarningMessage(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showToastMessage(
    BuildContext context,
    String msg,
    String colorType,
    int showingTime,
  ) {
    var _color = Colors.blueAccent[700];
    var _showingDuration = 2;

    ///< default 2 secs
    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      _showingDuration = showingTime;
    }

    switch (colorType.toLowerCase()) {
      case 'red':
        {
          _color = Colors.redAccent[700];
          //kai_20231021 let's playback alert onetime here
          if (USE_AUDIO_PLAYBACK == true) {
            if (mAudioPlayer == null) {
              mAudioPlayer = CsaudioPlayer();
            }
            if (mAudioPlayer != null) {
              //mAudioPlayer!.playLowBatAlert();
              mAudioPlayer.playAlertOneTime('battery');
            }
          }
        }
        break;

      case 'yellow':
        _color = Colors.yellowAccent[700];
        break;

      case 'green':
        _color = Colors.greenAccent[700];
        break;

      case 'blue':
        _color = Colors.blueAccent[700];
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        /*  // kai_20230501 blocked show message in center for the consistency of toast message
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
            left: 30.0, right: 30.0, top: 30.0, bottom: 300.0),
       */
        backgroundColor: _color, // Colors.blueAccent[700],
        content: Text(msg),
        duration: Duration(seconds: _showingDuration),
      ),
    );
  }

  Timer? debounceTimer;
  var DebounceDuration = 2;
  var ShowingDuration = 2;
  String lastMessage = '';

  void showToastMessageDebounce(
    BuildContext context,
    String newMessage,
    String ColorType,
    int showingTime,
  ) {
    var _color = Colors.blueAccent[700];
    var ShowingDuration = 2;

    ///< default 2 secs
    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      ShowingDuration = showingTime;
    }

    switch (ColorType.toLowerCase()) {
      case 'red':
        {
          _color = Colors.redAccent[700];
          //kai_20231021 let's playback alert onetime here
          if (USE_AUDIO_PLAYBACK == true) {
            if (mAudioPlayer == null) {
              mAudioPlayer = CsaudioPlayer();
            }
            if (mAudioPlayer != null) {
              //mAudioPlayer!.playLowBatAlert();
              mAudioPlayer.playAlertOneTime('battery');
            }
          }
        }
        break;

      case 'yellow':
        _color = Colors.yellowAccent[700];
        break;

      case 'green':
        _color = Colors.greenAccent[700];
        break;

      case 'blue':
        _color = Colors.blueAccent[700];
        break;
    }

    if (debounceTimer != null && debounceTimer!.isActive) {
      debounceTimer!.cancel();
    }

    if (newMessage != lastMessage) {
      debounceTimer = Timer(Duration(seconds: DebounceDuration), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _color,
            content: Text(newMessage),
            duration: Duration(seconds: ShowingDuration),
          ),
        );
        lastMessage = newMessage;
      });
    }
  }

  void showTXErrorMsgDialog(String title, String message) {
    final titleDialog = title;
    final msgDialog = message;

    // create dialog and start alert playback onetime
    if (USE_AUDIO_PLAYBACK == true) {
      if (mAudioPlayer == null) {
        mAudioPlayer = CsaudioPlayer();
      }
      if (mAudioPlayer != null) {
        if (mAudioPlayer.isPlaying == true) {
          mAudioPlayer.stop();
          mAudioPlayer.isPlaying = false;
        }
        // mAudioPlayer.playLowBatAlert();
        mAudioPlayer.playAlertOneTime('battery');
      } else {
        log('kai:homePage:showTXErrorMsgDialog:mAudioPlayer is null!!, can not '
            'call mAudioPlayer.playLowBatAlert()');
      }
    }

    showDialog<BuildContext>(
      context: (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY  // key: _key,
        title:
            //Text('Alert'),
            Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Text(
            titleDialog,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        content: Text(
          msgDialog,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (USE_AUDIO_PLAYBACK == true) {
                if (mAudioPlayer != null) {
                  mAudioPlayer.stop();
                } else {
                  log('kai:homePage:showTXErrorMsgDialog:mAudioPlayer '
                      'is null:can not call mAudioPlayer.stop()');
                }
              }
              //let's try it again here
              Navigator.of(
                (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                    ? mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(mCMgr.appContext!.l10n.ok),
          ),
          TextButton(
            onPressed: () {
              if (USE_AUDIO_PLAYBACK == true) {
                if (mAudioPlayer != null) {
                  mAudioPlayer.stop();
                } else {
                  log('kai:homePage:showTXErrorMsgDialog:mAudioPlayer is '
                      'null:can not call mAudioPlayer.stop()');
                }
              }
              Navigator.of(
                (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                    ? mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(mCMgr.appContext!.l10n.dismiss),
          ),
        ],
      ),
    );
  }

  /*
   * @brief show Warning message with audio playback
   *        if title is alert then once playback during 2 ~ 3 secs
   *        if title is warning then playback repeatedly w/ dismissed option
   */
  void WarningMsgDlg(String title, String Msg, String ColorType, int showTime) {
    var Title = 'Warning';
    const Color _Color = Colors.red;

    if (showTime > 0) {
      //let's showToast Message with duration showTime
      _showToastMessage(
        (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
            ? mCMgr.appContext!
            : context,
        Msg,
        ColorType,
        showTime,
      );
      return;
    }

    if (title.isNotEmpty && title.isNotEmpty) {
      Title = title;
    }

    switch (ColorType) {
      case 'red':
        const Color _Color = Colors.red;
        break;

      case 'blue':
        const Color _Color = Colors.blue;
        break;

      case 'green':
        const Color _Color = Colors.green;
        break;

      default:
        const Color _Color = Colors.red;
        break;
    }

    // kai_20231021 let's check title type here and
    // set playback for alert once w/ 2~ 3 secs & warning repeatedly w/ dismiss option

    // create dialog and start alert playback onetime
    if (USE_AUDIO_PLAYBACK == true) {
      if (mAudioPlayer == null) {
        mAudioPlayer = CsaudioPlayer();
      }
      if (mAudioPlayer != null) {
        // mAudioPlayer.playLowBatAlert();
        // mAudioPlayer.loopAssetsAudio();
        mAudioPlayer.playAlert('battery');
        // mAudioPlayer.loopAssetsAudioOcclusion();
      } else {
        log('kai:homePage:WarningMsgDlg:mAudioPlayer is null:can not call mAudioPlayer.loopAssetsAudio()');
      }
    }

    showDialog<BuildContext>(
      context: (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY //   key: _key,
        title: Container(
          decoration: const BoxDecoration(
            color: _Color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Text(
            Title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        content: Text(
          Msg,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              //send "BZ1=0" to stop  buzzer in csp-1
              //mCMgr.mPump!.SendMessage2Pump('BZ1=0');
              mCMgr.mPump!.pumpTxCharacteristic!.write(utf8.encode('BZ2=0'));
              //stop playback alert
              if (USE_AUDIO_PLAYBACK == true) {
                if (mAudioPlayer != null) {
                  mAudioPlayer.stopAlert();
                  // mAudioPlayer.stopAssetsAudio();
                }
              }

              Navigator.of(
                (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                    ? mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(mCMgr.appContext!.l10n.dismiss),
          ),
        ],
      ),
    );
  }

  /*
   * @brief show toast message on the bottom of the screen
   */
  void showMsgProgress(
    BuildContext context,
    String message,
    String colorType,
    int showingTime,
  ) {
    var showingDuration = 3;
    var _color = Colors.blueAccent[700];

    if (showingTime > 0) {
      // let's set _ShowingDuration Time here
      showingDuration = showingTime;
    }

    switch (colorType.toLowerCase()) {
      case 'red':
        _color = Colors.redAccent[700];
        break;

      case 'yellow':
        _color = Colors.yellowAccent[700];
        break;

      case 'green':
        _color = Colors.greenAccent[700];
        break;

      case 'blue':
        _color = Colors.blueAccent[700];
        break;
    }

    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: showingDuration),
      backgroundColor: _color,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final overlayState = Overlay.of(context)!;
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height / 2 - 50,
        left: MediaQuery.of(context).size.width / 2 - 50,
        width: 100,
        height: 100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_color!),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Timer(Duration(seconds: showingDuration), () {
      overlayEntry.remove();
    });
  }

  void _showSetupWizardMsgDialog(
    String title,
    String message,
    String actionType,
  ) {
    final titleDialog = title;
    final msgDialog = message;
    final actionTypeDialog = actionType;
    var inputText = '';
    var enableTextField = true;

    ///< enable/disable TextField
    const readOnlyTextField = false;

    ///< block typing something
    var hintStringTextField = mCMgr.appContext!.l10n.enterYourInput;

    switch (actionType) {
      case 'HCL_DOSE_CANCEL_REQ':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = mCMgr.appContext!.l10n.cancelInjectionDose;
        break;

      case 'PATCH_DISCARD_REQ':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = mCMgr.appContext!.l10n.discardPatch;
        break;

      case 'SAFETY_CHECK_REQ':
      case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = mCMgr.appContext!.l10n.safetyCheck;
        break;

      case 'PATCH_INFO_REQ':
        enableTextField = false;
        hintStringTextField = '';
        //let's put dummy string to operate onPress()
        inputText = mCMgr.appContext!.l10n.patchInfoRequest;
        break;

      case 'CANNULAR_INSERT_RPT_SUCCESS':
      case 'CANNULAR_INSERT_RSP_SUCCESS':
      case 'INFUSION_INFO_RPT_SUCCESS':
      case 'INFUSION_INFO_RPT_REMAIN_AMOUNT':
      case 'INFUSION_INFO_RPT_30MIN_REPEATEDLY':
      case 'INFUSION_INFO_RPT_RECONNECTED':
      case 'SET_TIME_RSP_SUCCESS':
      case 'PATCH_INFO_RPT1_SUCCESS':
      case 'PATCH_INFO_RPT2_SUCCESS':
      case 'SAFETY_CHECK_RSP_SUCCESS':
      case 'SAFETY_CHECK_RSP_GOT_1STRSP':
      case 'HCL_BOLUS_CANCEL_RSP_SUCCESS':
        {
          ///kai_20231011 let's update setting screen
          mCMgr.changeNotifier();
          //kai_20230510 if procesing dialog is showing now, then
          // dismiss it also here
          _showToastMessage(
            (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                ? mCMgr.appContext!
                : context,
            msgDialog,
            'blue',
            0,
          );
        }
        break;
      case 'PATCH_NOTICE_RPT':
      case 'BUZZER_CHECK_RSP_SUCCESS':
      case 'PATCH_DISCARD_RSP_SUCCESS':
      case 'PATCH_RESET_RPT_SUCCESS_MODE0':
      case 'PATCH_RESET_RPT_SUCCESS_MODE1':
      case 'BUZZER_CHANGE_RSP_SUCCESS':
        {
          _showToastMessage(
            (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                ? mCMgr.appContext!
                : context,
            msgDialog,
            'blue',
            0,
          );
        }
        break;
      case 'HCL_BOLUS_RSP_SUCCESS':
        {
          //let's update dose injection result here
          // update local DB & Remote DB thru cloudLoop
          _showToastMessage(
            (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                ? mCMgr.appContext!
                : context,
            msgDialog,
            'blue',
            0,
          );
        }
        break;
      case 'SET_TIME_RSP_FAILED':
      case 'SAFETY_CHECK_RSP_LOW_INSULIN':
      case 'SAFETY_CHECK_RSP_ABNORMAL_PUMP':
      case 'SAFETY_CHECK_RSP_LOW_VOLTAGE':
      case 'SAFETY_CHECK_RSP_FAILED':
      case 'INFUSION_THRESHOLD_RSP_FAILED':
      case 'HCL_BOLUS_RSP_FAILED':
      case 'HCL_BOLUS_RSP_OVERFLOW':
      case 'HCL_BOLUS_CANCEL_RSP_FAILED':
      case 'CANNULAR_INSERT_RPT_FAILED':
      case 'CANNULAR_INSERT_RSP_FAILED':
      case 'PATCH_DISCARD_RSP_FAILED':
      case 'BUZZER_CHECK_RSP_FAILED':
      case 'BUZZER_CHANGE_RSP_FAILED':
        {
          _showToastMessage(
            (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                ? mCMgr.appContext!
                : context,
            msgDialog,
            'red',
            0,
          );
        }
        break;
      case 'SET_TIME_REQ':
      case 'INFUSION_THRESHOLD_REQ':
      case 'HCL_DOSE_REQ':
      case 'INFUSION_INFO_REQ':
      case 'PATCH_RESET_REQ':
        enableTextField = true;
        hintStringTextField = mCMgr.appContext!.l10n.enterYourInput;
        break;
      default:
        return;
    }

    log(
      'kai:check _key.currentContext == Null , lets create dialog here',
    );

    showDialog<BuildContext>(
      context: (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        // _USE_GLOBAL_KEY //  key: _key,
        title:
            //Text('Alert'),
            Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Dimens.dp10),
              topRight: Radius.circular(Dimens.dp10),
            ),
          ),
          padding: const EdgeInsets.all(Dimens.dp14),
          child: Text(
            titleDialog,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Dimens.dp16,
            ),
          ),
        ),
        titlePadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msgDialog,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: Dimens.dp16,
              ),
            ),
            TextField(
              enabled: enableTextField,

              ///< let's handle enable/disable based on ActionType
              onChanged: (value) {
                inputText = value;
              },
              decoration: InputDecoration(
                hintText: hintStringTextField,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        actions: [
          TextButton(
            onPressed: () {
              //let's check inputText is empty first
              log(
                'kai: press OK Button: _ActionType = $actionTypeDialog',
              );
              if (inputText.isNotEmpty) {
                final type = actionTypeDialog;
                log('kai: _ActionType = $type');
                switch (type) {
                  case 'SET_TIME_REQ':

                    ///< 0x11 : set total injected insulin amount : reservoir
                    {
                      // Date/Time,Injection amount, HCL Mode
                      // put reservoir injection amount here 1 ~ 300 U ( 2mL ~ 3mL )
                      final value = int.parse(inputText);
                      if (value > 300 || value < 1) {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 10 ~ 200',
                          'red',
                          0,
                        );
                      } else {
                        CspPreference.setString(
                          CspPreference.pumpReservoirInjectionKey,
                          inputText,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                        mCMgr.mPump!
                            .SendSetTimeReservoirRequest(value, 0x01, null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.sendingTimeNInjectInsulinAmount}($value)U ...',
                          'blue',
                          0,
                        );
                      }
                    }
                    break;

                  case 'INFUSION_THRESHOLD_REQ':

                    ///< 0x17 : 인슐린 주입 임계치 설정 요청
                    {
                      // TYPE: 최대 주입 량 설정 (0x01)
                      // 최대 볼러스 주입 량 (U, 2 byte: 정수+ 소수점 X 100) : 입력 범위 0.5 ~ 25 U
                      // 사용자가 설정 메뉴 중 볼러스 주입 정보의 최대 볼러스 량 정보를 재 설정하면 본 메시지가 송신된다.
                      //int value = int.parse(inputText)*100; ///< scaling by 100
                      if (!inputText.contains('.')) {
                        // in case that no floating point on the typed String sequence
                        inputText = '$inputText.0';
                      }
                      final value = (double.parse(inputText) * 100).toInt();
                      if (value > 2500 || value < 50)

                      ///< scaled range from 25 ~ 0.5
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                          'red',
                          0,
                        );
                      } else {
                        CspPreference.setString(
                          CspPreference.pumpMaxInfusionThresholdKey,
                          inputText,
                        );
                        mCMgr.mPump!
                            .sendSetMaxBolusThreshold(inputText, 0x01, null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.sendingMaxBolusInjectionAmount}($inputText)U ...',
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      }
                    }
                    break;

                  case 'HCL_DOSE_REQ':

                    ///< 0x67 : Bolus/ Dose injection
                    {
                      // Mode (1 byte): HCL 통합 주입(0x00), 교정 볼러스 (Correction Bolus) 0x01, 식사 볼러스 (Meal bolus) 0x02
                      // HCLBy APP” 모드에서 기저와 볼러스 주입이 통합된 자동 모드에서 주입할 인슐린 총량을 주입하기위해 사용
                      // HCL By App” 모드에서 교정 볼러스 주입 제어 알고리즘에 의한 교정 볼러스 계산기 주입 값을 가감한
                      // 최종 교정 볼러스 주입량이 있으면 본 메시지를 패치로 전송한다.
                      //int value = int.parse(inputText)*100; ///< scaling by 100
                      if (!inputText.contains('.')) {
                        // in case that no floating point on the typed String sequence
                        inputText = '$inputText.0';
                      }
                      final value = (double.parse(inputText) * 100).toInt();
                      if (value > 2500 || value < 1)

                      ///< scaled range from 25 ~ 0.01
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.01 ~ 25',
                          'red',
                          0,
                        );
                      } else {
                        //kai_20230427 let's check isDoseInjectingNow is true
                        if (mCMgr.mPump!.isDoseInjectingNow == true) {
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                          ).pop();

                          ///< due to toast popup is showing behind the active dialog
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            mCMgr.appContext!.l10n.doseProcessingMsg,
                            'red',
                            0,
                          );
                          // ko : 펌프가 이전 도즈 주입을 처리중입니다.처리가 완료 될때 까지 잠시만 기다려 주세요.
                        } else {
                          CspPreference.setString(
                            CspPreference.pumpHclDoseInjectionKey,
                            inputText,
                          );
                          mCMgr.mPump!.sendSetDoseValue(inputText, 0x00, null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            '${mCMgr.appContext!.l10n.sendingDoseAmount}($inputText)U ...',
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'HCL_DOSE_CANCEL_REQ':
                    {
                      log(
                        'kai: HCL_DOSE_CANCEL_REQ: enableTextField = $enableTextField',
                      );
                      if (enableTextField == false) {
                        mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          mCMgr.appContext!.l10n
                              .sendingDoseInjectionCancelRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // in case that no floating point on the typed String sequence
                          inputText = '$inputText.0';
                        }

                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!.cancelSetDoseValue(0x00, null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            mCMgr.appContext!.l10n
                                .sendingDoseInjectionCancelRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'PATCH_DISCARD_REQ':
                    {
                      if (enableTextField == false) {
                        mCMgr.mPump!.sendDiscardPatch(null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          mCMgr.appContext!.l10n.sendingDiscardPatchRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // in case that no floating point on the typed String sequence
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!.sendDiscardPatch(null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            mCMgr.appContext!.l10n.sendingDiscardPatchRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'INFUSION_INFO_REQ':
                    {
                      final value = int.parse(inputText);
                      if (value > 1 || value < 0)

                      ///< scaled range from 0 ~ 1
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                          'red',
                          0,
                        );
                      } else {
                        mCMgr.mPump!.sendInfusionInfoRequest(
                          int.parse(inputText),
                          null,
                        );
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          mCMgr.appContext!.l10n.sendingInfusionInfoRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      }
                    }
                    break;

                  case 'SAFETY_CHECK_REQ':
                  case 'INFUSION_THRESHOLD_RSP_SUCCESS_SAFETY_REQUEST':
                    {
                      if (enableTextField == false) {
                        mCMgr.mPump!.sendSafetyCheckRequest(null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          mCMgr.appContext!.l10n.sendingSafetyCheckRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        final value = int.parse(inputText);
                        if (value > 1 || value < 0)

                        ///< scaled range from 0 ~ 1
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!.sendSafetyCheckRequest(null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            mCMgr.appContext!.l10n.sendingSafetyCheckRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  case 'PATCH_RESET_REQ':
                    {
                      final value = int.parse(inputText);
                      if (value > 1 || value < 0)

                      ///< scaled range from 0 ~ 1
                      {
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0 ~ 1',
                          'red',
                          0,
                        );
                      } else {
                        mCMgr.mPump!.sendResetPatch(int.parse(inputText), null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          mCMgr.appContext!.l10n.sendingResetRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      }
                    }
                    break;

                  case 'PATCH_INFO_REQ':
                    {
                      if (enableTextField == false) {
                        mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                        _showToastMessage(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                          mCMgr.appContext!.l10n.sendingPatchInfoRequest,
                          'blue',
                          0,
                        );
                        Navigator.of(
                          (USE_APPCONTEXT == true &&
                                  mCMgr.appContext != null &&
                                  !mounted)
                              ? mCMgr.appContext!
                              : context,
                        ).pop();
                      } else {
                        //int value = int.parse(inputText)*100; ///< scaling by 100
                        if (!inputText.contains('.')) {
                          // 입력된 문자열에 소수점이 없는 경우
                          inputText = '$inputText.0';
                        }
                        final value = (double.parse(inputText) * 100).toInt();
                        if (value > 2500 || value < 50)

                        ///< scaled range from 25 ~ 0.5
                        {
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            '${mCMgr.appContext!.l10n.pleaseTypeAvailableValue} : 0.5 ~ 25',
                            'red',
                            0,
                          );
                        } else {
                          mCMgr.mPump!.sendPumpPatchInfoRequest(null);
                          _showToastMessage(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                            mCMgr.appContext!.l10n.sendingPatchInfoRequest,
                            'blue',
                            0,
                          );
                          Navigator.of(
                            (USE_APPCONTEXT == true &&
                                    mCMgr.appContext != null &&
                                    !mounted)
                                ? mCMgr.appContext!
                                : context,
                          ).pop();
                        }
                      }
                    }
                    break;

                  default:
                    {
                      Navigator.of(
                        (USE_APPCONTEXT == true &&
                                mCMgr.appContext != null &&
                                !mounted)
                            ? mCMgr.appContext!
                            : context,
                      ).pop();
                    }
                    break;
                }
              }
            },
            child: Text(mCMgr.appContext!.l10n.ok),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                    ? mCMgr.appContext!
                    : context,
              ).pop();
            },
            child: Text(mCMgr.appContext!.l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    var inputText = '';
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n.enterAvalue),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(hintText: context.l10n.enterAvalue),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n.cancel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(context.l10n.save),
              onPressed: () {
                //let's check inputText is empty first
                if (inputText.isNotEmpty) {
                  CspPreference.setString('cgmSourceTypeKey', inputText);
                  _showSelectionMessage(context, inputText);
                  mCMgr.changeCGM();

                  ///< update Cgm instance
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  /*
   * @fn updateInsulinDelivery(String bolus)
   * @brief update bolus data and emit it to server
   *        this API is used in Home screen
   * @param[in] Glucose : String double bolus data
   */
  Future<void> _inputInsulinDelivery(String bolus) async {
    debugPrint('${tag}kai:_inputInsulinDelivery:setDose = $setDose');
    if (!setDose) {
      setDose = true;
      debugPrint('kai:_inputInsulinDelivery:set true for setDose = $setDose');
      if (FORCE_BGLUCOSE_UPDATE_FLAG) {
        final pumpInsulinDelivery = GetIt.I<InputInsulinBloc>()
          ..add(
            InputInsulinValueChanged(
              value: double.parse(bolus),
            ),
          );
        if (debugMessageFlag) {
          log('updateInsulinDelivery: before status = '
              '${pumpInsulinDelivery.state.status.isValidated}');
        }
        // pumpInsulinDelivery.add(InputInsulinSubmitted());  ///< updated by User
        pumpInsulinDelivery.add(
          const InputInsulinSubmitted(
            source: ReportSource.sensor,
          ),
        );

        ///< updated by sensor
      }
    }
  }

  /*
   * @fn updateBloodGlucosePageBySensor(String Glucose)
   * @brief update glucose data and emit it to server
   *        this API is used in DialogView
   * @param[in] Glucose : String double glucose data
   */
  void _inputBloodGlucosePageBySensor(String glucose, int timeDate) {
    if (FORCE_BGLUCOSE_UPDATE_FLAG) {
      final sensorInputGlucose = GetIt.I<InputBloodGlucoseBloc>()
        ..add(
          InputBloodGlucoseValueChanged(
            value: double.parse(
              glucose,
            ),
          ),
        );
      if (debugMessageFlag) {
        log(
          'updateBloodGlucosePageBySensor: before status = '
          '${sensorInputGlucose.state.status.isValidated}',
        );
      }
      //  sensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
      sensorInputGlucose.add(
        InputBloodGlucoseSubmitted(
          // source: ReportSource.user,
          time: DateTime.fromMillisecondsSinceEpoch(
            timeDate,
          ),
        ),
      );

      ///< updated by sensor
    }
  }

  Future<void> _onXdripOptionSelected(String? deviceId) async {
    log('kai:index.page.dart:_onXdripOptionSelected($deviceId)');

    //kai_20231127 let's check the Xdrip is installed first here
    final isInstalled = await XDripLauncher.isXdripInstalled();
    if (!isInstalled) {
      //show install is needed to use Xdrip message here
      _showToastMessage(
        (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
            ? mCMgr.appContext!
            : context,
        '${(USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext! : context.l10n.appInstallNeeded}',
        'blue',
        0,
      );
      return;
    }

    //let's move to the select page here
    //let's set BGStream Callback here
    switch (deviceId) {
      case 'xdripHome':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdripHome', 'xdripHome'));
        await XDripLauncher.launchXDripHome();
        break;
      case 'StartSensor':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdripHome', 'xdripHome'));
        await XDripLauncher.startNewSensor();

        break;
      case 'BGHistory':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdripHome', 'xdripHome'));
        await XDripLauncher.bgHistory();

        break;
      case 'BluetoothScan':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        setState(() {});
        unawaited(_saveCgm('xdripHome', 'xdripHome'));
        await XDripLauncher.bluetoothScan();

        break;

      case 'FakeNumbers':
        await CspPreference.setString('cgmSourceTypeKey', 'Xdrip');
        await mCMgr.changeCGM();

        ///< update Cgm instance
        log('kai:FakeNumbers:call mCMgr.registerBGStreamDataListen( '
            'mCMgr.mCgm!, _BloodGlucoseDataStreamCallback)');
        mCMgr.registerBGStreamDataListen(
          mCMgr.mCgm,
          _bloodGlucoseDataStreamCallback,
        );
        if (mounted) {
          setState(() {});
        }
        unawaited(_saveCgm('xdripHome', 'xdripHome'));
        await XDripLauncher.fakeNumbers();

        break;
    }
  }

  Future<void> _saveCgm(String id, String code) async {
    if (mounted == true) {
      context.read<SaveCgmBloc>().add(CgmTransmitterIdChanged(id));
      context.read<SaveCgmBloc>().add(CgmTransmitterCodeChanged(code));
      context.read<SaveCgmBloc>().add(const CgmRequestSubmitted());
    } else {
      (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context.read<SaveCgmBloc>().add(CgmTransmitterIdChanged(id));
      (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context.read<SaveCgmBloc>().add(CgmTransmitterCodeChanged(code));
      (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
          ? mCMgr.appContext!
          : context.read<SaveCgmBloc>().add(const CgmRequestSubmitted());
    }
  }

  // void _showDialog(BuildContext context, String value) {
  //   final children = <Widget>[
  //     ListTile(
  //       title: const Text('1.Dexcom'),
  //       onTap: () async {
  //         //let's update cspPreference here
  //         await cspPreference.setString('cgmSourceTypeKey', 'Dexcom');
  //         _showSelectionMessage(context, 'Dexcom');
  //         await mCMgr.changeCGM();

  //         ///< update Cgm instance
  //         //kai_20230519 register response callback here
  //         mCMgr.registerResponseCallbackListener(
  //           mCMgr.mCgm,
  //           _handleResponseCallbackCgm,
  //         );

  //         ///< update Cgm instance
  //         Navigator.pop(context);
  //       },
  //     ),
  //     ListTile(
  //       title: const Text('2.Libro'),
  //       onTap: () async {
  //         await cspPreference.setString('cgmSourceTypeKey', 'Libro');
  //         _showSelectionMessage(context, 'Libro');
  //         await mCMgr.changeCGM();

  //         ///< update Cgm instance
  //         ///kai_20230519 register response callback here
  //         mCMgr.registerResponseCallbackListener(
  //           mCMgr.mCgm,
  //           _handleResponseCallbackCgm,
  //         );

  //         ///< update Cgm instance
  //         Navigator.pop(context);
  //       },
  //     ),
  //     ListTile(
  //       title: const Text('3.i-sens'),
  //       onTap: () async {
  //         await cspPreference.setString('cgmSourceTypeKey', 'i-sens');
  //         _showSelectionMessage(context, 'i-sens');
  //         await mCMgr.changeCGM();

  //         ///< update Cgm instance
  //         ///kai_20230519 register response callback here
  //         mCMgr.registerResponseCallbackListener(
  //           mCMgr.mCgm,
  //           _handleResponseCallbackCgm,
  //         );

  //         ///< update Cgm instance
  //         Navigator.pop(context);
  //       },
  //     ),
  //     ListTile(
  //       title: const Text('4.Xdrip'),
  //       onTap: () async {
  //         await cspPreference.setString('cgmSourceTypeKey', 'Xdrip');
  //         await mCMgr.changeCGM();

  //         ///< update Cgm instance
  //         // mCMgr.UnregisterBGStreamDataListen(mCMgr.mCgm!);
  //         mCMgr.registerBGStreamDataListen(
  //           mCMgr.mCgm,
  //           _bloodGlucoseDataStreamCallback,
  //         );
  //         //XDripLauncher.FakeNumbers();
  //         Navigator.pop(context);
  //       },
  //     ),
  //     ListTile(
  //       title: const Text('5.others'),
  //       onTap: () {
  //         _showInputDialog(context);
  //       },
  //     )
  //   ];

  //   //let's show dialog here
  //   showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Select CGM Type'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: children,
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () {
  //               Navigator.pop(context);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  /*
   * @brief if receive bloodglucose from connected CGM in Home screen, then
   *        pushing the received bloodglucose 
   * data to remote DB by using this API.
   *        this API is used in Home screen
   *
   */
  void _updateBloodGlucosePageBySensorInHome(String glucose, int timeDate) {
    if (FORCE_BGLUCOSE_UPDATE_FLAG) {
      final sensorInputGlucose = GetIt.I<InputBloodGlucoseBloc>()
        ..add(
          InputBloodGlucoseValueChanged(value: double.parse(glucose)),
        );
      if (debugMessageFlag) {
        log(
          'updateBloodGlucosePageBySensorInHome: before status '
          '= ${sensorInputGlucose.state.status.isValidated}',
        );
      }
      //sensorInputGlucose.add(InputBloodGlucoseSubmitted());  ///< updated by User
      sensorInputGlucose.add(
        InputBloodGlucoseSubmitted(
          source: ReportSource.sensor,
          time: DateTime.fromMillisecondsSinceEpoch(
            timeDate,
          ),
        ),
      );

      ///< updated by sensor
    }
  }

  /*
   * @brief Handle ResponseCallback event sent from CGM
   *        if caller register this callback which should be implemented
   *        by using ConnectivityMgr.RegisterResponseCallbackListener(IDevice, 
   * ResponseCallback) then
   *        caller can receive an event delivered from Cgm and handle it.
   *        this API is used in Home screen
   */
  void _handleResponseCallbackCgm(
    RSPType indexRsp,
    String message,
    String actionType,
  ) {
    log('${tag}kai:_handleResponseCallbackCgm() is called, mounted = $mounted, setDose($setDose)');
    log('${tag}kai:RSPType($indexRsp)'
        '\nmessage($message)\nactionType($actionType)');

    if (mCMgr.mCgm == null) {
      log('${tag}kai:_handleResponseCallbackCgm(): mCMgr.mCgm is null!!: '
          'Cannot handle the response event!! ');
      return;
    }

    switch (indexRsp) {
      case RSPType.PROCESSING_DONE:
        {
          log('${tag}kai:PROCESSING_DONE: redraw Screen widgits ');
          // To do something here after receive the processing result
          if (actionType == HCL_BOLUS_RSP_SUCCESS) {}
        }
        break;

      case RSPType.TOAST_POPUP:
        {
          log('${tag}kai:TOAST_POPUP: redraw Screen widgits ');
        }
        break;

      case RSPType.ALERT:
        {
          log('${tag}kai:ALERT: redraw Screen widgits ');
        }
        break;

      case RSPType.NOTICE:
        {
          log('${tag}kai:NOTICE: redraw Screen widgits ');
        }
        break;

      case RSPType.ERROR:
        {
          log('${tag}kai:ERROR: redraw Screen widgits ');
        }
        break;

      case RSPType.WARNING:
        {
          log('${tag}kai:WARNING: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_INPUT_DLG:
        {
          log('${tag}kai:SETUP_INPUT_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.SETUP_DLG:
        {
          log('${tag}kai:SETUP_DLG: redraw Screen widgits ');
        }
        break;

      case RSPType.UPDATE_SCREEN:
        {
          log('${tag}kai:UPDATE_SCREEN: redraw Screen widgits ');

          switch (actionType) {
            case 'NEW_BLOOD_GLUCOSE':
              {
                //kai_20230905 let's set flag which update insulin delivery DataBase
                log('${tag}kai:UPDATE_SCREEN:NEW_BLOOD_GLUCOSE: set  setDose = false ');
                setDose = false;
                Future.delayed(
                  const Duration(seconds: 1),
                  () async {
                    //To do something here .....
                    final bgValue = mCMgr.mCgm!.getBloodGlucoseValue();
                    final lastTimeReceived =
                        mCMgr.mCgm!.getLastTimeBGReceived();
                    //1. update chart graph after upload received
                    //glucose data to server
                    _updateBloodGlucosePageBySensorInHome(
                      bgValue.toString(),
                      lastTimeReceived,
                    );

                    final autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
                      const NoParams(),
                    ))
                        .foldRight(
                      0,
                      (r, previous) => r,
                    );

                    final announceMeal =
                        (await GetIt.I<GetAnnounceMealUseCase>().call(
                      const NoParams(),
                    ))
                            .foldRight(
                      0,
                      (r, previous) => r,
                    );

                    final user = (await GetIt.I<GetProfileUseCase>().call(
                      const NoParams(),
                    ))
                        .foldRight(
                      const UserProfile(
                        gender: Gender.female,
                        name: '',
                        id: '',
                        weight: 0,
                        totalDailyDose: 0,
                      ),
                      (r, previous) => r,
                    );
                    log('$tag:kai auto mode : $autoMode');

                    if (autoMode > 0) {
                      log('$tag:kai: using policynet');
                      final intValue = mCMgr.mCgm!.getBloodGlucoseValue();
                      log('$tag:kai: current glucose: $intValue');
                      final lastValue = mCMgr.mCgm!.getLastBloodGlucose() > 0
                          ? mCMgr.mCgm!.getLastBloodGlucose()
                          : intValue;
                      log('$tag:kai: last glucose: $lastValue');

                      final receivedTimeHistoryList =
                          mCMgr.mCgm!.getRecievedTimeHistoryList().getRange(
                                0,
                                5,
                              );
                      final timeHist = receivedTimeHistoryList
                          .map<String>((i) => i)
                          .toList();

                      final bloodGlucoseHistoryList =
                          mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(
                                0,
                                5,
                              );
                      final cgmHist = bloodGlucoseHistoryList
                          .map<double>((i) => i.toDouble())
                          .toList();

                      final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();

                      log('$tag:kai: announceMeal status = $announceMeal');
                      log('$tag:kai: total daily dose = ${user.totalDailyDose}');
                      log('$tag:kai: basal rate = ${user.basalRate}');
                      log('$tag:kai: cgmHist = $cgmHist');
                      log('$tag:kai: timeHist = $timeHist');
                      log('$tag:kai: insulin '
                          'carb ratio = ${user.insulinCarbRatio.toString()}');
                      //2. PolicyNet Executor send the calculated bolus(insulin) value
                      // to the connected Pump device
                      // after check connection status is connected
                      final response = await mCMgr.mPN!.execution(
                        cgmHist: cgmHist,
                        timeHist: timeHist,
                        lastInsulin: lastInsulin,
                        announceMeal: announceMeal,
                        totalDailyDose: user.totalDailyDose,
                        basalRate: user.basalRate ?? 0.0,
                        insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
                        iob: 0,
                      );
                      log(
                        '$tag:kai: mCMgr.mPN!.execution():response = $response',
                      );
                      if (response > 0) {
                        if (mCMgr.mPump!.ConnectionStatus ==
                            BluetoothDeviceState.connected) {
                          //kai_20230905 let's set flag which update insulin delivery DataBase
                          // setDose = false;
                          final insulinValue = response
                              .toString(); // U or mL, which will be calculated by PolicyNet
                          const mode =
                              0x00; //mode : total dose injection(0x00), (Correction Bolus)
                          // 0x01, (Meal bolus) 0x02
                          const BluetoothCharacteristic? characteristic =
                              null; // set null then control it based on the
                          // internal implementation
                          await mCMgr.mPump!.sendSetDoseValue(
                            insulinValue,
                            mode,
                            characteristic,
                          );
                        } else {
                          log('$tag:kai:mCMgr.mPump!.connectionStatus != '
                              'BluetoothDeviceState.connected');
                          log('$tag:kai: auto '
                              'connect status : $_pumpIsConnected');
                          if (_pumpIsConnected) {
                            await _autoConnect().whenComplete(
                              () async {
                                if (mCMgr.mPump!.ConnectionStatus ==
                                    BluetoothDeviceState.connected) {
                                  //kai_20230905 let's set flag which update insulin delivery DataBase
                                  // setDose = false;

                                  final insulinValue = response
                                      .toString(); // U or mL, which will be calculated
                                  // by PolicyNet
                                  const mode =
                                      0x00; //mode : total dose injection(0x00),
                                  //(Correction Bolus)
                                  // 0x01, (Meal bolus) 0x02
                                  const BluetoothCharacteristic?
                                      characteristic =
                                      null; // set null then control it based on the
                                  // internal implementation
                                  await mCMgr.mPump!.sendSetDoseValue(
                                    insulinValue,
                                    mode,
                                    characteristic,
                                  );
                                }
                              },
                            );
                          }
                        }
                      } else {
                        await _inputInsulinDelivery(response.toString());
                      }

                      if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
                          (CspPreference.getBooleanDefaultFalse(
                                CspPreference.broadcastingPolicyNetBolus,
                              ) ==
                              true)) {
                        // send policynet result to the destination android aps application
                        await mCMgr.mPN!.broadcasting(
                          bolus: response,
                          pkgName: CspPreference.getString(
                            CspPreference.destinationPackageName,
                            defaultValue: 'com.kai.bleperipheral',
                          ),
                        );
                      }
                    } else {
                      log('$tag:kai: using basal rate');

                      final basalRate =
                          ((user.basalRate! / 12) * 20.0).round() / 20.0;

                      log('$tag:kai: basal rate : ${user.basalRate}');
                      log('$tag:kai: basal rate : $basalRate');

                      // 2. PolicyNet Executor send the calculated bolus(insulin) value
                      // to the connected Pump device after
                      // check connection status is connected
                      if (mCMgr.mPump!.ConnectionStatus ==
                          BluetoothDeviceState.connected) {
                        //setDose = false;
                        const mode =
                            0x00; //mode : total dose injection(0x00), (Correction Bolus)
                        // 0x01, (Meal bolus) 0x02
                        const BluetoothCharacteristic? characteristic =
                            null; // set null then control it based on the
                        // internal implementation
                        await mCMgr.mPump!.sendSetDoseValue(
                          basalRate.toString(),
                          mode,
                          characteristic,
                        );
                      } else {
                        log('$tag:kai: mCMgr.mPump!.connectionStatus != '
                            'BluetoothDeviceState.connected');
                        log('$tag:kai: auto connect _pumpIsConnected = $_pumpIsConnected');
                        if (_pumpIsConnected) {
                          await _autoConnect().whenComplete(
                            () async {
                              if (mCMgr.mPump!.ConnectionStatus ==
                                  BluetoothDeviceState.connected) {
                                //setDose = false;
                                const mode =
                                    0x00; //mode : total dose injection(0x00),
                                // (Correction Bolus)
                                // 0x01, (Meal bolus) 0x02
                                const BluetoothCharacteristic? characteristic =
                                    null; // set null then control it based on the
                                // internal implementation
                                await mCMgr.mPump!.sendSetDoseValue(
                                  basalRate.toString(),
                                  mode,
                                  characteristic,
                                );
                              }
                            },
                          );
                        }
                      }

                      if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
                          (CspPreference.getBooleanDefaultFalse(
                                CspPreference.broadcastingPolicyNetBolus,
                              ) ==
                              true)) {
                        // send policynet result to the destination android aps application
                        await mCMgr.mPN!.broadcasting(
                          bolus: basalRate,
                          pkgName: CspPreference.getString(
                            CspPreference.destinationPackageName,
                            defaultValue: 'com.kai.bleperipheral',
                          ),
                        );
                      }
                    }
                  },
                );

                /*  kai_20231011


                Future.delayed(
                  const Duration(seconds: 1),
                  () async {
                    final user = (await GetIt.I<GetProfileUseCase>()
                            .call(const NoParams()))
                        .foldRight(
                      const UserProfile(
                        gender: Gender.female,
                        name: '',
                        id: '',
                        weight: 0,
                        totalDailyDose: 0,
                      ),
                      (r, previous) => r,
                    );

                    final autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
                      const NoParams(),
                    ))
                        .foldRight(
                      0,
                          (r, previous) => r,
                    );

                    final announceMeal = (await GetIt.I<GetAutoModeUseCase>()
                            .call(const NoParams()))
                        .foldRight(0, (r, previous) => r);
                    //To do something here .....
                    final intValue = mCMgr.mCgm!.getBloodGlucoseValue();
                    final lastTimeReceived =
                        mCMgr.mCgm!.getLastTimeBGReceived();
                    //1. update chart graph after upload received
                    //glucose data to server
                    _updateBloodGlucosePageBySensorInHome(
                      intValue.toString(),
                      lastTimeReceived,
                    );
                    //kai_20230615 let's notify to consummer or
                    //selector in other pages.
                    // mCMgr.mCgm!.notifyListeners();
                    // mCMgr.notifyListeners();

                    //2. notify to PolicyNet Executor
                    log('udin:call using policynet');
                    log('udin:call current glucose: $intValue');
                    final lastValue = mCMgr.mCgm!.getLastBloodGlucose() > 0
                        ? mCMgr.mCgm!.getLastBloodGlucose()
                        : intValue;
                    log('udin:call last glucose: $lastValue');

                    final receivedTimeHistoryList =
                        mCMgr.mCgm!.getRecievedTimeHistoryList();
                    final timeHist =
                        receivedTimeHistoryList.map<String>((i) => i).toList();

                    final bloodGlucoseHistoryList =
                        mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(0, 5);
                    final cgmHist = bloodGlucoseHistoryList
                        .map<double>((i) => i.toDouble())
                        .toList();

                    final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();

                    log('kai:call announceMeal status = $announceMeal');
                    log('kai:call total daily dose = ${user.totalDailyDose}');
                    log('kai:call basal rate = ${user.basalRate}');
                    log('kai:call cgmHist = $cgmHist');
                    log('kai:call timeHist = $timeHist');
                    log('kai:call last insulin = ${lastInsulin.toString()}');
                    log('kai:call insulin '
                        'carb ratio = ${user.insulinCarbRatio.toString()}');
                    final response = await mCMgr.mPN!.execution(
                      cgmHist: cgmHist,
                      timeHist: timeHist,
                      lastInsulin: lastInsulin,
                      announceMeal: announceMeal,
                      totalDailyDose: user.totalDailyDose,
                      basalRate: user.basalRate ?? 0.0,
                      insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
                    );

                    //kai_20230829 example
                    // send policynet result to the destination android aps application
                    // await mCMgr.mPN!.broadcasting(bolus: response);

                    //3. PolicyNet Executor send the calculated bolus(insulin)
                    //value to the connected Pump device after check connection
                    //status is connected
                    if (mCMgr.mPump!.ConnectionStatus ==
                        BluetoothDeviceState.connected) {
                      //kai_20230905 let's set flag which update insulin delivery DataBase
                      setDose = false;
                      debugPrint('kai:_handleResponseCallbackCgm:NEW_BLOOD_GLUCOSE:set false for setDose = ${setDose}');
                      final insulinValue = response
                          .toString(); // U or mL, which will be calculated
                      // by PolicyNet
                      log('${tag}kai:NEW_BLOOD_GLUCOSE:mPN.execution '
                          'result($insulinValue), call '
                          'sendSetDoseValue($insulinValue)');
                      const mode = 0x00; //mode : total dose injection(0x00),
                      //(Correction Bolus) 0x01, (Meal bolus) 0x02
                      const BluetoothCharacteristic? characteristic =
                          null; // set null then control it based on the
                      //internal implementation
                      await mCMgr.mPump!
                          .sendSetDoseValue(insulinValue, mode, characteristic);
                    }
                    //4. refresh all
                    if (TEST_FEATCH_DATA_UPDATE == true) {
                      Future.delayed(const Duration(seconds: 1), () async {
                        await _fetchBloodGlucose();
                        await _fetchSummaryReport();
                      });
                    }
                  },
                );
                */

                //kai_20230512 let's call connectivityMgr.notifyListener()
                //to notify  for consumer or selector page
                mCMgr.notifyListeners();
              }
              break;

            case 'CGM_SCAN_UPDATE':
              {
                log('${tag}kai:CGM_SCAN_UPDATE');
              }
              break;

            case 'DISCONNECT_FROM_USER_ACTION':
              {
                log('${tag}kai:DISCONNECT_FROM_USER_ACTION');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${CspPreference.mCGM_NAME} ${context.l10n.disconnectByUSer}',
                    );
                  });
                }
                mCMgr.notifyListeners();
              }
              break;

            case 'DISCONNECT_FROM_DEVICE_CGM':
              {
                log('${tag}kai:DISCONNECT_FROM_DEVICE_CGM');
                if (mounted) {
                  setState(
                    () {
                      _showWarningMessage(
                        context,
                        '${CspPreference.mCGM_NAME} ${context.l10n.disconnectDevice}',
                      );
                    },
                  );
                }
                mCMgr.notifyListeners();
                //kai_20230612 we need to consider auto reconnection in this
                //case in order to keep use the service.
              }
              break;

            case 'CONNECT_TO_DEVICE_CGM':
              {
                log('${tag}kai:CONNECT_TO_DEVICE_CGM');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${CspPreference.mCGM_NAME} ${context.l10n.hasBeenConnected}',
                    );
                  });
                }
                mCMgr.notifyListeners();
              }
              break;

            case 'TIMEOUT_CONNECT_TO_DEVICE_CGM':
              {
                log('${tag}kai:TIMEOUT_CONNECT_TO_DEVICE_CGM');
                if (mounted) {
                  setState(() {
                    _showMessage(
                      context,
                      '${context.l10n.timeoutForConnecting} ${CspPreference.mCGM_NAME}!!',
                    );
                  });
                }
                mCMgr.notifyListeners();
              }
              break;
          }
        }
        break;
      case RSPType.MAX_RSPTYPE:
        // TODO: Handle this case.
        break;
    }
  }

  /*
   * @fn _BloodGlucoseDataStreamCallback(dynamic event)
   * @param[in] event : received event data structure based on json
   * @brief receive the glucose data from android MainActivity thru xdrip
   *        caller should implement this callback in order to forward the
   *  received data to the PolicyNet Executor
   *        This API is used in DialogView
   */
  void _bloodGlucoseDataStreamCallback(dynamic event) {
    //check event here
    setDose = false;
    if (debugMessageFlag) {
      // {"glucose":"150.0","timestamp":"1669944611002","raw":"0.0","direction":"Flat","source":"G6 Native / G5 Native"}
      log('$tag: _BloodGlucoseDataStreamCallback: is called: set false for setDose = $setDose');
    }
    //parse json format sent from MaiActivity here
    final jsonData = json.decode(event.toString()) as Map<String, dynamic>;

    if (debugMessageFlag) {
      log('$tag: gluecose = ${jsonData['glucose']}');
      log('$tag: timestamp = ${jsonData['timestamp']}');
      log('$tag: raw = ${jsonData['raw']}');
      log('$tag: direction = ${jsonData['direction']}');
      log('$tag: source = ${jsonData['source']}');
      log('$tag: sensorSerial = ${jsonData['sensorSerial']}');
      log('$tag: calibrationInfo = ${jsonData['calibrationInfo']}');
    }

    /* save received bloodglucose time  and value here */
    final timeDate = int.parse(jsonData['timestamp'].toString());
    final glucose = jsonData['glucose'].toString();

    //update UI Screen here
    log('kai: mounted = $mounted, call setState() for update UI');
    if (mounted) {
      setState(() {
        mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
        //kai_20230509 if Glucose have floating point as like double " 225.0 "
        //then convert the value to int exclude ".0" by using floor()
        // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
        mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
        mCMgr.mCgm!.setRecievedTimeHistoryList(
          0,
          DateTime.fromMillisecondsSinceEpoch(
            timeDate,
          ).toIso8601String(),
        );
        mCMgr.mCgm!.setBloodGlucoseHistoryList(
          0,
          double.parse(glucose).floor(),
        );
        mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
        mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
        final xDripData = XdripData.fromJson(jsonData);
        mCMgr.mCgm!.setCollectBloodGlucose(xDripData);
      });
    } else {
      log('kai: !mounted = $mounted,  update UI');
      mCMgr.mCgm!.setLastTimeBGReceived(timeDate);
      //kai_20230509 if Glucose have floating point as like double " 225.0 "
      //then convert the value to int exclude ".0" by using floor()
      // mCMgr.mCgm!.setBloodGlucoseValue(int.parse(Glucose));
      mCMgr.mCgm!.setBloodGlucoseValue(double.parse(glucose).floor());
      mCMgr.mCgm!.setRecievedTimeHistoryList(
        0,
        DateTime.fromMillisecondsSinceEpoch(
          timeDate,
        ).toIso8601String(),
      );
      mCMgr.mCgm!.setBloodGlucoseHistoryList(
        0,
        double.parse(glucose).floor(),
      );
      mCMgr.mCgm!.cgmModelName = jsonData['source'].toString();
      mCMgr.mCgm!.cgmSN = jsonData['sensorSerial'].toString();
      final xDripData = XdripData.fromJson(jsonData);
      mCMgr.mCgm!.setCollectBloodGlucose(xDripData);
    }

    // UI Update here
    if (debugMessageFlag) {
      final mCgmGlucoseReceiveTime = DateFormat('yyyy/MM/dd HH:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(timeDate));
      final mCgmGlucoseValue = jsonData['glucose'].toString();

      log('$tag:>>xdrip:$mCgmGlucoseReceiveTime: glucose = $mCgmGlucoseValue '
          'raw = ${jsonData['raw']}');
    }
    // update chart graph after upload received glucose data to server
    // updateBloodGlucosePageBySensor(glucose);
    _inputBloodGlucosePageBySensor(glucose, timeDate);
    //kai_20230615 let's notify to consummer or selector in other pages.
    mCMgr.mCgm!.notifyListeners();
    mCMgr.notifyListeners();

    ///< send bloodglucose data to the DB or notify PolicyNet Executor
    Future.delayed(
      const Duration(seconds: 2),
      () async {
        //To do something here .....

        //1. notify to PolicyNet Executor

        final autoMode = (await GetIt.I<GetAutoModeUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          0,
          (r, previous) => r,
        );

        final announceMeal = (await GetIt.I<GetAnnounceMealUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          0,
          (r, previous) => r,
        );

        final user = (await GetIt.I<GetProfileUseCase>().call(
          const NoParams(),
        ))
            .foldRight(
          const UserProfile(
            gender: Gender.female,
            name: '',
            id: '',
            weight: 0,
            totalDailyDose: 0,
          ),
          (r, previous) => r,
        );
        log('$tag:call auto mode : $autoMode');

        if (autoMode > 0) {
          log('$tag:kai:call using policynet');
          final intValue = mCMgr.mCgm!.getBloodGlucoseValue();
          log('$tag:kai:call current glucose: $intValue');
          final lastValue = mCMgr.mCgm!.getLastBloodGlucose() > 0
              ? mCMgr.mCgm!.getLastBloodGlucose()
              : intValue;
          log('$tag:kai:call last glucose: $lastValue');

          final receivedTimeHistoryList =
              mCMgr.mCgm!.getRecievedTimeHistoryList().getRange(
                    0,
                    5,
                  );
          final timeHist =
              receivedTimeHistoryList.map<String>((i) => i).toList();

          final bloodGlucoseHistoryList =
              mCMgr.mCgm!.getBloodGlucoseHistoryList().getRange(
                    0,
                    5,
                  );
          final cgmHist =
              bloodGlucoseHistoryList.map<double>((i) => i.toDouble()).toList();

          final lastInsulin = mCMgr.mPump!.getBolusDeliveryValue();

          log('$tag:kai:call announceMeal status = $announceMeal');
          log('$tag:kai:call total daily dose = ${user.totalDailyDose}');
          log('$tag:kai:call basal rate = ${user.basalRate}');
          log('$tag:kai:call cgmHist = $cgmHist');
          log('$tag:kai:call timeHist = $timeHist');
          log('$tag:kai:call insulin '
              'carb ratio = ${user.insulinCarbRatio.toString()}');
          //2. PolicyNet Executor send the calculated bolus(insulin) value
          // to the connected Pump device
          // after check connection status is connected
          final response = await mCMgr.mPN!.execution(
            cgmHist: cgmHist,
            timeHist: timeHist,
            lastInsulin: lastInsulin,
            announceMeal: announceMeal,
            totalDailyDose: user.totalDailyDose,
            basalRate: user.basalRate ?? 0.0,
            insulinCarbRatio: user.insulinCarbRatio ?? 0.0,
            iob: 0,
          );
          log('$tag:kai:call mCMgr.mPN!.execution(): response = $response');
          if (response > 0) {
            if (mCMgr.mPump!.ConnectionStatus ==
                BluetoothDeviceState.connected) {
              //kai_20230905 let's set flag which update insulin delivery DataBase
              // setDose = false;
              final insulinValue = response
                  .toString(); // U or mL, which will be calculated by PolicyNet
              const mode =
                  0x00; //mode : total dose injection(0x00), (Correction Bolus)
              // 0x01, (Meal bolus) 0x02
              const BluetoothCharacteristic? characteristic =
                  null; // set null then control it based on the
              // internal implementation
              await mCMgr.mPump!
                  .sendSetDoseValue(insulinValue, mode, characteristic);
            } else {
              log('$tag:kai:mCMgr.mPump!.connectionStatus != '
                  'BluetoothDeviceState.connected');
              log('$tag:kai:call auto '
                  'connect status : $_pumpIsConnected');
              if (_pumpIsConnected) {
                await _autoConnect().whenComplete(
                  () async {
                    if (mCMgr.mPump!.ConnectionStatus ==
                        BluetoothDeviceState.connected) {
                      //kai_20230905 let's set flag which update insulin delivery DataBase
                      //setDose = false;

                      final insulinValue = response
                          .toString(); // U or mL, which will be calculated
                      // by PolicyNet
                      const mode = 0x00; //mode : total dose injection(0x00),
                      //(Correction Bolus)
                      // 0x01, (Meal bolus) 0x02
                      const BluetoothCharacteristic? characteristic =
                          null; // set null then control it based on the
                      // internal implementation
                      await mCMgr.mPump!
                          .sendSetDoseValue(insulinValue, mode, characteristic);
                    }
                  },
                );
              }
            }
          } else {
            _inputInsulinDelivery(response.toString());
          }

          if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
              (CspPreference.getBooleanDefaultFalse(
                    CspPreference.broadcastingPolicyNetBolus,
                  ) ==
                  true)) {
            // send policynet result to the destination android aps application
            await mCMgr.mPN!.broadcasting(
              bolus: response,
              pkgName: CspPreference.getString(
                CspPreference.destinationPackageName,
                defaultValue: 'com.kai.bleperipheral',
              ),
            );
          }
        } else {
          log('$tag:kai:call using basal rate');

          final basalRate = ((user.basalRate! / 12) * 20.0).round() / 20.0;

          log('$tag:kai:call basal rate : ${user.basalRate}');
          log('$tag:kai:call basal rate : $basalRate');

          // 2. PolicyNet Executor send the calculated bolus(insulin) value
          // to the connected Pump device after
          // check connection status is connected
          if (mCMgr.mPump!.ConnectionStatus == BluetoothDeviceState.connected) {
            const mode =
                0x00; //mode : total dose injection(0x00), (Correction Bolus)
            // 0x01, (Meal bolus) 0x02
            const BluetoothCharacteristic? characteristic =
                null; // set null then control it based on the
            // internal implementation
            await mCMgr.mPump!.sendSetDoseValue(
              basalRate.toString(),
              mode,
              characteristic,
            );
          } else {
            log('$tag:kai:call mCMgr.mPump!.connectionStatus != '
                'BluetoothDeviceState.connected');
            log('$tag:kai:call auto connect _pumpIsConnected = $_pumpIsConnected');
            if (_pumpIsConnected) {
              await _autoConnect().whenComplete(
                () async {
                  if (mCMgr.mPump!.ConnectionStatus ==
                      BluetoothDeviceState.connected) {
                    const mode = 0x00; //mode : total dose injection(0x00),
                    // (Correction Bolus)
                    // 0x01, (Meal bolus) 0x02
                    const BluetoothCharacteristic? characteristic =
                        null; // set null then control it based on the
                    // internal implementation
                    await mCMgr.mPump!.sendSetDoseValue(
                      basalRate.toString(),
                      mode,
                      characteristic,
                    );
                  }
                },
              );
            }
          }

          if (USE_BROADCASTING_POLICYNET_BOLUS == true &&
              (CspPreference.getBooleanDefaultFalse(
                    CspPreference.broadcastingPolicyNetBolus,
                  ) ==
                  true)) {
            // send policynet result to the destination android aps application
            await mCMgr.mPN!.broadcasting(
              bolus: basalRate,
              pkgName: CspPreference.getString(
                CspPreference.destinationPackageName,
                defaultValue: 'com.kai.bleperipheral',
              ),
            );
          }
        }
      },
    );

    if (USE_ALERT_PAGE_INSTANCE == true) {
      debugPrint('$tag:kai:call checkAlertNotification()');
      checkAlertNotification();
    }
  }

  Future<void> _autoConnect() async {
    debugPrint('kai:call auto connect pump');
    //kai_20230926 added the case of disconnecting by user
    if (CspPreference.getBooleanDefaultFalse(
          CspPreference.disconnectedByUser,
        ) ==
        true) {
      debugPrint(
        'kai:CspPreference.disconnectedByUser is true: not proceed autoconnection at this time',
      );
      return;
    }
    await mCMgr.mPump!.startScan(5).whenComplete(() async {
      final device = mCMgr.mPump!.getConnectedDevice();
      if (device != null) {
        await mCMgr.mPump!.connectToDevice(device);
        log('kai:call prev device $device');
      } else {
        log('kai:call new device ${mCMgr.mPump!.getScannedDeviceLists()}');

        //kai_20230925
        if (mCMgr.mPump!.getScannedDeviceLists() != null &&
            mCMgr.mPump!.getScannedDeviceLists()!.isNotEmpty) {
          await mCMgr.mPump!
              .connectToDevice(mCMgr.mPump!.getScannedDeviceLists()![0]);
        }
        log('kai:call new device ${mCMgr.mPump!.getScannedDeviceLists()}');
      }
      //kai_20240116 check previous register callback exit here
      // if use below callback then call cancel here because
      // already statecallback is registered during processing connectToDevice() above
      if (mCMgr.mPump!.mPumpconnectionSubscription != null) {
        mCMgr.mPump!.mPumpconnectionSubscription!.cancel();
      }

      mCMgr.mPump!.registerPumpStateCallback((state) {
        switch (state) {
          case BluetoothDeviceState.connected:
            {
              mCMgr.mPump!.ConnectionStatus = BluetoothDeviceState.connected;
              debugPrint(
                '$tag:kai:_autoConnect.registerPumpStateCallback.connected',
              );
              if (mCMgr != null && mCMgr.mPump != null && device != null) {
                if (CspPreference.mPUMP_NAME
                    .toLowerCase()
                    .contains(DANARS_PUMP_NAME.toLowerCase())) {
                  mCMgr.mPump!.ModelName = DANARS_PUMP_NAME;
                } else {
                  mCMgr.mPump!.ModelName = device.name;
                }
                mCMgr.mPump!.notifyListeners();
                mCMgr.notifyListeners();
              }
            }

            break;

          case BluetoothDeviceState.disconnected:
            {
              mCMgr.mPump!.ConnectionStatus = BluetoothDeviceState.disconnected;
              debugPrint(
                '$tag:kai:_autoConnect.registerPumpStateCallback.disconnected',
              );
              if (mCMgr != null && mCMgr.mPump != null) {
                mCMgr.mPump!.ModelName = '';
                mCMgr.mPump!.notifyListeners();
                mCMgr.notifyListeners();

                if (mCMgr.mPump! is PumpDanars) {
                  //reset the flag here first
                  if (USE_DANAI_CHECK_CONNECTION_COMMAND_SENT) {
                    (mCMgr.mPump as PumpDanars)
                        .issendPumpCheckAfterConnectFailed = 1;
                    (mCMgr.mPump as PumpDanars).onRetrying = false;
                    if (USE_CHECK_ENCRYPTION_ENABLED) {
                      (mCMgr.mPump as PumpDanars).enabledStartEncryption =
                          false;
                    }
                  }
                }
              }
            }
            break;

          case BluetoothDeviceState.disconnecting:
            {
              mCMgr.mPump!.ConnectionStatus =
                  BluetoothDeviceState.disconnecting;
            }

            break;

          case BluetoothDeviceState.connecting:
            {
              mCMgr.mPump!.ConnectionStatus = BluetoothDeviceState.connecting;
            }

            break;
        }
      });
    });
  }

  /*
   * @brief let's implement additional service here
   */
  Future<void> _onConnectPressed() async {
    //let's check valid code and transmitter ID here
    log('kai:index.page.dart:_onConnectPressed(${_cgmInfoData?.deviceId})');

    if (_cgmInfoData?.transmitterId != null &&
        _cgmInfoData?.transmitterCode != null) {
      if (_cgmInfoData?.transmitterCode != null &&
          _cgmInfoData?.transmitterId != null) {
        _showWarningMessage(
          (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          mCMgr.appContext!.l10n.putValidCodeNtransmitterID,
        );
        return;
      } else if (_cgmInfoData?.transmitterCode != null) {
        _showWarningMessage(
          (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          mCMgr.appContext!.l10n.putValidCode,
        );
        return;
      } else if (_cgmInfoData?.transmitterId != null) {
        _showWarningMessage(
          (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          mCMgr.appContext!.l10n.putTransmitterID,
        );
        return;
      } else if (_cgmInfoData!.transmitterCode.toString().length <
          maxValodCodeLength) {
        _showWarningMessage(
          (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          '${mCMgr.appContext!.l10n.invalidCode},$maxValodCodeLength ${mCMgr.appContext!.l10n.digitRequired}',
        );
        return;
      } else if (_cgmInfoData!.transmitterId.toString().length <
          maxTransmitterIDLength) {
        _showWarningMessage(
          (mounted == true)
              ? context
              : (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                  ? mCMgr.appContext!
                  : context,
          '${mCMgr.appContext!.l10n.invalidID}, $maxTransmitterIDLength ${mCMgr.appContext!.l10n.digitRequired}',
        );
        return;
      }

      //Update UI
      await CspPreference.setString(
        'dex_txid',
        _cgmInfoData!.transmitterId.toString(),
      );
      if (mounted) {
        setState(() {
          _isConnecting = true;
        });
      } else {
        _isConnecting = true;
      }

      // Simulate connection attempt
      try {
        log('kai: check _selectedDeviceId=${_cgmInfoData!.deviceId} here');

        /// 1. update selected Cgm instance here
        if (_cgmInfoData!.deviceId == 'Dexcom') {
          await CspPreference.setString('cgmSourceTypeKey', 'Dexcom');
          ResponseCallback? prevRspCallback;
          if (mCMgr.mCgm == null) {
            await mCMgr.changeCGM();
            //kai_20230519 let's backup previous setResponse callback before
            //changing cgm instance here
            prevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
          } else {
            //kai_20230519 let's backup previous setResponse callback before
            //changing cgm instance here
            prevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
            await mCMgr.changeCGM();
          }

          if (prevRspCallback != null) {
            // because clearDeviceInfo is always called in this case.
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              prevRspCallback,
            );
          } else {
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              _handleResponseCallbackCgm,
            );
          }

          log('kai: after call registerResponseCallbackListener()');
        } else if (_cgmInfoData!.deviceId == 'i-sens') {
          if (USE_ISENSE_BROADCASTING == true) {
            CspPreference.setString('cgmSourceTypeKey', 'i-sens');
            await mCMgr.changeCGM();

            ///< update Cgm instance
            mCMgr.registerBGStreamDataListen(
              mCMgr.mCgm,
              _bloodGlucoseDataStreamCallback,
            );

            //dismiss dialog here
            log('kai:CgmIsenseBC:dismiss dialog call _onConnectPressed()');
            _isConnecting = false;
            _showSelectionMessage(
              (mounted == true)
                  ? context
                  : (USE_APPCONTEXT == true &&
                          mCMgr.appContext != null &&
                          !mounted)
                      ? mCMgr.appContext!
                      : context,
              mCMgr.appContext!.l10n.isensCgmIsReadyNow,
            );

            if (mounted) {
              Navigator.of(context).pop();
            } else {
              //kai_20230721 no need  Navigator.of((USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted) ? mCMgr.appContext!: context).pop();
            }

            if (mCMgr.mPump!.ConnectionStatus !=
                BluetoothDeviceState.connected) {
              //kai_20230830 let's allow to access Pump setup first time only on home page
              if (CspPreference.getBooleanDefaultFalse(
                    CspPreference.pumpSetupfirstTimeDone,
                  ) !=
                  true) {
                await _onSearchPumpDialog(
                  (mounted == true)
                      ? context
                      : (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                  false,
                );
                // _showPumpDialog();
              }
            }

            //kai_20230724 let's skip below procedure in case of CgmIsenseBC
            return;
          }

          await CspPreference.setString('cgmSourceTypeKey', 'i-sens');
          ResponseCallback? prevRspCallback;
          if (mCMgr.mCgm == null) {
            await mCMgr.changeCGM();
            //kai_20230519 let's backup previous setResponse callback before
            //changing cgm instance here
            prevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
          } else {
            //kai_20230519 let's backup previous setResponse callback before
            //changing cgm instance here
            prevRspCallback = mCMgr.mCgm!.getResponseCallbackListener();
            await mCMgr.changeCGM();
          }

          ///< update Cgm instance
          if (prevRspCallback != null) {
            // because clearDeviceInfo is always called in this case.
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              prevRspCallback,
            );
          } else {
            mCMgr.registerResponseCallbackListener(
              mCMgr.mCgm,
              _handleResponseCallbackCgm,
            );
          }
        }

        /// 2. start scanning and stop after 5 secs,
        /// then try to connect the device
        /// that is detected by using specified device
        /// name with transmitter ID & valid code automatically.
        if (mCMgr != null && mCMgr.mCgm != null) {
          log('kai: call mCMgr.mCgm!.startScan(5)');
          await mCMgr.mCgm!.startScan(5);
        } else {
          log('kai: mCMgr.mCgm is null');
        }

        log('kai: delayed(Duration(seconds: 5)');
        //wait 5 secs until scan is complete
        await Future<void>.delayed(const Duration(seconds: 5), () async {
          log('kai: after delayed(Duration(seconds: 5)');
          //let's set callback to check result after 5 secs here
          Future<void>.delayed(const Duration(seconds: 5), () async {
            if (debugMessageFlag) {
              log('kai: after discovery and pop '
                  'dialog:(${DateFormat("yyyy-MM-dd HH:mm:ss").format(
                DateTime.now(),
              )})');
            }
            if (_isConnecting = true) {
              if (mounted) {
                setState(() {
                  _isConnecting = false;
                });
              } else {
                _isConnecting = false;
              }
              mCMgr.mCgm!.notifyListeners();
              mCMgr.notifyListeners();
              if (mounted) {
                Navigator.of(context).pop();
                if (mCMgr.mPump!.ConnectionStatus !=
                    BluetoothDeviceState.connected) {
                  //kai_20230830 let's allow to access Pump setup first time only on home page
                  if (CspPreference.getBooleanDefaultFalse(
                        CspPreference.pumpSetupfirstTimeDone,
                      ) !=
                      true) {
                    await _onSearchPumpDialog(context, false);
                  }
                }
              } else {
                if (mCMgr.mPump!.ConnectionStatus !=
                    BluetoothDeviceState.connected) {
                  //kai_20230830 let's allow to access Pump setup first time only on home page
                  if (CspPreference.getBooleanDefaultFalse(
                        CspPreference.pumpSetupfirstTimeDone,
                      ) !=
                      true) {
                    await _onSearchPumpDialog(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      false,
                    );
                  }
                }
              }
            }
          });

          //scan success case
          log('kai:check mCMgr.mCgm!.getScannedDeviceLists()!.isNotEmpty');
          // if(mCMgr.mCgm!.getScannedDeviceLists()!.isNotEmpty)
          if (mCMgr.mCgm!.cgmDevices != null &&
              mCMgr.mCgm!.cgmDevices.isNotEmpty) {
            // get last two digit thru cspPreference.getString("dex_txid")
            final transmitter = CspPreference.getString('dex_txid');
            var lastTwoDigits = '';
            if (transmitter != null && transmitter.isNotEmpty) {
              lastTwoDigits = transmitter.substring(transmitter.length - 2);
            } else {}

            final _matchName = CspPreference.mCGM_NAME + lastTwoDigits;
            log('kai:MatchName = $_matchName');

            for (final dev in mCMgr.mCgm!.cgmDevices) {
              if (dev.name.contains(_matchName)) {
                await mCMgr.mCgm!.connectToDevice(dev);

                if (mCMgr.mCgm!.cgmConnectedDevice != null) {
                  log('kai:success to connect $_matchName');
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                        context,
                        '${context.l10n.successToCgmConnect} $_matchName',
                      );
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      '${mCMgr.appContext!.l10n.successToCgmConnect} $_matchName',
                    );
                  }
                } else {
                  log('kai:fail to connect $_matchName');
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                        context,
                        '${context.l10n.canNotToCgmConnect} $_matchName ${context.l10n.atThisTime}',
                      );
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                      (USE_APPCONTEXT == true &&
                              mCMgr.appContext != null &&
                              !mounted)
                          ? mCMgr.appContext!
                          : context,
                      '${mCMgr.appContext!.l10n.canNotToCgmConnect} $_matchName ${mCMgr.appContext!.l10n.atThisTime}',
                    );
                  }
                }

                break;
              } else if (dev.name
                  .toLowerCase()
                  .contains(CspPreference.mCGM_NAME.toLowerCase())) {
                //kai_20230625 consider the case of not using last two digits
                if (debugMessageFlag) {
                  log('kai:Not use Two digits :call '
                      'mCMgr.mCgm!.connectToDevice(${dev.name})');
                }
                await mCMgr.mCgm!.connectToDevice(dev);
                if (debugMessageFlag) {
                  log('kai:Not use Two digits :after call '
                      'mCMgr.mCgm!.connectToDevice(${dev.name})');
                }
                if (mCMgr.mCgm!.cgmConnectedDevice != null) {
                  if (debugMessageFlag) {
                    log('kai:Not use Two digits '
                        ':success to connect ${dev.name}');
                  }
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                        context,
                        '${context.l10n.successToCgmConnect} ${dev.name}',
                      );
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                        (USE_APPCONTEXT == true &&
                                mCMgr.appContext != null &&
                                !mounted)
                            ? mCMgr.appContext!
                            : context,
                        '${mCMgr.appContext!.l10n.successToCgmConnect}'
                        ' ${dev.name}');
                  }
                } else {
                  if (debugMessageFlag) {
                    log('kai:Not use Two digits :fail to connect '
                        '${dev.name}');
                  }
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _showSelectionMessage(
                          context,
                          '${context.l10n.canNotToCgmConnect} '
                          '${dev.name} ${context.l10n.atThisTime}');
                    });
                  } else {
                    _isConnecting = false;
                    _showSelectionMessage(
                        (USE_APPCONTEXT == true &&
                                mCMgr.appContext != null &&
                                !mounted)
                            ? mCMgr.appContext!
                            : context,
                        '${mCMgr.appContext!.l10n.canNotToCgmConnect} '
                        '${dev.name} ${mCMgr.appContext!.l10n.atThisTime}');
                  }
                }
                break;
              }
            }

            if (_isConnecting == true) {
              log('kai:No matched device in the scan list');
              if (mounted) {
                setState(() {
                  _isConnecting = false;
                  _showSelectionMessage(
                    context,
                    '${context.l10n.noMatchedDevice} $_matchName ${context.l10n.atThisTime}',
                  );
                });
              } else {
                _isConnecting = false;
                _showSelectionMessage(
                  (USE_APPCONTEXT == true &&
                          mCMgr.appContext != null &&
                          !mounted)
                      ? mCMgr.appContext!
                      : context,
                  '${mCMgr.appContext!.l10n.noMatchedDevice} $_matchName ${mCMgr.appContext!.l10n.atThisTime}',
                );
              }
            }

            mCMgr.mCgm!.notifyListeners();
          } else {
            //show toast message "There is no scanned cgm device at
            //this time!!, try it again!!" here.
            if (mounted) {
              setState(() {
                _isConnecting = false;
                _showSelectionMessage(
                  context,
                  context.l10n.noScanListAtThisTime,
                );
              });
            } else {
              _isConnecting = false;
              _showSelectionMessage(
                (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                    ? mCMgr.appContext!
                    : context,
                mCMgr.appContext!.l10n.noScanListAtThisTime,
              );
            }
          }
        });
      } catch (e) {
        log('${tag}kai: startScan failed  $e');
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _showSelectionMessage(
              context,
              context.l10n.scanFailed,
            );
          });
        } else {
          _isConnecting = false;
          _showSelectionMessage(
            (USE_APPCONTEXT == true && mCMgr.appContext != null && !mounted)
                ? mCMgr.appContext!
                : context,
            mCMgr.appContext!.l10n.scanFailed,
          );
        }
      }

      /// 3. go to the previous CgmPage Screen
      ///  after dismiss the ConnectionDialog.
      log('kai:not Xdrip: dismiss dialog call _onConnectPressed()');
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mCMgr.mPump!.ConnectionStatus != BluetoothDeviceState.connected) {
        //kai_20230830 let's allow to access Pump setup first time only on home page
        if (CspPreference.getBooleanDefaultFalse(
              CspPreference.pumpSetupfirstTimeDone,
            ) !=
            true) {
          await _onSearchPumpDialog(
            (mounted == true)
                ? context
                : (USE_APPCONTEXT == true &&
                        mCMgr.appContext != null &&
                        !mounted)
                    ? mCMgr.appContext!
                    : context,
            false,
          );
        }
      }
    } else {
      //dismiss dialog here
      log('kai:Xdrip:dismiss dialog call _onConnectPressed()');
      //kai_20230613 if call below Navigator.of(context).pop() w/o _showPumpDialog() then context does not valid.
      // so we have to call together
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (mCMgr.mPump!.ConnectionStatus != BluetoothDeviceState.connected) {
        //kai_20230830 let's allow to access Pump setup first time only on home page
        if (CspPreference.getBooleanDefaultFalse(
              CspPreference.pumpSetupfirstTimeDone,
            ) !=
            true) {
          await _onSearchPumpDialog(
            (mounted == true)
                ? context
                : (USE_APPCONTEXT == true &&
                        mCMgr.appContext != null &&
                        !mounted)
                    ? mCMgr.appContext!
                    : context,
            false,
          );
        }
      }
    }
  }
}
